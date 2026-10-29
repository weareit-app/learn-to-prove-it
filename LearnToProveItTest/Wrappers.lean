module

public import LearnToProveIt.GraphComp.Reasoning

/-!
# Wrappers around answer-revealing results

Theorems that restate a revealing declaration under another name, in a module
of their own. A submission that cites one depends on the revealing result
indirectly, and the checker must still report it.
-/

namespace LearnToProveItTest

/-- `graph_comp_iff` under another name. -/
public theorem renamed {α β γ : Type*} (f : α → β) (r : β → γ → Prop) (a : α) (c : γ) :
    Relation.Comp (fun x y => f x = y) r a c ↔ r (f a) c :=
  LearnToProveIt.graph_comp_iff f r a c

/-- Two wrappers deep. -/
public theorem renamedTwice {α β γ : Type*} (f : α → β) (r : β → γ → Prop) (a : α) (c : γ) :
    Relation.Comp (fun x y => f x = y) r a c ↔ r (f a) c :=
  renamed f r a c

end LearnToProveItTest
