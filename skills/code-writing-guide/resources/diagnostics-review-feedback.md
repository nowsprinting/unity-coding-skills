# Diagnostics and Review Feedback

Diagnostics (IDE inspections, analyzers, linters) and code review feedback are based on general best practices.
They are not always appropriate for the specific code at hand — sometimes following them makes the code less readable or harder to maintain.

## Diagnostics

- If the recommendation fits the code, apply it.
- If it does not fit the specific context (e.g., applying it would hurt readability or conflict with the local design), it is fine to suppress it — with the `[SuppressMessage]` attribute or a `// ReSharper disable once <InspectionName>` comment, at the narrowest scope possible (a single line or member, not a whole file or assembly). **Report the suppressed diagnostic to the user with the reason** — explain what the diagnostic was and why it was not applied — and leave a "why not" code comment at the suppression site (see the "Why Not" Comments section in `coding-guideline.md`). This prevents the same diagnostic from being suppressed without record in the future and helps future readers (human or AI) understand the intent.
- If the code is under `Packages/` and the diagnostic is correct on some Unity versions and wrong on others — because the code is needed on one side of a version boundary and not the other (e.g. a `using` directive that is redundant on Unity 2023.1+ but required on older versions) — do NOT suppress it. Wrap the code in a `#if` directive instead. See the "Unity Version-Dependent Code" section in `coding-guideline.md`. (A deprecation warning for an API that still works on every supported version is not this case — suppressing it is correct. Under `Assets/`, rewrite the code for the project's single Unity version instead of suppressing.)

## Review Feedback

Review comments are also written from a general perspective. Consider each one carefully and decide whether it actually applies to your situation.

- If the suggestion fits, apply it.
- If it does not fit (because the code intentionally takes a different approach), it is fine to decline. **Report the declined item to the user with the reason** — explain what the suggestion was and why it was not applied. If the surrounding code is doing something non-obvious or unconventional, also leave a "why not" code comment (see the "Why Not" Comments section in `coding-guideline.md`). This prevents the same suggestion from being raised again in future reviews and helps future readers (human or AI) understand the intent.
