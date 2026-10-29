module

public import LearnToProveIt.GraphComp.Metadata

/-!
# Export the exercise metadata

`lake exe export-exercise-metadata` prints the graph-composition family's
metadata as JSON. With `--check FILE` it instead exits non-zero when `FILE`
differs from what it would print, so the committed fixture cannot drift.
-/

open Lean LearnToProveIt

/-- `j` as JSON text: two-space indentation and keys in ascending order, so
the committed file reads in a stable order and diffs cleanly. -/
partial def render (j : Json) (indent : String := "") : String :=
  let inner := indent ++ "  "
  let block (open_ close : String) (items : List String) :=
    if items.isEmpty then open_ ++ close
    else open_ ++ "\n" ++ ",\n".intercalate (items.map (inner ++ ·)) ++ "\n" ++ indent ++ close
  match j with
  | .arr items => block "[" "]" (items.toList.map (render · inner))
  | .obj fields =>
    block "{" "}" (fields.toArray.toList.map fun (k, v) => s!"{(toJson k).compress}: {render v inner}")
  | j => j.compress

/-- The JSON document, ending in a newline. -/
def rendered : String := render (toJson GraphComp.graphComp) ++ "\n"

public def main : List String → IO UInt32
  | [] => do
    IO.print rendered
    return 0
  | ["--check", path] => do
    if (← IO.FS.readFile path) == rendered then return 0
    IO.eprintln s!"{path} is out of date. Regenerate it with:\n  \
      lake exe export-exercise-metadata > {path}"
    return 1
  | _ => do
    IO.eprintln "usage: export-exercise-metadata [--check FILE]"
    return 2
