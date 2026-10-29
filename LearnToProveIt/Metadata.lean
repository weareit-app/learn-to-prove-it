module

public import Lean.Data.Json

/-!
# Exercise metadata

The machine-readable description of an exercise family that a learning
application (first, prove.how through a fixture) reads instead of Lean: what
each exercise asks, the Lean obligation that checks it, how it is evaluated, and
which competencies it can give evidence about.

This is learn-to-prove-it's own export format. Its fields follow the roles of
prove.how's logical `ExerciseFamily` and `AssessmentDesign` records (targets,
context, supplied facts, grounding, rubric), but it is not, and does not copy, a
`@learn-it/contracts` schema.

The module imports no Mathlib, so the export executable stays small. The tests
check every declaration it names against the Lean that defines it.
-/

namespace LearnToProveIt

open Lean

/-- Where an exercise sits in the progression. -/
public inductive Stage where
  | comprehension
  | reasoning
  | transfer
  deriving BEq, Repr

/-- The stage's name in the export. -/
public def Stage.slug : Stage → String
  | .comprehension => "comprehension"
  | .reasoning => "reasoning"
  | .transfer => "transfer"

public instance : ToJson Stage := ⟨fun s => toJson s.slug⟩

/-- Who decides whether a criterion is met. The checker decides only whether a
Lean proof is correct; every judgment about a learner's explanation belongs to
the learning engine. -/
public inductive Judge where
  | leanChecker
  | learningEngine
  deriving BEq, Repr

public instance : ToJson Judge where
  toJson
    | .leanChecker => "lean-checker"
    | .learningEngine => "learning-engine"

/-- One evaluation criterion. -/
public structure Criterion where
  id : String
  description : String
  decidedBy : Judge
  deriving ToJson

/-- A parameter of an exercise instance: its value, and the constraint the
family's soundness theorem needs it to meet. -/
public structure Parameter where
  name : String
  value : String
  constraint : String
  deriving ToJson

/-- A competency an exercise can give evidence about. The IDs are proposals in
the `learn-to-prove-it:` namespace, not learn-it or prove.how IDs. -/
public structure Competency where
  id : String
  statement : String
  status : String := "proposed"
  deriving ToJson

/-- Statuses, each typed by the kind of evidence behind it. There is no single
`verified` flag. -/
public structure Status where
  /-- `lean-kernel-checked`: the reference solution is a theorem the pinned
  build checks. -/
  referenceSolution : String := "lean-kernel-checked"
  /-- `lean-kernel-checked` when a soundness theorem covers the family's
  instances; `not-applicable` for an exercise with no parameters. -/
  familySoundness : String
  /-- Whether an independent reviewer has compared the Lean statement with the
  informal target. -/
  statementFidelity : String := "not-reviewed"
  deriving ToJson

/-- One exercise. -/
public structure Exercise where
  id : String
  version : String
  stage : Stage
  order : Nat
  title : String
  /-- What the learner is asked, written for this repository. -/
  prompt : String
  /-- The mathematical target, in plain words. -/
  mathematicalTarget : String
  parameters : List Parameter
  /-- The proposition a formal answer must prove; `checkSubmission` takes it. -/
  obligation : Name
  /-- The obligation's proposition as Lean source, as shown to a learner. -/
  statement : String
  referenceSolution : Name
  familySoundness : Option Name
  criteria : List Criterion
  /-- Competencies the exercise is designed to give evidence about. -/
  targets : List String
  /-- Competencies the exercise relies on without assessing them. -/
  context : List String
  /-- Earlier results the learner may use. -/
  suppliedFacts : List Name
  /-- Library results that already state the answer. Citing one is correct
  mathematics; what it says about the learner is the engine's call. -/
  revealing : List Name
  status : Status
  deriving ToJson

/-- The declarations whose use the checker should report for `ex`. -/
public def Exercise.watched (ex : Exercise) : List Name := ex.suppliedFacts ++ ex.revealing

/-- A Mathlib declaration this family reuses, and how (validation gate G3). -/
public structure Reuse where
  declaration : Name
  use : String
  deriving ToJson

/-- The pinned environment the obligations are checked in. -/
public structure Environment where
  lean : String
  mathlib : String
  mathlibCommit : String
  package : String
  deriving ToJson

/-- How a formal answer is checked. -/
public structure CheckerInfo where
  declaration : Name
  input : String
  allowedAxioms : List Name
  verdicts : List String
  sandbox : String
  deriving ToJson

/-- Where the family came from. -/
public structure Provenance where
  transformation : String
  licence : String
  design : String
  inspiration : String
  deriving ToJson

/-- An exercise family and its exercises, in order. -/
public structure ExerciseFamily where
  schema : String := "learn-to-prove-it/exercise-family-export"
  schemaVersion : String := "0.1.0"
  id : String
  version : String
  title : String
  /-- What the export does and does not assert. -/
  scope : String
  environment : Environment
  checker : CheckerInfo
  provenance : Provenance
  mathlibReuse : List Reuse
  competencies : List Competency
  exercises : List Exercise
  deriving ToJson

end LearnToProveIt
