---
name: Conductor Skill
description: Skill to process, run, and perform Gemini CLI Conductor commands (/conductor_setup, /conductor_newTrack, /conductor_implement, /conductor_status, /conductor_revert, /conductor_review) and read/generate artifacts in the conductor/ directory.
---

# Gemini CLI Conductor Skill

This skill enables Antigravity to act as the Conductor agent — managing the full
lifecycle of software development tracks: context setup, specification,
planning, implementation, and review.

## Conductor Directory

The conductor directory lives at `{PROJECT_ROOT}/conductor/` — the root of the
user's project repository (NOT the Antigravity brain/artifacts directory). All
conductor artifacts are project-level files committed to version control.

### Directory Structure

```
conductor/
├── index.md                  # Links to all context files
├── product.md                # Product definition & vision
├── product-guidelines.md     # Tone, visual identity, UX patterns
├── tech-stack.md             # Technical choices & frameworks
├── workflow.md               # Task workflow, coding principles, commands
├── setup_state.json          # Setup progress tracking
├── code_styleguides/         # Language-specific style guides
│   ├── html-css.md
│   ├── javascript.md
│   ├── scss.md
│   └── typescript.md
├── tracks.md                 # Registry of all tracks (features/bugs)
├── tracks/                   # Active track directories
│   └── <track_id>/
│       ├── index.md          # Track context links
│       ├── spec.md           # Detailed specification
│       ├── plan.md           # Phased implementation plan
│       └── metadata.json     # Track metadata
└── archive/                  # Completed track directories
```

## Context Loading

**Before executing ANY Conductor command**, load the project context by reading
these files (in order of priority):

1.  `conductor/product.md` — What the product is
2.  `conductor/product-guidelines.md` — How it should look & feel
3.  `conductor/tech-stack.md` — Technical decisions
4.  `conductor/workflow.md` — Task workflow & coding practices
5.  `conductor/tracks.md` — Current track registry

## Commands

### `/conductor_setup`

**Purpose:** Initialize or update the project's Conductor context (run once per
project).

> **Full interaction protocol:** See the `conductor_setup` workflow file for the
> complete interactive prompting script.

**Steps:**

1.  Check if `conductor/` directory exists.
2.  If it exists, read `conductor/setup_state.json` to determine what's already
    configured.
3.  For each missing artifact, interactively guide the user to create:
    -   `conductor/product.md` — Ask about project vision, users, goals
    -   `conductor/product-guidelines.md` — Ask about tone, visual identity, UX
        patterns
    -   `conductor/tech-stack.md` — Ask about languages, frameworks, databases
    -   `conductor/workflow.md` — Copy the template from the bundled
        `templates/workflow_template.md` (located alongside this SKILL.md) and
        customize based on user responses
    -   `conductor/code_styleguides/` — Generate style guides for each language
        in use
    -   `conductor/tracks.md` — Initialize empty track registry
    -   `conductor/index.md` — Generate links to all context files
4.  Update `conductor/setup_state.json` after each successful step.
5.  **Never generate two artifacts without a user interaction in between.**

--------------------------------------------------------------------------------

### `/conductor_newTrack`

**Purpose:** Start a new feature or bug fix track with a specification and
phased plan.

> **Full interaction protocol:** See the `conductor_newTrack` workflow file for
> the complete interactive prompting script.

**Syntax:**

-   `/conductor_newTrack` — Interactive mode (ask user for description)
-   `/conductor_newTrack "description of feature or bug"` — Direct mode

**Steps:**

1.  **Load Context:** Read all conductor context files (product, guidelines,
    tech-stack, workflow).
2.  **Generate Track ID:** Format: `<snake_case_short_name>_<YYYYMMDD>` (e.g.,
    `dark_mode_toggle_20260218`).
