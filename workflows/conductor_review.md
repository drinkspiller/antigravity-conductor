---
description: Review completed work against specifications, guidelines, and quality gates
---

1. Read the Conductor skill instructions at the skill file for Conductor.
2. **Locate the project root:**
   - First, check the current working directory and its parents for a `conductor/` directory.
   - If not found, check the root of the current Git repository (`git rev-parse --show-toplevel`) for a `conductor/` directory.
   - If found, use that path as `{PROJECT_ROOT}` and inform the user: "Found Conductor context at `{PROJECT_ROOT}/conductor/`."
   - If NOT found, ask the user: **"I couldn't find a `conductor/` directory in this workspace. Please specify the project root path where it exists (or should be created)."** Wait for the user's response and use the provided path as `{PROJECT_ROOT}`.

3. **Load Context:** Read from `{PROJECT_ROOT}/conductor/`:
   - `conductor/tracks.md` — Identify the active track (marked `[~]` or most recently `[x]`).
   - The active track's `spec.md` and `plan.md`.
   - `conductor/product-guidelines.md`
   - `conductor/workflow.md`
   - Any relevant files in `conductor/code_styleguides/`

4. **Determine Review Scope:**
   Ask the user: **"What would you like me to review? (A) The entire track, (B) Just the current/latest phase, or (C) A specific set of files?"**

   Wait for the user's response.

4. **Gather Changed Files:**
   Using the workspace's VCS (detect whether it is git, hg/Fig, or g4/Piper):
   - For the selected scope, run the appropriate diff command against the track start point:
     - git: `git diff --name-only <start_sha> HEAD`
     - hg: `hg diff --stat -r <start_rev>`
     - g4: `g4 diff --name-only`
   - Read each changed file.

5. **Evaluate Against Criteria:**

   For each acceptance criterion in `spec.md`:
   - Check whether the changed files satisfy it.
   - Mark as ✅ Met, ⚠️ Partially met, or ❌ Not met.

   Check quality gates from `conductor/workflow.md`:
   - Test coverage threshold met?
   - All tests passing?
   - Commit messages follow convention?

   Check style guide compliance from `conductor/code_styleguides/`:
   - Naming conventions followed?
   - File organization correct?
   - Import ordering consistent?

6. **Generate Review Report:**

   Present a structured report:

   ```
   ## Review Report: <Track Title>

   ### Acceptance Criteria
   | # | Criterion | Status | Notes |
   |---|-----------|--------|-------|
   | 1 | <criterion> | ✅ Met | <details> |
   | 2 | <criterion> | ⚠️ Partial | <what's missing> |
   | 3 | <criterion> | ❌ Not met | <what needs to be done> |

   ### Quality Gates
   - Test coverage: ✅ 87% (target: 80%)
   - All tests passing: ✅
   - Commit conventions: ⚠️ 2 commits missing type prefix

   ### Style Compliance
   - ✅ Naming conventions
   - ⚠️ Import ordering in 1 file

   ### Summary
   <Overall assessment and recommended next steps>
   ```

7. **Ask for Disposition:**
   "Based on this review, would you like to: (A) Mark the track as complete, (B) Create follow-up tasks for the issues found, or (C) Continue implementation to address the gaps?"

   Wait for the user's response and take the appropriate action.
