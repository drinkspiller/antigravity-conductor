---
description: Start a new feature or bug fix track with a specification and phased plan
---

1. Read the Conductor skill instructions at the skill file for Conductor.
2. **Locate the project root:**
   - First, check the current working directory and its parents for a `conductor/` directory.
   - If not found, check the root of the current Git repository (`git rev-parse --show-toplevel`) for a `conductor/` directory.
   - If found, use that path as `{PROJECT_ROOT}` and inform the user: "Found Conductor context at `{PROJECT_ROOT}/conductor/`."
   - If NOT found, ask the user: **"I couldn't find a `conductor/` directory in this workspace. Please specify the project root path where it exists (or should be created)."** Wait for the user's response and use the provided path as `{PROJECT_ROOT}`.

3. **Load Context:** Read all conductor context files in order from `{PROJECT_ROOT}/conductor/`:
   - `conductor/product.md`
   - `conductor/product-guidelines.md`
   - `conductor/tech-stack.md`
   - `conductor/workflow.md`
   - `conductor/tracks.md`

4. **Get the Feature/Bug Description:**
   - If a description was provided after the command (e.g., `/conductor_newTrack "add dark mode"`), use it.
   - If no description was provided, ask: **"What feature or bug would you like to work on? Describe it in 1-2 sentences."** Wait for the user's response.

4. **Research the Codebase:**
   - Search the codebase for files, components, and patterns relevant to the described feature or bug.
   - Identify the areas of code that will likely need modification.
   - Present a brief summary of your findings: "Here's what I found in the codebase that's relevant to this track: ..."

5. **Ask Clarifying Questions:**
   Before writing the spec, ask the user **3-5 specific, actionable questions** about the feature. Tailor these to the description and codebase findings. Example question categories:

   - **Scope:** "Should this include [related feature X], or is that out of scope?"
   - **Edge cases:** "How should the system behave when [edge case Y] occurs?"
   - **UI/UX:** "Do you have a design or wireframe, or should I propose a UI approach?"
   - **Data model:** "Does this require new fields/tables, or can we reuse existing structures?"
   - **Acceptance criteria:** "What does 'done' look like? Any specific metrics or behaviors to validate?"

   **Wait for the user's responses before proceeding.**

6. **Generate the Specification (`spec.md`):**
   Based on the description, codebase research, and user answers, generate `conductor/tracks/<track_id>/spec.md` with this structure:

   ```
   # Specification: <Track Title>

   ## Overview
   <Brief description and context>

   ## Functional Requirements
   - <Detailed requirements>

   ## UI/UX Details
   - <If applicable>

   ## Acceptance Criteria
   - [ ] <Testable criteria>

   ## Out of Scope
   - <Explicit exclusions>
   ```

   **Present the spec to the user and ask: "Does this spec accurately capture what you want to build? Reply yes to approve, or suggest changes."**

   **Do not proceed until the user explicitly approves the spec.**

7. **Generate the Implementation Plan (`plan.md`):**
   After spec approval, break it into a phased plan with tasks and sub-tasks:

   ```
   # Implementation Plan - <Track Title>

   ## Phase 1: <Phase Name>
   - [ ] Task: <Task Name>
     - [ ] <Sub-task>
     - [ ] <Sub-task>
   - [ ] Task: Conductor - User Manual Verification 'Phase 1: <Phase Name>'

   ## Phase 2: <Phase Name>
   ...
   ```

   Follow the TDD workflow from `conductor/workflow.md` if TDD is configured. Each phase should end with a verification task.

   **Present the plan to the user and ask: "Does this plan look good? Reply yes to approve, or suggest changes."**

   **Do not proceed until the user explicitly approves the plan.**

8. **Generate Supporting Files:**
   - `conductor/tracks/<track_id>/metadata.json` with track_id, type, status, timestamps, and description.
   - `conductor/tracks/<track_id>/index.md` linking to spec.md, plan.md, and metadata.json.

9. **Update the Track Registry:**
   Add an entry to `conductor/tracks.md`:
   ```
   - [ ] **Track: <Track Title>** _Link: [./tracks/<track_id>/](./tracks/<track_id>/)_
   ```

10. **Confirm Completion:**
    Display: "✅ Track `<track_id>` created! Run `/conductor_implement` to start working through the plan."
