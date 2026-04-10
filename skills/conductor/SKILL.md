---
name: Conductor Skill
description: Skill to process, run, and perform Gemini CLI Conductor commands (/conductor_setup, /conductor_newTrack, /conductor_implement, /conductor_status, /conductor_revert, /conductor_review) and read/generate artifacts in the conductor/ directory.
---

# Gemini CLI Conductor Skill

This skill enables Antigravity to act as the Conductor agent — managing the full
lifecycle of software development tracks: context setup, specification,
planning, implementation, review, and documentation synchronization.

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

## Interaction Convention

All Conductor commands use **structured choices** for user interactions. When a
command needs user input, present options as structured choices with clear
labels and descriptions rather than freeform text prompts. This applies to:

-   Artifact generation mode: "Interactive" vs "Autogenerate"
-   Draft confirmations: "Approve" vs "Revise"
-   Scope selections: presented as labeled options with descriptions
-   Disposition choices: "Archive" / "Delete" / "Skip"

## Artifact Output Convention

Whenever a Conductor command produces **structured output that requires user
review** — clarifying questions, reports, summaries, specs, plans, or
confirmation prompts — **always write it as an Antigravity artifact** using
`write_to_file` with `IsArtifact: true` and present it via `notify_user` with
`PathsToReview`.

### Artifact Types

-   **`walkthrough`** — Review reports, status dashboards, phase verification
    plans
-   **`implementation_plan`** — Specs, plans, and proposals
-   **`other`** — Clarifying questions, confirmation prompts, revert previews

### Naming Convention

Artifact filenames follow the pattern: `conductor_<command>_<context>.md`

Examples: `conductor_setup_product_questions.md`,
`conductor_review_dark_mode_toggle.md`, `conductor_status.md`

### Formatting

Use rich markdown in artifacts: **tables**, **alerts** (`[!NOTE]`, `[!TIP]`,
`[!IMPORTANT]`, `[!WARNING]`), **file links** (`[file.ts](file:///path)`),
**mermaid diagrams**, and **code blocks** where useful.

### Blocking

Set `BlockedOnUser: true` in `notify_user` when the artifact contains questions
or requires explicit approval before proceeding. Set `BlockedOnUser: false` for
informational outputs (status, review reports) unless a disposition choice is
required.

--------------------------------------------------------------------------------

## Commands

### `/conductor_setup`

**Purpose:** Initialize or update the project's Conductor context (run once per
project).

> **Full interaction protocol:** The complete interactive prompting script is in
> the `conductor_setup` skill (sibling directory `../conductor_setup/SKILL.md`).

**Capabilities:**

-   **Brownfield/Greenfield Detection** — Scans for dependency manifests
    (`package.json`, `go.mod`, `BUILD`, etc.), source directories, and existing
    architecture to classify the project type.
-   **Interactive/Autogenerate Mode** — For each context artifact, offers the
    user a choice between guided interactive creation or AI-drafted content.
-   **Draft Review Loops** — Every generated artifact is presented for approval
    with "Approve" / "Suggest changes" structured choices.
-   **Skills Selection** — Checks for a skills catalog, recommends relevant
    skills based on detected tech stack, and installs user selections.
-   **Setup State Tracking** — Uses `setup_state.json` to resume interrupted
    setups from the last completed step.

**Steps:**

1.  Detect project type (Brownfield vs Greenfield) by scanning manifests.
2.  For each context artifact, use Interactive or Autogenerate mode:
    -   `conductor/product.md` — Product definition & vision
    -   `conductor/product-guidelines.md` — Tone, visual identity, UX patterns
    -   `conductor/tech-stack.md` — Technical choices & frameworks
    -   `conductor/code_styleguides/` — Language-specific style guides
    -   `conductor/workflow.md` — Task workflow & coding practices
3.  Generate `conductor/index.md` linking all context files.
4.  Update `conductor/setup_state.json` after each successful step.
5.  Commit all setup files.

--------------------------------------------------------------------------------

### `/conductor_newTrack`

**Purpose:** Start a new feature or bug fix track with a specification and
phased plan, using an enhanced discovery protocol.

> **Full interaction protocol:** The complete interactive prompting script
> including enhanced discovery is in the `conductor_newTrack` skill (sibling
> directory `../conductor_newTrack/SKILL.md`).

**Syntax:**

-   `/conductor_newTrack` — Interactive mode (ask user for description)
-   `/conductor_newTrack "description of feature or bug"` — Direct mode

**Capabilities:**