3.  **Create Track Directory:** `conductor/tracks/<track_id>/`
4.  **Generate Specification (`spec.md`):**

    -   Research the codebase to understand relevant existing code.
    -   Ask the user clarifying questions about requirements.
    -   Write the spec following this structure:

        ```markdown
        # Specification: <Track Title>

        ## Overview

        <Brief description and context>

        ## Functional Requirements

        - <Detailed requirements>

        ## UI/UX Details

        - <If applicable, reference Figma or design details>

        ## Acceptance Criteria

        - [ ] <Testable criteria>

        ## Out of Scope

        - <Explicit exclusions>
        ```

    -   **Present spec to user for review before proceeding.**

5.  **Generate Plan (`plan.md`):**

    -   Break the spec into phased implementation with tasks and sub-tasks.
    -   Follow TDD workflow from `conductor/workflow.md`.
    -   Each phase ends with a "Conductor - User Manual Verification" task.
    -   Structure:

        ```markdown
        # Implementation Plan - <Track Title>

        ## Phase 1: <Phase Name>

        - [ ] Task: <Task Name>
          - [ ] <Sub-task>
          - [ ] <Sub-task>
        - [ ] Task: Conductor - User Manual Verification 'Phase 1: <Phase Name>' (Protocol in workflow.md)

        ## Phase 2: <Phase Name>

        ...
        ```

    -   **Present plan to user for review before proceeding.**

6.  **Generate Metadata (`metadata.json`):**

    ```json
    {
      "track_id": "<track_id>",
      "type": "feature|bugfix",
      "status": "new",
      "created_at": "<ISO 8601 timestamp>",
      "updated_at": "<ISO 8601 timestamp>",
      "description": "<one-line description>"
    }
    ```

7.  **Generate Index (`index.md`):**

    ```markdown
    # Track <track_id> Context

    - [Specification](./spec.md)
    - [Implementation Plan](./plan.md)
    - [Metadata](./metadata.json)
    ```

8.  **Update Registry:** Add entry to `conductor/tracks.md`: `markdown - [ ]
    **Track: <Track Title>** _Link:
    [./tracks/<track_id>/](./tracks/<track_id>/)_`

--------------------------------------------------------------------------------

### `/conductor_implement`

**Purpose:** Execute the plan for the current active track, working through
tasks sequentially.

> **Full interaction protocol:** See the `conductor_implement` workflow file for
> the complete execution protocol including TDD lifecycle and phase
> checkpointing.

**Steps:**

1.  **Load Context:** Read all conductor context files.
2.  **Identify Active Track:** Find the track marked `[~]` or the first `[ ]`
    track in `conductor/tracks.md`.
3.  **Read Track Plan:** Load `conductor/tracks/<track_id>/plan.md`.
4.  **Execute Tasks Sequentially** following the workflow defined in
    `conductor/workflow.md`:
    -   Find the next `[ ]` task in the plan.
    -   Mark it as `[~]` (in-progress).
    -   Follow the Standard Task Workflow from `conductor/workflow.md`:
        1.  Critical examination & ambiguity resolution
        2.  Write failing tests (Red Phase) if TDD is configured
        3.  Implement to pass tests (Green Phase)
        4.  Refactor
        5.  Verify coverage
        6.  Document deviations
    -   Mark completed tasks as `[x]`.
    -   Update `metadata.json` with `"status": "in_progress"` and new timestamp.
5.  **Phase Verification:** When a phase is complete, follow the Phase
    Completion Verification and Checkpointing Protocol from
    `conductor/workflow.md`.
6.  **Track Completion:** When all phases are done:
    -   Update `metadata.json` with `"status": "completed"`.
    -   Mark the track as `[x]` in `conductor/tracks.md`.

**Important:** The user's `conductor/workflow.md` is the authoritative source
for task workflow, commit conventions, quality gates, and checkpointing
behavior. Always defer to it.

--------------------------------------------------------------------------------

### `/conductor_status`

**Purpose:** Get a high-level overview of project progress.

> **Full interaction protocol:** See the `conductor_status` workflow file.

**Steps:**

1.  Read `conductor/tracks.md` and display:
    -   Total tracks, completed, in-progress, pending.
    -   For each in-progress track, read its `plan.md` and show phase/task
        progress.
2.  Format output as a clear summary table.

**Output format:**

