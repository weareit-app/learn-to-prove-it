# Glossary

- **Exercise family**: a parametrised exercise, with the constraints its parameters must meet and a soundness theorem saying every instance that meets them is provable.
- **Instance**: one choice of a family's parameters, published with its own obligation and reference solution.
- **Proof obligation** (obligation): the named Lean proposition a formal answer to an exercise must prove.
- **Reference solution**: a Lean theorem proving an obligation. The build checks it.
- **Submission**: a learner's formal answer, as Lean source for a term.
- **Verdict**: the checker's decision on a submission: accepted, or rejected with a reason. It is about the mathematics only. _Avoid_: score, grade.
- **Revealing declaration**: a library result that already states an exercise's answer. Citing one is correct mathematics. What it says about the learner is the learning engine's call.
- **Supplied fact**: an earlier result the learner may use in an exercise.
- **Target / context competency**: a competency an exercise is designed to give evidence about, versus one it only relies on.
- **Criterion**: one thing an answer is evaluated on, decided either by the Lean checker or by the learning engine.
