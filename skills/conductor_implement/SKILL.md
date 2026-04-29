---
name: conductor_implement
description: Execute the plan for the current active track, working through tasks sequentially with TDD lifecycle and phase checkpointing. Use when asked to implement, execute the plan, work on the next task, or run /conductor_implement.
---

# /conductor_implement — Execute the Plan

**Purpose:** Execute the plan for the current active track, working through
tasks sequentially, synchronizing documentation, and managing track cleanup.

**Before executing:** Read the Conductor skill (SKILL.md in the `conductor`
skill folder) for full context on directory structure, conventions, and
lifecycle rules.

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

**BAD — wall of analysis crammed into the question field:**

```
question: "Task 1.1 Critical Examination: I've analyzed the codebase against
the spec. Key findings: 1. **onDrop callback** currently only receives blockId
— we get the full Block from projectBlocks in PrintablePanel, so blockName
is available. 2. **removeBackgroundForDrop** is a plain async function...
Shall I proceed with TDD?"
options: ["Yes", "No"]
```

**GOOD — analysis as normal text, question is short and has nuanced options:**

First, output your analysis as regular markdown text:

> **Task 1.1 Critical Examination:** I've analyzed the codebase against the
> spec. Key findings: 1. `onDrop` callback currently only receives `blockId` —
> we get the full `Block` from `projectBlocks` in `PrintablePanel`, so
> `blockName` is available from `block.name`. 2. `removeBackgroundForDrop` is a
> plain async function (not a hook)...

Then call `ask_question` separately:

```
question: "How should I proceed on Task 1.1?"
options: [
  "Proceed — the patterns are clear",
  "I have concerns — let me clarify first",
  "Skip this task for now",
  "Show me the relevant code before deciding"
]
```

**More good examples:**

```
question: "I found 3 gaps in the draft spec. How should I handle them?"
options: [
  "Incorporate all suggestions into the spec",
  "Let me review each suggestion individually",
  "Acknowledge gaps and proceed anyway",
  "Discuss the gaps further before deciding"
]
```

```
question: "Phase 2 is complete. Does this meet your expectations?"
options: [
  "Looks good — continue to Phase 3",
  "Mostly good, but I want to tweak something first",
  "Not quite — let's revisit before moving on",
  "Show me the verification steps again"
]
```

```
question: "How would you like to handle the completed track?"
options: [
  "Run /conductor_review first",
  "Archive the track",
  "Delete the track",
  "Leave it as-is for now"
]
```

## Protocol

### Step 1: Setup Check

1.  **Ask the user** to specify the project root path containing the
    `conductor/` directory (e.g., the repository path). Use this path as
    `{PROJECT_ROOT}` for all operations in this session.
2.  Verify the existence of the core context files:
    -   `{PROJECT_ROOT}/conductor/product.md`
    -   `{PROJECT_ROOT}/conductor/tech-stack.md`
    -   `{PROJECT_ROOT}/conductor/workflow.md`
3.  If any of these files are missing, halt execution and inform the user that
    Conductor is not initialized properly.

### Step 2: Track Selection

1.  Check if the user provided a specific track name in their prompt.
2.  Read `{PROJECT_ROOT}/conductor/tracks.md`. Parse the file by splitting on
    the `---` separator to extract the list of tracks and their status markers
    (`[ ]`, `[~]`, `[x]`).
3.  If a track name was provided:
    -   Find the exact (case-insensitive) match in `tracks.md`.
    -   Use `ask_question` to confirm the selection with a structured choice:
        "Proceed with track '{Track Name}'?" [Yes] / [No]
4.  If no track name was provided:
    -   Find the first non-completed track (marked `[ ]` or `[~]`).
    -   Use `ask_question` to confirm the selection with a structured choice:
        "Proceed with track '{Track Name}'?" [Yes] / [No]
5.  If no incomplete tracks exist, announce that all tracks are complete and
    halt.

### Step 3: Track Implementation

1.  Before starting tasks, update the selected track's status to `[~]` in
    `{PROJECT_ROOT}/conductor/tracks.md`.
