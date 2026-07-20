---
trigger: always_on
description: Conductor universal protocol - operational guardrails for all conductor skills
---

# Conductor Universal Protocol (Controller Layer)

These operational standards apply globally to all Conductor skills. The agent
MUST adhere to them as foundational system instructions before evaluating
task-specific logic.

## 0. Conductor Directory

The conductor directory lives at `{PROJECT_ROOT}/conductor/` — the root of the
user's project repository (NOT the Jetski brain/artifacts directory). All
conductor artifacts are project-level files committed to version control.

```
conductor/
├── index.md                  # Links to all context files
├── product.md                # Product definition & vision
├── product-guidelines.md     # Tone, visual identity, UX patterns
├── tech-stack.md             # Technical choices & frameworks
├── workflow.md               # Task workflow, coding principles, commands
├── terms.md                  # Domain glossary & ubiquitous language
├── invariants.md             # Behavioral contracts & ordering rules
├── .api_surface_cache.json   # AST-extracted symbol snapshot (gitignored)
├── setup_state.json          # Setup progress tracking
├── code_styleguides/         # Language-specific style guides
├── adr/                      # Architecture Decision Records
│   └── NNNN-slug.md
├── tracks.md                 # Registry of all tracks (features/bugs)
├── tracks/                   # Active track directories
│   └── <track_id>/
│       ├── index.md          # Track context links
│       ├── spec.md           # Detailed specification
│       ├── plan.md           # Phased implementation plan
│       └── metadata.json     # Track metadata
└── archive/                  # Completed track directories
```

## 0a. Pre-Execution Context Loading

Before executing ANY Conductor command, load the project context by reading
these files (in order of priority):

1.  `conductor/product.md` — What the product is
2.  `conductor/product-guidelines.md` — How it should look & feel
3.  `conductor/tech-stack.md` — Technical decisions
4.  `conductor/workflow.md` — Task workflow & coding practices
5.  `conductor/terms.md` — Domain glossary & ubiquitous language
6.  `conductor/invariants.md` — Behavioral contracts & ordering rules
7.  `conductor/tracks.md` — Current track registry
8.  `conductor/adr/*.md` — Active architecture decision records
9.  **Per-directory context:** For each source file the current task will touch,
    check the parent directory chain case-insensitively for context files
    (`GEMINI.md`, `CLAUDE.md`, `AGENTS.md`, or `AGENT.md`) containing a `##
    Conductor Context` section. Load the nearest one (innermost directory wins).
10. **Drift scan:** Run a VCS diff stat against the last checkpoint commit.
    Cross-reference changed files against ADR scopes and invariant scopes. Flag
    contradictions before proceeding (see `conductor_cdd_protocols.md` §9).

Platform-specific behavior (VCS commands, path conventions) is injected by
always-on platform rules. Do not hardcode VCS
commands in skill protocols.

## 1. Core Operational Guardrails

-   **Precise Execution:** Do not skip steps. Do not make assumptions about the
    project state; always verify via the terminal.
-   **Tool Validation:** You MUST validate the success of every tool call. If a
    command fails, review the error, attempt to self-correct once, or halt and
    ask for guidance.
-   **Path Integrity:** Always use relative paths starting from the project root
    when referencing conductor files (e.g., `conductor/index.md`).
-   **Project Root Discovery:** You MUST ask the user to explicitly specify the
    project root path before operating on any conductor files. Use the
    user-provided path as `{PROJECT_ROOT}` for all operations.
-   **Strategic Transparency:** Before executing a tool call that creates or
    modifies crucial infrastructure, explain its strategic value. Don't just
    execute; act as a mentor guiding the user through the 'Why'.

## 2. Interaction Standards

-   **Sequential Execution Barriers:** When conducting interactive interviews or
    spec generation loops, ask questions strictly one at a time. Present a
    single question, pause execution, and collect user confirmation before
    generating subsequent questions.
-   **Structured Choices:** When gathering information or asking for decisions,
    provide single-choice or multiple-choice options with context-aware
    suggestions. If a specific option is preferred based on project standards,
    list it first and tag it with a recommended label.
-   **Human-Readable Navigation:** Always refer to process steps and documents
    by their human-readable names. Do not expose internal section numbers.

## 3. Artifact Output Convention

Whenever a Conductor command produces structured output requiring user review -
clarifying questions, reports, summaries, specs, plans, or confirmation prompts:

