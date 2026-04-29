---
name: conductor_review
description: Review completed work against specifications, guidelines, and quality gates. Use when asked to review a track, check work quality, run acceptance criteria, or run /conductor_review.
---

# /conductor_review — Review Completed Work

**Purpose:** Review completed work against specifications and guidelines to
ensure code quality, correctness, and adherence to project standards.

## `ask_question` Best Practices

The `ask_question` modal renders text with **limited formatting** — markdown
syntax like `**bold**`, backticks, and numbered lists display as raw characters.
Follow these rules to keep questions readable:

1.  **Short questions only.** The `question` field must be a single concise
    sentence (aim for ≤ 15 words). Never put analysis, findings, code
    references, status reports, or multi-line content in the question.
2.  **Report first, ask second.** Present any analysis, findings, or context as
    **regular text in your response** (where markdown renders properly), then
    call `ask_question` with only the decision question and options.
3.  **Options are the user's voice.** Each option string should read as
    something the user would say — not a description of what you will do.
4.  **Go beyond binary.** Prefer 3-4 meaningful options over Yes/No whenever the
    decision has nuance.

### Examples

**BAD — review findings crammed into the question:**

```
question: "Review found: 2 Critical issues (missing null check in UserModel.ts
line 47, SQL injection risk in query builder), 3 Medium issues. I recommend
fixing Critical issues before moving forward. What would you like to do?"
options: ["Apply Fixes", "Skip"]
```

**GOOD — findings in the review artifact, question is just the decision:**

First, write findings to the review artifact and present it. Then call
`ask_question`:

```
question: "2 critical and 3 medium issues found. How should we proceed?"
options: [
  "Auto-fix all issues",
  "Auto-fix critical only, I'll handle the rest",
  "I'll fix everything manually",
  "Proceed without fixing"
]
```

**More good examples:**

```
question: "The diff is 450+ lines. Use iterative review mode?"
options: [
  "Yes, review file by file",
  "No, do a high-level summary instead",
  "Let me narrow the scope first"
]
```

```
question: "Review is complete. What should we do with the track?"
options: [
  "Archive the track",
  "Delete the track (irreversible)",
  "Leave it in place for now"
]
```

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
