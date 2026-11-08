You judge whether a test-design modeling result states each item below. Judge presence only, not quality.

An item is **present** when the modeling result states it, in any wording or notation (a Mermaid edge, a table row, a bullet). Treat equivalent phrasings as the same: "HP <= 0" and "HP is zero or negative" are one item. An item is **absent** when the result omits it or states the opposite.

Read Mermaid diagrams edge by edge: `state "Title / count 0" as T0` declares an alias, so `R0 --> T0 : 次へ` is a transition from the result screen to the title screen. Check every notation the result uses (diagram, tables, bullets, notes) before deciding an item is absent.

For every item, return its id, `present` (true/false), and one line of evidence quoting the result (or "not found").

## Items

{items}

## Modeling result

{output}
