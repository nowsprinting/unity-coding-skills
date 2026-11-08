Draft a golden checklist for evaluating test-design modeling results against the specification below. A judge model will later check each item as present or absent in other modeling results of the same specification, so write items that are:

- **Traceable to the specification**: every `must` item follows from a statement in the specification, not from a choice this one modeling result happened to make. Skip findings that need judgment unless the specification clearly forces them.
- **Phrased by meaning, not notation**: "Pressing X with count 0 is not accepted: no transition and the count stays 0" rather than a Mermaid edge or a table row, so that a result modeling the same facts with another notation (product states vs. guards, one table vs. two) still passes.
- **One fact per item**, in English, with the specification's own terms (button names, screen names) kept as written.
- **Compact**: about 15 to 25 `must` items. Merge transitions or partitions that differ only by a value inside one equivalence partition ("with count 1 or more", not one item per count), and leave out facts a judge cannot check from the modeling result alone.
- **Plain text**: no backticks or Markdown emphasis inside an item; a `regex` item is the bare pattern.

Cover, under `## must`: the key inputs/states/outputs (including an input the test cannot arrange, if any); each selected test technique with its test selection criterion; every transition, partition, or rule of each model; the gaps, contradictions, undefined conditions, and unverifiable items that the specification forces.
Under `## must_not`: techniques the resource says do not fit this specification; transitions or outcomes the specification rules out; a contradiction reported when the specification has none (or the reverse); test cases or test method names being listed.
Under `## regex`: a few case-insensitive regexes for fixed vocabulary the raw output must contain, e.g., `stateDiagram-v2`, `0.?switch|0 ?スイッチ`, `equivalence partition|同値分割`.

Output only the Markdown file, in exactly this shape, with no other text:

```
# Golden: {name}

<one line stating what the fixture exercises>

## must

- ...

## must_not

- ...

## regex

- ...
```

## Specification (spec.md)

{spec}

## Modeling result to draw from

{output}