```
## Project Status

### Track Registry
| # | Track | Status |
|---|-------|--------|
| 1 | Feature X | ✅ Complete |
| 2 | Bug Fix Y | 🔄 In Progress (Phase 2, Task 3/5) |
| 3 | Feature Z | ⬜ Pending |

### Active Track: <track_name>
- Phase 1: ✅ Complete
- Phase 2: 🔄 In Progress
  - [x] Task 1
  - [x] Task 2
  - [~] Task 3 (current)
  - [ ] Task 4
  - [ ] Task 5
- Phase 3: ⬜ Pending
```

--------------------------------------------------------------------------------

### `/conductor_revert`

**Purpose:** Undo work from a track, phase, or task.

> **Full interaction protocol:** See the `conductor_revert` workflow file for
> the complete revert protocol including scope selection and confirmation.

**Steps:**

1.  Read `conductor/tracks.md` to identify the current active track.
2.  Ask user what to revert:
    -   **Entire track:** Revert all commits associated with the track.
    -   **Current phase:** Revert to the last phase checkpoint.
    -   **Last task:** Revert the most recent task commit.
3.  Detect the workspace VCS type (git, hg/Fig, or g4/Piper) and use its
    history commands with checkpoint SHAs from `plan.md` to identify the
    change range (e.g., `git log`, `hg log`, or `g4 changes`).
4.  Execute the appropriate revert command for the detected VCS
    (e.g., `git revert`, `hg backout`, or `g4 revert`).
5.  Update `plan.md` and `tracks.md` status markers accordingly.

--------------------------------------------------------------------------------

### `/conductor_review`

**Purpose:** Review completed work against specifications and guidelines.

> **Full interaction protocol:** See the `conductor_review` workflow file for
> the complete review protocol including acceptance criteria checking.

**Steps:**

1.  Read the active track's `spec.md` and `plan.md`.
2.  Read `conductor/product-guidelines.md`.
3.  Review all changed files using the workspace's VCS diff command
    (e.g., `git diff`, `hg diff`, or `g4 diff`) against the track start point.
4.  Evaluate against:
    -   Acceptance criteria from `spec.md`
    -   Quality gates from `conductor/workflow.md`
    -   Style guides from `conductor/code_styleguides/`
5.  Generate a review report with:
    -   ✅ Criteria met
    -   ⚠️ Warnings
    -   ❌ Issues to address

--------------------------------------------------------------------------------

## Task Status Markers

These markers are used consistently in `plan.md` and `tracks.md`:

Marker | Meaning
------ | ---------------------
`[ ]`  | Pending / Not started
`[~]`  | In progress
`[x]`  | Completed

## Track Archival

When a track is completed, its directory can be moved from `conductor/tracks/`
to `conductor/archive/` for cleanliness. The track entry in `tracks.md` should
be updated with the new link path.

## Conductor Guardrails

When operating as the Conductor agent, always follow these safety rules:

-   **Never modify conductor files outside the active track** — only update
    files in `conductor/tracks/<active_track_id>/` and `conductor/tracks.md`
    during implementation.
-   **Always confirm before overwriting user-approved specs or plans** — if a
    spec or plan has been explicitly approved, do not modify it without asking.
-   **Ask before destructive operations** — do not delete tracks, revert
    commits, or remove conductor artifacts without explicit user confirmation.
-   **One artifact at a time during setup** — never generate two setup
    artifacts without a user interaction in between.
-   **Spec and plan approval gates** — during `/conductor_newTrack`, always
    present the spec and plan for explicit user approval before proceeding.

## Locating the Conductor Directory

Before operating on any conductor files, locate the project root using this
priority order:

1.  **Walk up from the current working directory** — check each parent for a
    `conductor/` subdirectory.
2.  **Check the Git repository root** — run `git rev-parse --show-toplevel` and
    check for `conductor/` there.
3.  **Ask the user** — if neither search finds a `conductor/` directory, prompt
    the user to specify the project root path.

Once resolved, use the path as `{PROJECT_ROOT}` for all conductor operations
in the session. For `/conductor_setup`, if no existing directory is found, ask
the user where to create it.
