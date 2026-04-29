---
name: conductor_chat
description: Load all Conductor project context (product, tech-stack, guidelines, workflow, active tracks) and proceed immediately to the user's task. Use when asked to "use conductor context", "load conductor", "conductor chat", or when the user wants to work with conductor knowledge without creating tracks or running the full ceremony.
---

# Conductor Chat — Context-Primed Freeform Agent

**Purpose:** Rapidly ingest all Conductor project knowledge into context and
then proceed directly to the user's task — no follow-up questions, no new
tracks, no approval gates. This is the lightweight complement to the full
Conductor workflow.

## When to Use

-   The user wants to leverage existing Conductor project knowledge to inform a
    coding task, research question, or design decision.
-   The user wants to "just go" with conductor context without the ceremony of
    creating tracks, specs, or plans.
-   The user invokes `/conductor_chat` or asks to "load conductor context."

## Protocol

### Step 1: Locate the Conductor Directory

1.  **Auto-detect** the conductor directory using these heuristics (in priority
    order):

    -   Check the user's open editor files for paths containing `/conductor/`.
        Extract the `{PROJECT_ROOT}` from the path (the parent of `conductor/`).
    -   Check the user's current workspace root for a `conductor/` subdirectory.
    -   If the user's prompt mentions a path, use it.

2.  **Confidence gate:**

    -   If exactly ONE candidate `conductor/` directory is found with high
        certainty, use it. Announce: `"Using conductor context at
        {PROJECT_ROOT}"`
    -   If MULTIPLE candidates are found, present them as options and ask the
        user to pick.
    -   If NO candidate is found, ask the user: `"I couldn't locate a conductor/
        directory. Please specify the project root path containing the
        conductor/ directory."`

3.  **Validate** the located directory by checking that at least
    `{PROJECT_ROOT}/conductor/product.md` exists. If it does not exist, inform
    the user that the Conductor context is not initialized and suggest running
    `/conductor_setup`.

### Step 2: Tiered Context Loading

Load the project context in two tiers. Read files silently — do NOT produce
artifacts, summaries, or status reports for the loading process itself.

#### Tier 1: Core Context (always loaded)

Read the following files, in this order. Skip any that do not exist (note the
absence but do not halt):

1.  `{PROJECT_ROOT}/conductor/product.md` — Product definition & vision
2.  `{PROJECT_ROOT}/conductor/product-guidelines.md` — Tone, visual identity, UX
3.  `{PROJECT_ROOT}/conductor/tech-stack.md` — Technical choices & frameworks
4.  `{PROJECT_ROOT}/conductor/workflow.md` — Task workflow & coding practices
5.  `{PROJECT_ROOT}/conductor/tracks.md` — Track registry

#### Tier 2: Active Track Context (loaded selectively)

1.  Parse `tracks.md` for all tracks. Identify tracks marked as in-progress
    (`[~]`) or pending (`[ ]`).
2.  For each active or pending track, read:
    -   `{PROJECT_ROOT}/conductor/tracks/{track_id}/spec.md`
    -   `{PROJECT_ROOT}/conductor/tracks/{track_id}/plan.md`
3.  **Skip** the following unless the user's prompt explicitly references them:
    -   Archived tracks (`{PROJECT_ROOT}/conductor/archive/`)
    -   `review.md` files
    -   `metadata.json` and `index.md` files (low information density)
4.  If the user's prompt mentions a specific track by name (including archived
    tracks), load that track's `spec.md` and `plan.md` as well.

#### Tier 2b: Code Style Guides (loaded if present)

If `{PROJECT_ROOT}/conductor/code_styleguides/` exists, read all files in it.
These inform code quality expectations.

### Step 3: Act on the User's Task

After context is loaded, determine the next action:

-   **If the user's prompt or prior conversation context contains a task,
    question, or request:** Proceed immediately to fulfilling it using standard
    agent tools (file editing, code search, building, testing, etc.). The loaded
    conductor context informs your work — use the product vision, tech-stack
    decisions, style guides, and active track knowledge to guide your actions.

-   **If there is no accompanying prompt or prior context:** Announce that the
    project context is loaded and briefly state what you found (e.g., "Loaded
    conductor context for {product name}: {N} active tracks, tech stack is
    {summary}. Ready — what would you like to work on?"). Do NOT produce a
    detailed status artifact — that's what `/conductor_status` is for.

## Guardrails

### Read-Only Default

-   **Do NOT modify, create, or delete any files inside
    `{PROJECT_ROOT}/conductor/` unless the user explicitly asks you to.** This
    includes tracks, specs, plans, and all context files.
-   If your task requires changes that would normally trigger a conductor
    workflow (e.g., creating a new track, updating a spec), inform the user and
    suggest the appropriate conductor command instead of doing it yourself.

### Explicit Escape Hatch

-   If the user explicitly asks you to modify conductor files (e.g., "update the
    spec for track X" or "add a task to the plan"), you may do so. But announce
    what you're changing before making the edit.

### No Ceremony

-   Do NOT create artifacts for the loading process.
-   Do NOT ask structured choice questions after loading (no `ask_question`
    calls for approval gates, mode selection, or confirmation).
-   Do NOT create new tracks, specs, or plans.
-   The only acceptable question is asking for the conductor directory path
    (Step 1) if auto-detection fails.

## Conductor Directory Structure Reference

For reference, the standard conductor directory layout is:

```
conductor/
├── index.md                  # Links to all context files
├── product.md                # Product definition & vision
├── product-guidelines.md     # Tone, visual identity, UX patterns
├── tech-stack.md             # Technical choices & frameworks
├── workflow.md               # Task workflow, coding principles, commands
├── setup_state.json          # Setup progress tracking
├── code_styleguides/         # Language-specific style guides
├── tracks.md                 # Registry of all tracks (features/bugs)
├── tracks/                   # Active track directories
│   └── <track_id>/
│       ├── spec.md           # Detailed specification
│       ├── plan.md           # Phased implementation plan
│       └── metadata.json     # Track metadata
└── archive/                  # Completed track directories
```
