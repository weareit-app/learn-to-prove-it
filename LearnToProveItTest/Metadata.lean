module

public meta import LearnToProveIt.Checker
public meta import LearnToProveIt.GraphComp.Metadata
public import LearnToProveIt

/-!
# Metadata tests

The exported metadata names Lean declarations and quotes Lean statements as
text. These tests check it against the Lean it describes, so a rename or an
edited statement breaks the build instead of the fixture going stale.
-/

open Lean Elab Meta LearnToProveIt GraphComp

/-- Every problem found with `family`'s metadata, empty if there are none. -/
meta def problems (family : ExerciseFamily) : MetaM (List String) := do
  let env ← getEnv
  let mut out := []
  let exists_ (n : Name) := env.contains n
  for reuse in family.mathlibReuse do
    unless exists_ reuse.declaration do out := out ++ [s!"missing reused {reuse.declaration}"]
  unless family.checker.allowedAxioms == allowedAxioms.toList do
    out := out ++ ["allowed axioms differ from the checker's"]
  unless family.checker.verdicts == "accepted" :: Rejection.samples.map (·.kind) do
    out := out ++ ["verdicts differ from the checker's"]
  unless family.environment.lean == s!"leanprover/lean4:v{Lean.versionString}" do
    out := out ++ [s!"Lean version {family.environment.lean} is not {Lean.versionString}"]
  let competencyIds := family.competencies.map (·.id)
  for ex in family.exercises do
    let some (.defnInfo obl) := env.find? ex.obligation
      | out := out ++ [s!"{ex.id}: no obligation {ex.obligation}"]; continue
    unless obl.type.isProp do out := out ++ [s!"{ex.id}: obligation is not a Prop"]
    -- The reference solution proves exactly the obligation.
    match env.find? ex.referenceSolution with
    | some info =>
      unless info.type.isConstOf ex.obligation do
        out := out ++ [s!"{ex.id}: reference solution does not prove {ex.obligation}"]
    | none => out := out ++ [s!"{ex.id}: no reference solution {ex.referenceSolution}"]
    if let some sound := ex.familySoundness then
      unless exists_ sound do out := out ++ [s!"{ex.id}: no soundness theorem {sound}"]
    for n in ex.suppliedFacts ++ ex.revealing do
      unless exists_ n do out := out ++ [s!"{ex.id}: no declaration {n}"]
    -- The statement shown is, up to reducible unfolding, the one Lean checks.
    let same ← try
        let stx ← ofExcept <| Parser.runParserCategory env `term ex.statement
        Term.TermElabM.run' <| Term.withLevelNames obl.levelParams do
          let e ← Term.elabType stx
          Term.synthesizeSyntheticMVarsNoPostponing
          withReducible <| isDefEq (← instantiateMVars e) obl.value
      catch _ => pure false
    unless same do out := out ++ [s!"{ex.id}: statement text is not the obligation"]
    for c in ex.targets ++ ex.context do
      unless competencyIds.contains c do out := out ++ [s!"{ex.id}: unknown competency {c}"]
    if ex.targets.any ex.context.contains then
      out := out ++ [s!"{ex.id}: a competency is both target and context"]
    unless ex.criteria.any (·.decidedBy == .leanChecker) do
      out := out ++ [s!"{ex.id}: no criterion for the checker"]
  return out

/-- info: [] -/
#guard_msgs in
#eval problems graphComp

/-! The exercises run in order: comprehension, reasoning, transfer. -/

/-- info: [(1, "comprehension"), (2, "reasoning"), (3, "transfer")] -/
#guard_msgs in
#eval graphComp.exercises.map fun ex => (ex.order, ex.stage.slug)

/-! Each reference solution, submitted as text, is accepted by the checker. -/

/-- info: [true, true, true] -/
#guard_msgs in
#eval show CoreM (List Bool) from graphComp.exercises.mapM fun ex => do
  return (← checkSubmission ex.obligation ex.referenceSolution.toString).isAccepted