1.  **Write as a Jetski artifact** using `write_to_file` with `IsArtifact: true`
2.  **Present via `notify_user`** with `PathsToReview` pointing to the file
3.  **Use appropriate ArtifactType**: `walkthrough` for reports/status,
    `implementation_plan` for specs/plans, `other` for questions/prompts
4.  **Set `BlockedOnUser: true`** when the artifact requires approval before
    proceeding

Artifact filenames follow: `conductor_<command>_<context>.md`

## 4. VCS Operations

Conductor skills are VCS-agnostic by default. Platform-specific VCS behavior
(Git, Mercurial) is injected by platform rules. When no platform rule overrides VCS behavior, default
to Git:

-   `git status` to check for changes
-   `git add` / `git commit` for commits
-   `git diff` for diffs
-   `git log` for history

**IMPORTANT:** Before creating any commit, ALWAYS check for actual changes
first. Do NOT create empty commits.

## 5. Conductor Guardrails

-   **Never modify conductor files outside the active track** — only update
    files in `conductor/tracks/<active_track_id>/` and `conductor/tracks.md`
    during implementation. **Exceptions:** `conductor/invariants.md`,
    `conductor/terms.md`, `conductor/.api_surface_cache.json`, and source-tree
    `GEMINI.md` files may be updated at phase checkpoints or when invariant
    capture triggers fire.
-   **Always confirm before overwriting user-approved specs or plans.**
-   **Ask before destructive operations** — do not delete tracks, revert
    commits, or remove artifacts without explicit user confirmation.
-   **Spec and plan approval gates** — always present specs and plans for
    explicit user approval before proceeding.
-   **Document sync is opt-in** — present proposed changes as diffs for user
    approval.

## 6. ADR & Glossary Preflight Interceptor

Full protocol in `conductor_adr_preflight.md` (loaded on demand by skills).
Triggers when any Conductor skill runs against a brownfield project with no
existing ADR files — sweeps docs for undocumented trade-offs and offers to
formalize them before proceeding.

## 7. Project Root Resolution

Before operating on any conductor files, resolve `{PROJECT_ROOT}` using this
tiered heuristic:

1.  **Editor context:** Check the user's open editor files for paths containing
    `/conductor/`. Extract `{PROJECT_ROOT}` as the parent of `conductor/`.
2.  **Workspace root:** Check the current workspace root for a `conductor/`
    subdirectory.
3.  **User prompt:** If the user's prompt mentions a specific path, use it.
4.  **Confidence gate:**
    -   If exactly ONE candidate is found, use it and announce: *"Using
        conductor context at {PROJECT_ROOT}."*
    -   If MULTIPLE candidates are found, present them as options via
        `ask_question` and ask the user to pick.
    -   If NO candidate is found, ask the user: *"I couldn't locate a conductor/
        directory. Please specify the project root path."*

Once resolved, `{PROJECT_ROOT}` persists for the duration of the session. Sub-
skills MUST NOT re-implement this discovery — they reference `{PROJECT_ROOT}`
directly.

## 8. Minimum Viable Project Files

The following files constitute a valid Conductor project. All Conductor commands
(except `/conductor_setup`) MUST verify these exist before proceeding:

-   `{PROJECT_ROOT}/conductor/product.md`
-   `{PROJECT_ROOT}/conductor/tech-stack.md`
-   `{PROJECT_ROOT}/conductor/workflow.md`
-   `{PROJECT_ROOT}/conductor/tracks.md`

Individual skills may require additional files (e.g., `/conductor_review`
requires `product-guidelines.md`), but the base set above is the minimum gate.
If any are missing, halt execution with: *"Conductor context is incomplete.
Please run `/conductor_setup` first."*

`conductor/invariants.md` is optional. Projects function without it; it is
created lazily during track work when the first invariant is captured.

## 9. CDD Protocols (Drift Scan, Invariant Capture, Per-Directory Context)

Full protocols in `conductor_cdd_protocols.md` (loaded on demand by skills).
Covers:

-   **§9 Pre-Execution Drift Scan**: Cross-reference uncommitted changes against
    ADR/invariant scopes; flag contradictions before the skill proceeds.
-   **§10 Invariant Capture Protocol**: File format, capture triggers (5
    lifecycle points), and capture interaction flow for
    `conductor/invariants.md`.
-   **§11 Per-Directory GEMINI.md Context**: Section format, creation triggers,
    loading priorities, and update rules for `## Conductor Context` sections.
