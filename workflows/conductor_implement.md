---
description: Execute the plan for the current active track, working through tasks sequentially
---

1. Read the Conductor skill instructions at the skill file for Conductor.
2. **Locate the project root:**
   - First, check the current working directory and its parents for a `conductor/` directory.
   - If not found, check the root of the current Git repository (`git rev-parse --show-toplevel`) for a `conductor/` directory.
   - If found, use that path as `{PROJECT_ROOT}` and inform the user: "Found Conductor context at `{PROJECT_ROOT}/conductor/`."
   - If NOT found, ask the user: **"I couldn't find a `conductor/` directory in this workspace. Please specify the project root path where it exists (or should be created)."** Wait for the user's response and use the provided path as `{PROJECT_ROOT}`.

3. **Load Context:** Read all conductor context files from `{PROJECT_ROOT}/conductor/`:
   - `conductor/product.md`
   - `conductor/product-guidelines.md`
   - `conductor/tech-stack.md`
   - `conductor/workflow.md`
   - `conductor/tracks.md`

4. **Identify the Active Track:**
   - Find the track marked `[~]` (in-progress) in `conductor/tracks.md`.
   - If no track is marked `[~]`, find the first `[ ]` (pending) track.
   - If no pending tracks exist, inform the user: "No pending tracks found. Run `/conductor_newTrack` to create one."
   - Read the track's `plan.md` and `spec.md`.

4. **Execute Tasks Sequentially:**

   For each uncompleted task (`[ ]`) in the plan:

   **Step 4.1: Select and Mark Task**
   - Find the next `[ ]` task in sequential order.
   - Mark it as `[~]` in `plan.md`.
   - Update `metadata.json` with `"status": "in_progress"` and current timestamp.

   **Step 4.2: Critical Examination**
   - Before implementing, examine the task critically.
   - If there is any ambiguity, ask the user a specific question to resolve it. Wait for their response.

   **Step 4.3: Write Failing Tests (Red Phase)**
   - If TDD is configured in `conductor/workflow.md`:
     - Write test(s) that define the expected behavior for this task.
     - Run the tests and confirm they fail as expected.
   - If TDD is not configured, skip to implementation.

   **Step 4.4: Implement (Green Phase)**
   - Write the minimum code necessary to make the tests pass (or to fulfill the task if no TDD).
   - Run the test suite and confirm all tests pass.

   **Step 4.5: Refactor**
   - With passing tests, refactor for clarity and quality.
   - Re-run tests to confirm they still pass.

   **Step 4.6: Verify Coverage**
   - Run coverage reports using the project's configured tools.
   - Target the coverage threshold defined in `conductor/workflow.md`.

   **Step 4.7: Document Deviations**
   - If the implementation required diverging from `tech-stack.md`, update it with the new approach and a dated note.

   **Step 4.8: Commit**
   - Stage changes and commit with a structured message following the format in `conductor/workflow.md`.
   - Record the commit SHA in `plan.md` next to the completed task.

   **Step 4.9: Mark Complete**
   - Update the task from `[~]` to `[x]` in `plan.md`.

5. **Phase Completion Verification:**

   When the last task in a phase is completed:

   **Step 5.1:** Inform the user that the phase is complete.

   **Step 5.2:** Run the automated test suite and report results.

   **Step 5.3:** Generate a manual verification plan with specific, actionable steps:
   - For frontend changes: commands to start dev server, URLs to visit, expected visual outcomes.
   - For backend changes: curl commands, expected responses, database state checks.

   **Step 5.4:** Present the verification plan and ask: **"Does this meet your expectations? Please confirm with yes or provide feedback."**

   **Wait for explicit user confirmation before proceeding to the next phase.**

   **Step 5.5:** Create a checkpoint commit (e.g., `conductor(checkpoint): Checkpoint end of Phase X`).

6. **Track Completion:**

   When all phases are done:
   - Update `metadata.json` with `"status": "completed"` and current timestamp.
   - Mark the track as `[x]` in `conductor/tracks.md`.
   - Display: "✅ Track complete! Run `/conductor_review` to review the work against the spec."
