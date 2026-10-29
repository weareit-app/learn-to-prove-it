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

Elaborating a submission runs arbitrary Lean, including tactics. Real learner
input must go through a sandboxed runner (`lean-on-it`), never a public service.
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
  | .unknownObligation n => s!"unknown obligation {n}"
  | .unparsable _ => "unparsable"
  | .illTyped _ => "ill-typed"
  | .incomplete => "incomplete"
  | .kernelRejected _ => "kernel rejected"
  | .disallowedAxioms _ => "disallowed axioms"

/-- The checker's verdict on a submission. -/
public inductive Verdict where
  /-- A correct proof, with the axioms it depends on and the revealing
  declarations it refers to. -/
  | accepted (axioms : Array Name) (cited : Array Name)
  | rejected (reason : Rejection)
  deriving Repr, BEq

/-- The axioms an accepted proof may depend on: Lean's standard three. -/
public meta def allowedAxioms : Array Name := #[``propext, ``Classical.choice, ``Quot.sound]

/-- The name a submission is added under, in the throwaway environment. -/
public meta def submissionName : Name := `_learnToProveIt_submission

/-- Constants that `value` refers to, looking through auxiliary declarations
that elaboration added (absent from `base`), such as abstracted proofs. -/
meta partial def referencedConstants (base env : Environment) (value : Expr) :
    NameSet :=
  go value.getUsedConstantsAsSet {}
where
  go (todo : NameSet) (seen : NameSet) : NameSet := Id.run do
    let mut seen := seen
    let mut next : NameSet := {}
    for n in todo do
      if seen.contains n then continue
      seen := seen.insert n
      if base.contains n then continue
      if let some v := (env.find? n).bind (·.value?) then
        next := next.append v.getUsedConstantsAsSet
    if next.isEmpty then seen else go next seen

/-- Check `submission`, Lean source for a term, as a proof of the proposition
defined by `obligation`. Reports which of `revealing` (library results that
already state the answer) the proof refers to. Leaves the environment and
message log as it found them. -/
public meta def checkSubmission (obligation : Name) (submission : String)
    (revealing : Array Name := #[]) : CoreM Verdict := do
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
      let used := referencedConstants base (← getEnv) value
      return .accepted axioms (revealing.filter used.contains)
  finally
    Core.setMessageLog savedLog

end LearnToProveIt
