module

public meta import Lean.Elab.Term
public meta import Lean.Elab.SyntheticMVars
public meta import Lean.Util.CollectAxioms
public meta import Lean.AddDecl

/-!
# Submission checker

Checks a learner's Lean proof of an exercise's proof obligation. The submission
is source text for a Lean term (a `by` block is a term). The checker parses it,
elaborates it against the obligation in the current environment, adds it to a
throwaway copy of that environment as a theorem (so the kernel checks it), and
collects the axioms it depends on.

The verdict is about the mathematics only. An accepted submission is a correct
proof; a rejected one is not a correct proof *as written in Lean*, which is not
the same as the learner's informal reasoning being wrong. What either says about
the learner is for the learning engine to decide.

Elaborating a submission runs arbitrary Lean, including tactics with effects
outside Lean's environment. `withoutModifyingEnv` restores the environment; it
is not a security boundary. Real learner input must go through a sandboxed
runner (`lean-on-it`). Until that integration lands, nothing in this repository
(no executable, server or tool) calls the checker on untrusted input.
-/

namespace LearnToProveIt

open Lean Elab

/-- Why a submission is not an accepted proof. -/
public inductive Rejection where
  /-- The obligation named is not a definition whose body the environment
  exposes (in the module system, mark it `@[expose]`). A caller error. -/
  | unknownObligation (name : Name)
  /-- The text does not parse as a Lean term. -/
  | unparsable (message : String)
  /-- The term does not elaborate to a proof of the obligation. -/
  | illTyped (messages : List String)
  /-- The term contains `sorry` or leaves a hole unfilled. -/
  | incomplete
  /-- The kernel rejected the elaborated proof. -/
  | kernelRejected (message : String)
  /-- Checking ran out of heartbeats or recursion depth. -/
  | limitExceeded (message : String)
  /-- The proof depends on axioms outside `allowedAxioms`, such as the one
  `native_decide` adds to trust the compiler. -/
  | disallowedAxioms (axioms : Array Name)
  deriving Repr, BEq

/-- A short, stable name for a rejection's kind. -/
public meta def Rejection.kind : Rejection → String
  | .unknownObligation _ => "unknown obligation"
  | .unparsable _ => "unparsable"
  | .illTyped _ => "ill-typed"
  | .incomplete => "incomplete"
  | .kernelRejected _ => "kernel rejected"
  | .limitExceeded _ => "limit exceeded"
  | .disallowedAxioms _ => "disallowed axioms"

/-- The checker's verdict on a submission. -/
public inductive Verdict where
  /-- A correct proof, with the axioms and the watched declarations it depends
  on. `citationsComplete` is false when the dependency closure reached a
  declaration whose body the environment does not hold, so a watched
  declaration behind it would be missed. -/
  | accepted (axioms : Array Name) (cited : Array Name) (citationsComplete : Bool)
  | rejected (reason : Rejection)
  deriving Repr, BEq

/-- Whether the verdict accepts the submission. -/
public meta def Verdict.isAccepted : Verdict → Bool
  | .accepted .. => true
  | .rejected _ => false

/-- The axioms an accepted proof may depend on: Lean's standard three. -/
public meta def allowedAxioms : Array Name := #[``propext, ``Classical.choice, ``Quot.sound]

