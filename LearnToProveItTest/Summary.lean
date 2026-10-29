module

public meta import LearnToProveIt.Checker

/-! A one-line form of a verdict, so tests compare the verdict's kind rather
than the wording of Lean's error messages. -/

namespace LearnToProveIt

open Lean

/-- The verdict's kind, with the axioms and citations of an acceptance. -/
public meta def summary : Verdict → String
  | .accepted axioms cited => s!"accepted; axioms: {axioms.toList}; cites: {cited.toList}"
  | .rejected reason => s!"rejected: {reason.kind}"

end LearnToProveIt
