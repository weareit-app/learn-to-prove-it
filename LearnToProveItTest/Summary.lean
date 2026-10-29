module

public meta import LearnToProveIt.Checker

/-! A one-line form of a verdict, so tests compare the verdict's kind rather
than the wording of Lean's error messages. -/

namespace LearnToProveIt

open Lean

/-- The verdict's kind, with the axioms and citations of an acceptance, and
whether those citations are partial. -/
public meta def summary : Verdict → String
  | .accepted axioms cited complete =>
    s!"accepted; axioms: {axioms.toList}; cites: {cited.toList}" ++
      if complete then "" else " (citations partial)"
  | .rejected reason => s!"rejected: {reason.kind}"

end LearnToProveIt
