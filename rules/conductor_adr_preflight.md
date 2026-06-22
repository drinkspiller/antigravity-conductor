# ADR & Glossary Preflight Interceptor

> Loaded on demand by Conductor skills. Not an always-on rule.

Whenever ANY Conductor skill is executed against an existing project:

1.  **Lazy Detection:** Check whether `{PROJECT_ROOT}/conductor/adr/` exists and
    contains at least one `.md` file.
2.  **Interception:** If no ADR files are found AND the project is brownfield
    (contains source code or existing Conductor docs):
    -   Temporarily pause the invoked skill's primary protocol.
    -   Sweep existing documentation (`tech-stack.md`, `product.md`, legacy
        track `spec.md`, `README.md`) for architectural trade-offs.
    -   Filter extracted statements through the 3-part gate (hard to reverse ×
        surprising × real trade-off).
    -   If qualifying candidates are identified, interview the user via
        `ask_question`: *"I swept your existing docs and found foundational
        decisions that predate our ADR system. Formalize them before we
        proceed?"*
    -   Write accepted items to `conductor/adr/NNNN-slug.md` and initialize
        `terms.md`.
    -   Upon completion (or if the user selects 'Skip'), immediately resume and
        execute the originally invoked skill command.