-   **Codebase Reconnaissance** — Scans existing code, tech stack, and prior
    track specs before asking questions. Questions are informed by actual
    codebase context, not generic.
-   **Design Decision Elicitation** — Identifies 2-4 key architectural decisions
    (e.g., "extend existing module vs new service") and presents them as
    structured choices with pros/cons.
-   **Gap Analysis** — Checks the draft spec against error handling, edge cases,
    backwards compatibility, security, performance, accessibility, and testing
    strategy. Suggests improvements.
-   **Cross-Track Awareness** — Reads existing track specs to identify
    overlapping scope, sequencing dependencies, and shared components.
-   **Devil's Advocate** — Challenges 2-3 assumptions in the spec based on
    codebase context before final approval.

**Steps:**

1.  **Setup Check:** Verify `product.md`, `tech-stack.md`, `workflow.md` exist.
2.  **Capture Description:** Accept from argument or interactive prompt.
3.  **Infer Track Type:** Feature vs Bug/Chore from description analysis.
4.  **Duplicate Check & Init:** Verify no name collisions, create track dir.
5.  **Codebase Reconnaissance:** Scan existing code and track specs.
6.  **Interactive Spec Questions:** Structured choices, 3-4 batched questions.
7.  **Design Decisions:** Present architectural forks as structured choices.
8.  **Draft Spec:** Generate spec with Overview, Functional/Non-Functional
    Requirements, Design Decisions, Acceptance Criteria, Out of Scope.
9.  **Gap Analysis:** Structured gap check with concrete suggestions.
10. **Cross-Track Awareness:** Identify overlaps and dependencies.
11. **Devil's Advocate:** Challenge assumptions before approval.
12. **Final Spec Confirmation:** Present for approval via artifact review.
13. **Generate Plan:** Phased plan with TDD tasks and verification checkpoints.
14. **Generate Artifacts:** metadata.json, index.md, update tracks.md.
15. **Commit:** VCS commit with standardized message.

--------------------------------------------------------------------------------

### `/conductor_implement`

**Purpose:** Execute the plan for the current active track, working through
tasks sequentially with TDD lifecycle and phase checkpointing.

> **Full interaction protocol:** The complete execution protocol including TDD
> lifecycle, phase checkpointing, document synchronization, and track cleanup is
> in the `conductor_implement` skill (sibling directory
> `../conductor_implement/SKILL.md`).

**Capabilities:**

-   **Track Selection** — Accepts explicit track name or auto-detects the first
    non-completed track. Confirms with structured choice.
-   **TDD Lifecycle** — Red/Green/Refactor workflow per task as defined in
    `conductor/workflow.md`.
-   **Phase Checkpointing** — User manual verification at each phase boundary.
-   **Document Synchronization** — After track completion, proposes diff-based
    updates to `product.md`, `tech-stack.md`, and `product-guidelines.md` to
    keep project-level docs current.
-   **Track Cleanup** — Offers Archive, Delete, Review, or Skip options after
    track completion.

**Steps:**

1.  **Setup Check:** Verify core conductor files exist.
2.  **Select Track:** From argument or auto-detect, confirm selection.
3.  **Execute Tasks:** Sequential TDD workflow, marking progress in plan.md.
4.  **Phase Verification:** Checkpoint at each phase boundary.
5.  **Document Sync:** Propose updates to project-level docs on completion.
6.  **Track Cleanup:** Archive, Delete, Review, or Skip via structured choice.

**Important:** The user's `conductor/workflow.md` is the authoritative source
for task workflow, commit conventions, quality gates, and checkpointing
behavior. Always defer to it.

--------------------------------------------------------------------------------

### `/conductor_status`

**Purpose:** Get a high-level overview of project progress across all tracks.

> **Full interaction protocol:** The complete protocol is in the
> `conductor_status` skill (sibling directory `../conductor_status/SKILL.md`).

**Capabilities:**

-   **Dual Format Parsing** — Supports both new (`- [ ] **Track:`) and legacy
    (`## [ ] Track:`) format in tracks.md.
-   **Task-Level Progress** — Reads each track's plan.md for granular progress.
-   **Enhanced Summary** — Current date/time, project health assessment, current
    phase/task, next action, blockers, and percentage progress.

**Output includes:**

-   Project Status: "On Track" / "Behind Schedule" / "Blocked"
-   Current Phase and Task (the `[~]` item)
-   Next Action Needed (next `[ ]` pending task)
-   Blockers (if any)
-   Progress: tasks_completed/tasks_total (percentage)

