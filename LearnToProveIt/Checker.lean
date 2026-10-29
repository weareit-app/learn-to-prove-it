module

public meta import Lean.Elab.Term
public meta import Lean.Elab.SyntheticMVars
public meta import Lean.Util.CollectAxioms

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

/-- The name a submission is added under, in the throwaway environment. -/
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

/-- Check `submission`, Lean source for a term, as a proof of the proposition
defined by `obligation`. Reports which of `watched` (for an exercise, its
supplied facts and revealing declarations) the proof depends on, directly or
through other declarations.

A citation is found by declaration identity only. A proof that re-proves a
watched result inline, or uses another result stating the same thing, cites
nothing, so a missing citation is not evidence that the learner derived the
proof independently. Citations are complete only in an environment holding the
bodies of every declaration the proof depends on, such as one built by a plain
(non-module) `import`; the verdict says whether they are. Leaves the environment and
message log as it found them. -/
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
  Core.resetMessageLog
  try
    withoutModifyingEnv do
      let elaborated ← try
          let value ← (Term.TermElabM.run' do
              let value ← Term.elabTermEnsuringType stx goal
              Term.synthesizeSyntheticMVarsNoPostponing
              instantiateMVars value).run'
          pure (Except.ok value)
        catch e => pure (Except.error (← e.toMessageData.toString))
      let errors ← (← Core.getMessageLog).toList.filter (·.severity == .error)
        |>.mapM (·.data.toString)
      let value ← match elaborated with
        | .error msg => return .rejected (.illTyped (errors ++ [msg]))
        | .ok value =>
          if !errors.isEmpty then return .rejected (.illTyped errors)
          pure value
      if value.hasSorry || value.hasMVar then return .rejected .incomplete
      try
        addDecl (.thmDecl { name := submissionName, levelParams := info.levelParams,
                            type := goal, value })
      catch e => return .rejected (.kernelRejected (← e.toMessageData.toString))
      let axioms ← collectAxioms submissionName
      let disallowed := axioms.filter (!allowedAxioms.contains ·)
      if !disallowed.isEmpty then return .rejected (.disallowedAxioms disallowed)
      let (used, complete) ← dependencies submissionName
      return .accepted axioms (watched.filter used.contains) complete
  finally
    Core.setMessageLog savedLog

end LearnToProveIt
