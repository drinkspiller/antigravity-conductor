---
name: conductor_status
description: Get a high-level overview of project progress across all tracks. Use when asked for project status, track progress, what's done, or run /conductor_status.
---

# /conductor_status — View Project Progress

**Purpose:** Get a high-level overview of project progress.

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

**BAD — status summary in the question:**

```
question: "Project has 3 tracks: 1 complete, 1 in progress (Phase 2, Task 3),
1 pending. 15/23 tasks done (65%). What would you like to do next?"
options: ["Implement", "New track", "Review"]
```

**GOOD — status in the artifact, question is just 'what next':**

First, write the full status to the artifact. Then call `ask_question`:

```
question: "What would you like to do next?"
options: [
  "Continue implementing the current task",
  "Start a new track",
  "Review completed work",
  "Show me more details on a specific track"
]
```

## Protocol

1.  **Determine Project Root:** Use `ask_question` to ask the user to specify
    the project root path containing the `conductor/` directory (e.g., the
    repository path), if it is not already known. Use this path as
    `{PROJECT_ROOT}` for all operations in this session.

2.  **Setup Check:** Verify that the following core Conductor files exist:

    -   `{PROJECT_ROOT}/conductor/tracks.md`
    -   `{PROJECT_ROOT}/conductor/product.md`
    -   `{PROJECT_ROOT}/conductor/tech-stack.md`
    -   `{PROJECT_ROOT}/conductor/workflow.md`

    If any of these files are missing, halt execution and inform the user that
    the Conductor context is incomplete.

3.  **Read and Parse Tracks:**

    -   Read `{PROJECT_ROOT}/conductor/tracks.md`.
    -   Parse the tracks. You must support BOTH the new format (`- [ ]
        **Track:`) AND the legacy format (`## [ ] Track:`).
    -   Note the status of each track based on its checkbox:
        -   `[x]` = ✅ Complete
        -   `[~]` = 🔄 In Progress
        -   `[ ]` = ⬜ Pending

4.  **Analyze Task-Level Progress:**

    -   For each track, read its
        `{PROJECT_ROOT}/conductor/tracks/<track_id>/plan.md` to get task-level
        progress.
    -   Extract the current phase and task (marked `[~]`), the next pending task
        (marked `[ ]`), and any explicitly noted blockers.

5.  **Generate the Enhanced Status Summary:** Write the status summary as an
    artifact (`conductor_status.md`, `ArtifactType: walkthrough` using
    `write_to_file` with `IsArtifact: true`) and present via `notify_user` with
    `PathsToReview`.

    Include the following structured information in the artifact:

    **Overview:**

    -   **Current Date/Time:** <current timestamp>
    -   **Project Status:** High-level assessment ("On Track", "Behind
        Schedule", "Blocked") based on tasks and blockers
    -   **Current Phase and Task:** The specific phase/task marked `[~]` in the
        active track
    -   **Next Action Needed:** The next `[ ]` pending task
    -   **Blockers:** Items explicitly marked as blockers
    -   **Phases:** Total phases
    -   **Tasks:** Total tasks
    -   **Progress:** tasks_completed / tasks_total (percentage%)

    **Track Registry Summary:** Display in table format:

    ```markdown
    ## Project Status

    ### Track Registry
    | # | Track | Status |
    |---|-------|--------|
    | 1 | <Track Title> | ✅ Complete |
    | 2 | <Track Title> | 🔄 In Progress |
    | 3 | <Track Title> | ⬜ Pending |
    ```

    **Phase/Task Breakdown:** For each in-progress track, display the plan
    structure:

    ```markdown
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

    **Summary Statistics:** - Total tracks: N - Completed: N - In progress: N -
    Pending: N

6.  **Next Steps:** Use `ask_question` to present the user with structured
    choices for what to do next. Present them as a clear numbered list, for
    example:

    1.  Implement the current task (/conductor_implement)
    2.  Start a new track (/conductor_newTrack)
    3.  Review completed work (/conductor_review)
