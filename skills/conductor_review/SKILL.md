---
name: conductor_review
description: Review completed work against specifications, guidelines, and quality gates. Use when asked to review a track, check work quality, run acceptance criteria, or run /conductor_review.
---

# /conductor_review — Review Completed Work

**Purpose:** Review completed work against specifications and guidelines to
ensure code quality, correctness, and adherence to project standards.

## Protocol

### 1. Initialization

1.  **Ask the user** to specify the project root path containing the
    `conductor/` directory if not already known. Use this path as
    `{PROJECT_ROOT}` for all operations in this session.
2.  **Setup Check (§1.1):** Verify the following core files exist in
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

1.  **Volume check:** Run the appropriate diff stat command for the workspace's
    VCS:
    -   `git diff --shortstat <range>`
    -   `hg diff --stat -r <start_rev>:<end_rev>`
    -   Or equivalent command for the detected VCS
2.  Determine diff size:
    -   **Small/Medium (<300 lines):** Perform a single-pass review by reading
        the full diff output (`git diff <range>`, `hg diff`, etc.).
    -   **Large (>300 lines):** Confirm with the user via `ask_question`:
        "Iterative Review Mode may take longer. Proceed?"
        -   If yes: List changed files. Review each source file individually
            using `view_file` (skip lock files and assets). Store per-file
            findings and aggregate them into the final report.
        -   If no: Attempt a high-level summary review or ask the user to narrow
            the scope.

#### 2.4 Analysis Checklist

Evaluate the changed code against the following criteria: - **Intent
verification:** Does the implementation fulfill the requirements in `plan.md`
and `spec.md`? - **Style compliance:** Are `product-guidelines.md` and
`code_styleguides/*.md` rules followed? - **Correctness & safety:** Check for
bugs, race conditions, null risks, and perform a security scan for hardcoded
secrets or PII. - **Testing:** Check for new tests covering the changes. Attempt
to run the test suite automatically via the project's build tool. -
**Skill-specific checks:** Apply specialized guidelines from relevant installed
skills.

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
- Style Compliance: [Pass/Fail]
- Correctness & Safety: [Pass/Fail]
- Testing: [Pass/Fail]

## Findings
*(Categorize as Critical, High, Medium, or Low severity. Include the file path, context, and a code diff suggestion for fixing.)*

### Critical / High
- ...

### Medium / Low
- ...
```

Once the artifact is created, use `notify_user` with `PathsToReview` pointing to
the `review.md` file.

Based on the findings, present an overall recommendation via a structured choice
(`ask_question`): - If Critical/High issues exist: "I recommend fixing before
moving forward." - If Medium/Low issues only: "Changes look good, some minor
suggestions." - If none: "Everything looks great!"

Present options to the user: 1. **Apply Fixes:** Automatically apply the
suggested fixes using file editing tools. 2. **Manual Fix:** Halt to let the
user address the findings manually. 3. **Complete Track:** Proceed without
applying fixes.

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