/-- The name a submission is added under, in the throwaway environment, unless
the environment already uses it. -/
public meta def submissionName : Name := `_learnToProveIt_submission

/-- The constants `root` depends on: those in its type and value, and theirs,
transitively (the closure `collectAxioms` walks). Also whether that closure is
complete. It is not when it reaches a declaration whose body the environment
hides: under the module system an imported theorem, or an unexposed definition,
appears as an axiom. Such a declaration is told apart from a real axiom because
a real axiom is among its own axioms. -/
meta partial def dependencies (root : Name) : CoreM (NameSet × Bool) := do
  let env ← getEnv
  let mut todo := [root]
  let mut seen : NameSet := {}
  let mut complete := true
  while true do
    let n :: rest := todo | break
    todo := rest
    if seen.contains n then continue
    seen := seen.insert n
    let some info := env.find? n | complete := false; continue
    if info matches .axiomInfo _ then
      unless (← collectAxioms n).contains n do complete := false
    let body := (info.value? (allowOpaque := true)).elim #[] (·.getUsedConstants)
    todo := (info.type.getUsedConstants ++ body).toList ++ todo
  return (seen, complete)

/-- The declarations in `env` that are not in `base`, each after the ones it
depends on. -/
meta partial def addedSince (base env : Environment) : Array ConstantInfo :=
  let added : NameMap ConstantInfo := env.checked.get.constants.foldStage2
    (fun m n info => if base.contains n then m else m.insert n info) {}
  let rec visit (n : Name) (acc : Array ConstantInfo × NameSet) :=
    let (out, seen) := acc
    if seen.contains n then acc
    else match added.find? n with
      | none => acc
      | some info =>
        let deps := info.type.getUsedConstants ++
          (info.value? (allowOpaque := true)).elim #[] (·.getUsedConstants)
        let (out, seen) := deps.foldl (fun acc d => visit d acc) (out, seen.insert n)
        (out.push info, seen)
  (added.foldl (fun acc n _ => visit n acc) (#[], {})).1

/-- `info` as a declaration to add again, if it is of a kind a submission's
elaboration may create. -/
meta def declarationOf? : ConstantInfo → Option Declaration
  | .thmInfo v => some (.thmDecl v)
  | .defnInfo v => some (.defnDecl v)
  | .opaqueInfo v => some (.opaqueDecl v)
  | .axiomInfo v => some (.axiomDecl v)
  | _ => none

/-- A name for the submission's theorem that `env` does not already use,
publicly or privately. -/
meta def freshSubmissionName (env : Environment) : Name := Id.run do
  let mut n := submissionName
  let mut i := 1
  while env.contains n || env.contains (mkPrivateName env n) do
    n := submissionName.appendIndexAfter i
    i := i + 1
  return n

/-- Check `submission`, Lean source for a term, as a proof of the proposition
defined by `obligation`. Reports which of `watched` (for an exercise, its
supplied facts and revealing declarations) the proof depends on, directly or
through other declarations.

The kernel checks everything the verdict rests on, under the checker's options,
not the submission's or the caller's: after elaboration the environment is reset
to the caller's, and every declaration elaboration added (such as auxiliary
lemmas) is added again with kernel checking forced on, then the proof itself.
A submission that turns kernel checking off for its own auxiliary declarations
therefore gains nothing. That kernel pass is synchronous and pure, on the
caller's kernel environment, so its failure is a definite rejection.

A citation is found by declaration identity only. A proof that re-proves a
watched result inline, or uses another result stating the same thing, cites
nothing, so a missing citation is not evidence that the learner derived the
proof independently. Citations are complete only in an environment holding the
bodies of every declaration the proof depends on, such as one built by a plain
(non-module) `import`; the verdict says whether they are. Leaves the environment,
message log and trace state as it found them. Running out of heartbeats or
recursion depth is a rejection; an interrupt still propagates. -/
public meta def checkSubmission (obligation : Name) (submission : String)
    (watched : Array Name := #[]) : CoreM Verdict := do
  let base ← getEnv
  let some (.defnInfo info) := base.find? obligation
    | return .rejected (.unknownObligation obligation)
  let goal := info.value
  let stx ← match Parser.runParserCategory base `term submission with
    | .ok stx => pure stx
    | .error msg => return .rejected (.unparsable msg)
  let savedLog ← Core.getMessageLog
  let savedTraces ← getTraceState
  Core.resetMessageLog
  try
    withoutModifyingEnv <| withOptions (debug.skipKernelTC.set · false) do
      let elaborated ← tryCatchRuntimeEx
        (do
          let value ← (Term.TermElabM.run' do
              let value ← Term.elabTermEnsuringType stx goal
              Term.synthesizeSyntheticMVarsNoPostponing
              unless (← get).letRecsToLift.isEmpty do
                throwError "`let rec` and `where` are not supported in a submission"
              instantiateMVars value).run'
          pure (Except.ok value))
        fun e => do
          let msg ← e.toMessageData.toString
          pure (Except.error (if e.isRuntime then Rejection.limitExceeded msg else .illTyped [msg]))
      let errors ← (← Core.getMessageLog).toList.filter (·.severity == .error)
        |>.mapM (·.data.toString)
      let value ← match elaborated with
        | .error (.illTyped msgs) => return .rejected (.illTyped (errors ++ msgs))
        | .error reason => return .rejected reason
        | .ok value =>
          if !errors.isEmpty then return .rejected (.illTyped errors)
          pure value
      if value.hasSorry || value.hasMVar then return .rejected .incomplete
      let added := addedSince base (← getEnv)
      let name := freshSubmissionName base
      let mut decls := #[]
      for info in added do
        let some d := declarationOf? info
          | return .rejected (.kernelRejected s!"elaboration added an unsupported declaration {info.name}")
        decls := decls.push d
      decls := decls.push (.thmDecl { name, levelParams := info.levelParams, type := goal, value })
      -- The kernel check the verdict rests on: synchronous, from the caller's
      -- environment, with checking forced on whatever the options say.
      let opts := debug.skipKernelTC.set (← getOptions) false
      let mut kernel := base.toKernelEnv
      for d in decls do
        match kernel.addDecl opts d with
        | .ok k => kernel := k
        | .error e => return .rejected (.kernelRejected (← (e.toMessageData opts).toString))
      -- Already checked: add them to the elaboration environment for the axiom
      -- and citation walks.
      setEnv base
      withOptions (debug.skipKernelTC.set · true) do
        for d in decls do addDecl d
      let axioms ← collectAxioms name
      let disallowed := axioms.filter (!allowedAxioms.contains ·)
      if !disallowed.isEmpty then return .rejected (.disallowedAxioms disallowed)
      let (used, complete) ← dependencies name
      return .accepted axioms (watched.filter used.contains) complete
  finally
    Core.setMessageLog savedLog
    setTraceState savedTraces

end LearnToProveIt