2.  Load the track context by reading:
    -   `{PROJECT_ROOT}/conductor/tracks/{Track Name}/spec.md`
    -   `{PROJECT_ROOT}/conductor/tracks/{Track Name}/plan.md`
    -   `{PROJECT_ROOT}/conductor/workflow.md`
3.  Execute tasks sequentially as defined in `plan.md`. For each uncompleted
    task (`[ ]`):
    -   **Lifecycle Execution**: Defer to the lifecycle defined in `workflow.md`
        (e.g., TDD Red/Green/Refactor).
    -   **Mark Complete**: Once completed, update the task to `[x]` in `plan.md`
        and append the commit SHA.
4.  **Phase Checkpointing**: When the last task in a phase is completed:
    -   Run the automated test suite to ensure stability.
    -   Write a manual verification plan as an artifact (use
        `write_to_file` with `IsArtifact: true`, save to
        `{ARTIFACT_DIR}/conductor_implement_phase_N_verification.md`,
        `ArtifactType: walkthrough`). Detail specific, actionable steps (e.g.,
        URLs to visit, `curl` commands, expected visual outcomes).
    -   Present the verification artifact to the user via `notify_user` with
        `PathsToReview`. Use `ask_question` to confirm completion with a
        structured choice: "Phase complete. Does this meet your expectations?"
        [Yes] / [No]. Wait for explicit user confirmation.
    -   Create a checkpoint commit (e.g., `conductor(checkpoint): Checkpoint end
        of Phase X`) using the appropriate VCS commands (git, Mercurial, etc.).

### Step 4: Document Synchronization

This step triggers **only** when the track reaches `[x]` status (all tasks
complete). 1. Load the track's `spec.md` along with
`{PROJECT_ROOT}/conductor/product.md`, `{PROJECT_ROOT}/conductor/tech-stack.md`,
and `{PROJECT_ROOT}/conductor/product-guidelines.md`. 2. Analyze the `spec.md`
for new features, architectural decisions, or tech changes. 3. **Update
`product.md`**: Propose diff-based changes to incorporate new features. Use
`ask_question` to confirm with a structured choice: "Apply updates to
product.md?" [Yes] / [No] 4. **Update `tech-stack.md`**: Propose diff-based
changes to reflect any new technologies or architectural patterns. Use
`ask_question` to confirm with a structured choice: "Apply updates to
tech-stack.md?" [Yes] / [No] 5. **Update `product-guidelines.md`**: Propose
changes **only** for significant strategic shifts (e.g., branding, voice
changes). If applicable, include a clear warning about the impact. Use
`ask_question` to confirm with a structured choice: "Apply updates to
product-guidelines.md?" [Yes] / [No] 6. Commit all approved documentation
changes as a separate commit with the message: `docs(conductor): Synchronize
docs for track '<description>'` using the appropriate VCS tool.

### Step 5: Track Cleanup

This step occurs **only** after the track is fully complete and Document
Synchronization has been handled. 1. Present the user with options for the
completed track using `ask_question` with a structured choice: "How would you
like to handle the completed track?" [Review](run `/conductor_review`) /
[Archive] / [Delete] / [Skip] 2. If **Archive** is selected: - Ensure
`{PROJECT_ROOT}/conductor/archive/` exists. - Move the track folder into the
archive directory. - Remove the track's entry from
`{PROJECT_ROOT}/conductor/tracks.md`. - Commit the archive changes using the
appropriate VCS tool. 3. If **Delete** is selected: - Use `ask_question`
to double-confirm with a structured choice: "WARNING: Deleting a track is
irreversible. Proceed with deletion?" [Yes] / [No] - If confirmed, delete the
track folder. - Remove the track's entry from
`{PROJECT_ROOT}/conductor/tracks.md`. - Commit the deletion changes using the
appropriate VCS tool. 4. If **Review** is selected, transition directly
into the `/conductor_review` workflow. 5. If **Skip** is selected, leave the
track as is.