--------------------------------------------------------------------------------

### `/conductor_revert`

**Purpose:** Undo work from a track, phase, or task using VCS-aware revert.

> **Full interaction protocol:** The complete revert protocol including guided
> selection and VCS reconciliation is in the `conductor_revert` skill (sibling
> directory `../conductor_revert/SKILL.md`).

**Capabilities:**

-   **Guided Menu Selection** — Scans all tracks and plans, presents a
    prioritized menu of revertable items (in-progress first, then recent).
-   **Direct Target** — Accepts explicit target as argument with confirmation.
-   **VCS Reconciliation** — Handles ghost commits (from rebase/squash),
    plan-update commits, track creation commits, and cherry-pick duplicates.
-   **Execution Plan** — Presents a detailed preview (SHAs, messages, planned
    actions) for approval before executing.

**Steps:**

1.  **Setup Check:** Verify tracks.md exists and is not empty.
2.  **Target Selection:** Path A (direct argument) or Path B (guided menu).
3.  **VCS Reconciliation:** Find all associated commits, handle rewrites.
4.  **Execution Plan:** Present preview artifact for approval.
5.  **Execute Reverts:** VCS-appropriate commands in reverse chronological
    order.
6.  **Verify Plan State:** Ensure status markers are correctly reset.

--------------------------------------------------------------------------------

### `/conductor_review`

**Purpose:** Review completed work against specifications, guidelines, and
quality gates.

> **Full interaction protocol:** The complete review protocol including smart
> chunking and auto-fix is in the `conductor_review` skill (sibling directory
> `../conductor_review/SKILL.md`).

**Capabilities:**

-   **Smart Chunking** — Detects diff size;
    <300 lines uses single-pass review, >300 lines uses iterative per-file
    review with user confirmation.
-   **Code Style Enforcement** — Treats `code_styleguides/*.md` as "Law";
    violations are rated High severity.
-   **Auto-Fix Application** — Can automatically apply suggested fixes when user
    selects "Apply Fixes".
-   **Review Commit Tracking** — Records fix commits in plan.md with SHAs.
-   **Track Cleanup** — Offers Archive/Delete/Skip after review completion.

**Steps:**

1.  **Setup Check:** Verify core conductor files exist.
2.  **Scope Identification:** Auto-detect active track or accept user input.
3.  **Context Retrieval:** Load guidelines, style guides, installed skills.
4.  **Smart Chunking:** Volume check, select single-pass or iterative strategy.
5.  **Analysis:** Intent, style, correctness, safety, testing checks.
6.  **Report:** Generate structured review report artifact.
7.  **Decision:** "Apply Fixes" / "Manual Fix" / "Complete Track".
8.  **Commit & Cleanup:** Record changes, offer track disposition.

--------------------------------------------------------------------------------

## Task Status Markers

These markers are used consistently in `plan.md` and `tracks.md`:

Marker | Meaning
------ | ---------------------
`[ ]`  | Pending / Not started
`[~]`  | In progress
`[x]`  | Completed

## Track Archival

When a track is completed, it can be archived via the cleanup flow in
`/conductor_implement` or `/conductor_review`. The track directory is moved from
`conductor/tracks/` to `conductor/archive/`, and the entry in `tracks.md` is
updated accordingly.

## Conductor Guardrails

When operating as the Conductor agent, always follow these safety rules:

-   **Never modify conductor files outside the active track** — only update
    files in `conductor/tracks/<active_track_id>/` and `conductor/tracks.md`
    during implementation. Document sync (post-completion) is the exception.
-   **Always confirm before overwriting user-approved specs or plans** — if a
    spec or plan has been explicitly approved, do not modify it without asking.
-   **Ask before destructive operations** — do not delete tracks, revert
    commits, or remove conductor artifacts without explicit user confirmation.
-   **Use structured choices for all decisions** — present options as labeled
    choices rather than freeform prompts for consistency and clarity.
-   **Spec and plan approval gates** — during `/conductor_newTrack`, always
    present the spec and plan for explicit user approval before proceeding.
-   **Document sync is opt-in** — during post-track doc synchronization, always
    present proposed changes as diffs for user approval.

## Locating the Conductor Directory

Before operating on any conductor files or creating the `conductor/` directory,
**you MUST ask the user to explicitly specify the project root path** (e.g., the
repository path where the directory exists or should be created). Do not
attempt to automatically guess or determine the directory from the current
working context. Use the user-provided path as the `{PROJECT_ROOT}` for all
conductor operations in the session.
