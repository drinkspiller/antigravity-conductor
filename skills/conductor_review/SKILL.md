---
name: conductor_review
description: Review completed work against specifications, guidelines, and quality gates. Use when asked to review a track, check work quality, run acceptance criteria, or run /conductor_review.
persona: Principal Software Engineer
---

# /conductor_review — Review Completed Work

**Purpose:** Review completed work against specifications and guidelines to
ensure code quality, correctness, and adherence to project standards.

## Protocol

### 1. Initialization

1.  **Setup Check (§1.1):** Verify the following core files exist in
    `{PROJECT_ROOT}/conductor/`:
    -   `tracks.md`
    -   `product.md`
    -   `tech-stack.md`
    -   `workflow.md`
    -   `product-guidelines.md` If any of these files are missing, halt
        execution and inform the user that Conductor is not fully initialized.

### 2. Execution Phase

#### 2.1 Scope Identification

1.  Check for user-provided arguments describing what to review.
2.  **Auto-detect:** Read `{PROJECT_ROOT}/conductor/tracks.md` and look for a
    track marked as in-progress (`[~]`).
3.  If an in-progress track is found, confirm with the user using a structured
    question (`ask_question` instruction): "Review track '<track_name>'?".
    Options: "Yes", "No, specify scope".
4.  If no track is found or the user wants a different scope, present a text
    input prompt for the user to provide the review scope.
5.  Confirm the final scope with the user before proceeding.

#### 2.2 Context Retrieval

1.  Load `{PROJECT_ROOT}/conductor/product-guidelines.md` and
    `{PROJECT_ROOT}/conductor/tech-stack.md`.
2.  Load ALL files in `{PROJECT_ROOT}/conductor/code_styleguides/`. Treat these
    as "Law" — any violations are considered High severity.
3.  Check for installed skills in `.agents/skills/` or equivalent project skill
    directories and enable specialized feedback if relevant.
4.  Load the track's `plan.md` and `spec.md`. Extract commit SHAs/revisions from
    `plan.md`.
5.  Determine the revision range (start to end) for the review based on the plan
    and current workspace state.

#### 2.3 Smart Chunking & Review Process

1.  **Volume check:** Run the appropriate VCS diff stat command for the
    workspace.
2.  Determine diff size:
    -   **Small/Medium (<300 lines):** Perform a single-pass review by reading
        the full diff output.
    -   **Large (>300 lines):** Confirm with the user via `ask_question`:
        "Iterative Review Mode may take longer. Proceed?"
        -   If yes: List changed files. Review each source file individually
            using `view_file` (skip lock files and assets). Store per-file
            findings and aggregate them into the final report.
        -   If no: Attempt a high-level summary review or ask the user to narrow
            the scope.

#### 2.4 Analysis Checklist

Evaluate the changed code against the following criteria:

-   **Intent verification:** Does the implementation fulfill the requirements in
    `plan.md` and `spec.md`?
-   **ADR compliance:** For each ADR in `{PROJECT_ROOT}/conductor/adr/` that was
    created or modified during this track (or is active in the modified
    modules), verify that the implementation adheres to the recorded decision.
-   **Invariant compliance:** For each invariant in
    `{PROJECT_ROOT}/conductor/invariants.md` whose scope includes files changed
    in this track, verify that the implementation honors the behavioral
    contract.
-   **Style compliance:** Are `product-guidelines.md` and
    `code_styleguides/*.md` rules followed?
-   **Correctness & safety:** Check for bugs, race conditions, null risks, and
    perform a security scan for hardcoded secrets or PII.
-   **Testing:** Check for new tests covering the changes. Attempt to run the
    test suite automatically via the project's build tool.
-   **Skill-specific checks:** Apply specialized guidelines from relevant
    installed skills.

### 3. Review & Resolution

#### 3.1 Report & Decision

Generate a strict review report as an artifact (save to
`{PROJECT_ROOT}/conductor/tracks/<track_name>/review.md` if reviewing a track,
using `write_to_file` with `IsArtifact: true`, `ArtifactType: walkthrough`).

Use the following strict output format for the report:

```markdown
## Summary
<Overall assessment>

## Verification Checks
- Intent vs Spec: [Pass/Fail]
- ADR Compliance: [Pass/Fail]
- Invariant Compliance: [Pass/Fail]
- Style Compliance: [Pass/Fail]
- Correctness & Safety: [Pass/Fail]
- Testing: [Pass/Fail]

## Findings
*(Categorize as Critical, High, Medium, or Low severity. Include the file path, context, and a code diff suggestion for fixing. If an ADR compliance divergence was accepted as tech debt, document it here with a 'Tech Debt' tag.)*

### Critical / High
- ...

### Medium / Low
- ...
```

Once the artifact is created, use `notify_user` with `PathsToReview` pointing to
the `review.md` file.

**ADR Compliance Resolution**: If the analysis checklist identified any
divergences between the implementation and an active ADR:

-   For each divergence, call `ask_question` with a randomized prompt:
    *   "ADR-{NNNN} says '{decision}', but the implementation diverges: {desc}.
        Intentional?"
    *   "The code doesn't match the decision record. {file}:{line} does X but
        ADR-{NNNN} says Y."
    *   "Decision drift: ADR-{NNNN} expected '{expected}' but found '{actual}'
        in {file}. What's the call?"
    *   *Options*: `["Fix the code", "Update the ADR", "Acknowledge as tech
        debt"]`
-   Handle the selection:
    -   **Fix the code**: Treat this as a High severity finding in the review
        report, and include a code diff suggestion.
    -   **Update the ADR**: Trigger a draft update to the corresponding
        `{PROJECT_ROOT}/conductor/adr/NNNN-slug.md` file to reflect the new
        architectural reality. Enter the Draft Review Loop for the ADR.
    -   **Acknowledge as tech debt**: Record the divergence in the review report
        under 'Medium / Low' findings, tagged as `[Tech Debt]`.

**Invariant Compliance Resolution**: If the analysis checklist identified any
divergences between the implementation and an active invariant:

-   For each divergence, call `ask_question` with a randomized prompt:
    *   "Invariant {ID} says '{rule}', but the code diverges: {desc}.
        Intentional?"
    *   "The implementation violates {ID}: expected '{expected}' but found
        '{actual}' in {file}."
    *   *Options*: `["Fix the code", "Update the invariant", "Acknowledge as
        tech debt"]`
-   Handle the selection using the same protocol as ADR compliance resolution.

**Invariant Capture from Findings**: If the review flags a correctness or safety
issue that implies a behavioral invariant (e.g., "race condition: X must
complete before Y", "null check required before Z"), and the fix establishes an
ordering or initialization constraint, follow the Invariant Capture Protocol in
`conductor_cdd_protocols.md` §10 after the fix is applied.

Based on the findings, present an overall recommendation via a structured choice
(`ask_question`): - If Critical/High issues exist: "I recommend fixing before
moving forward." - If Medium/Low issues only: "Changes look good, some minor
suggestions." - If none: "Everything looks great!"

Present options to the user: 1. **Apply Fixes:** Automatically apply the
suggested fixes (including code fixes and ADR updates) using file editing
tools. 2. **Manual Fix:** Halt to let the user address the findings manually. 3.
**Complete Track:** Proceed without applying fixes.

Wait for the user's response and act accordingly.

#### 3.2 Commit Review Changes

If the user chose "Apply Fixes" and there are uncommitted changes after applying
them: 1. If reviewing a specific track, offer to commit the changes and update
`plan.md` by appending a "Review Fixes" phase. 2. Commit the changes using the
project's VCS. Use the commit message pattern: `fix(conductor): Apply review
suggestions for track '<name>'` 3. Record the new commit SHA/rev in `plan.md`.

#### 3.3 Track Cleanup

If reviewing a specific track and all issues are resolved (or the user chose to
Complete Track): 1. Present structured options for track cleanup via
`ask_question`: - **Archive:** Move the track files to
`{PROJECT_ROOT}/conductor/tracks/archive/`. - **Delete:** Remove the track files
(requires a double-confirmation from the user). - **Skip:** Leave the track
files in place. 2. Update `{PROJECT_ROOT}/conductor/tracks.md` to mark the track
as `[x]` (done).
