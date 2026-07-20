---
name: conductor-implement
description: Execute the plan for the current active track, working through tasks sequentially with TDD lifecycle and phase checkpointing. Use when asked to implement, execute the plan, work on the next task, or run /conductor-implement.
persona: Conductor Implementer
---

# /conductor-implement — Execute the Plan

**Purpose:** Execute the plan for the current active track, working through
tasks sequentially, synchronizing documentation, and managing track cleanup.

## Protocol

### Step 1: Setup Check

1.  Verify the existence of the core context files:
    -   `{PROJECT_ROOT}/conductor/product.md`
    -   `{PROJECT_ROOT}/conductor/tech-stack.md`
    -   `{PROJECT_ROOT}/conductor/workflow.md`
2.  If any of these files are missing, halt execution and inform the user that
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
    -   **Per-Directory Context**: Before modifying files in a directory for the first time in this track, check case-insensitively for existing agent context files: `GEMINI.md`, `CLAUDE.md`, `AGENTS.md`, or `AGENT.md`.
        -   If any of these files exist and contain a `## Conductor Context` section, use that file without prompting.
        -   If exactly one exists without `## Conductor Context`, append the section to that file.
        -   If multiple exist or none exist, and there is concrete architectural justification (multiple interacting services, complex stateful controllers, subtle local invariants, domain gotchas), prompt via `ask_question` asking the user which filename (`GEMINI.md`, `AGENTS.md`, `AGENT.md`, `CLAUDE.md`) they prefer.
        -   If the directory is simple (straightforward UI components, basic utilities, CRUD wrappers), skip prompting entirely.
    -   **Lifecycle Execution**: Defer to the lifecycle defined in `workflow.md`
        (e.g., TDD Red/Green/Refactor).
    -   **Invariant Capture**: When writing a guard, assertion, initialization
        constraint, or call-ordering check, evaluate whether it enforces a
        behavioral contract that extends beyond this track. If so, follow the
        Invariant Capture Protocol in `conductor_cdd_protocols.md` §10.
    -   **Mark Complete**: Once completed, update the task to `[x]` in `plan.md`
        and append the commit SHA.
4.  **Phase Checkpointing**: When the last task in a phase is completed:
    -   Run the automated test suite to ensure stability.
    -   **API Surface Extraction**: Run a VCS diff stat scoped to the current
        phase's commits to identify changed files. For each changed source file,
        extract all public symbols (exported functions, classes, interfaces,
        methods, properties, enum members) — use `ast-grep` (`sg`) if
        available, otherwise `rg` if available, then `grep`. Compare against
        `{PROJECT_ROOT}/conductor/.api_surface_cache.json` (create on first
        run). Present novel symbols via `ask_question` with `is_multi_select:
        true`: "These new exports appeared in Phase N. Add any to the glossary?"
        For each accepted symbol, append a definition to
        `{PROJECT_ROOT}/conductor/terms.md`. Update the cache file.
    -   **Per-Directory Context Update**: For directories touched in this phase, check whether their context file (`GEMINI.md`, `AGENTS.md`, `AGENT.md`, or `CLAUDE.md`) `## Conductor Context` section needs updates (new Key Types, new scoped invariants). Propose updates between the START and END boundary comments.
    -   Write a manual verification plan as a Jetski artifact (use
        `write_to_file` with `IsArtifact: true`, save to
        `{ARTIFACT_DIR}/conductor_implement_phase_N_verification.md`,
        `ArtifactType: walkthrough`). Detail specific, actionable steps (e.g.,
        URLs to visit, `curl` commands, expected visual outcomes).
    -   Present the verification artifact to the user via `notify_user` with
        `PathsToReview`. Use `ask_question` to confirm completion with a
        structured choice: "Phase complete. Does this meet your expectations?"
        [Yes] / [No]. Wait for explicit user confirmation.
    -   Create a checkpoint commit (e.g., `conductor(checkpoint): Checkpoint end
        of Phase X`) using VCS commands.

### Step 4: Document Synchronization

This step triggers **only** when the track reaches `[x]` status (all tasks
complete).

1.  Load the track's `spec.md` along with `{PROJECT_ROOT}/conductor/product.md`,
    `{PROJECT_ROOT}/conductor/tech-stack.md`,
    `{PROJECT_ROOT}/conductor/product-guidelines.md`, and
    `{PROJECT_ROOT}/conductor/terms.md`.
2.  Analyze the `spec.md` and the final implementation code for new features,
    architectural decisions, technical changes, or new domain-specific terms.
3.  **Update `product.md`**: Propose diff-based changes to incorporate new
    features. Use `ask_question` to confirm with a structured choice: "Apply
    updates to product.md?" [Yes] / [No]
4.  **Update `tech-stack.md`**: Propose diff-based changes to reflect any new
    technologies or architectural patterns. Use `ask_question` to confirm with a
    structured choice: "Apply updates to tech-stack.md?" [Yes] / [No]
5.  **Update `product-guidelines.md`**: Propose changes **only** for significant
    strategic shifts (e.g., branding, voice changes). If applicable, include a
    clear warning about the impact. Use `ask_question` to confirm with a
    structured choice: "Apply updates to product-guidelines.md?" [Yes] / [No]
6.  **Update `terms.md`**: Propose diff-based changes to capture any vocabulary
    shifts, refined definitions, or new domain terms that emerged. Use
    `ask_question` with a randomized prompt:
    -   "The glossary drifted. Here's what changed — apply?"
    -   "terms.md needs a refresh after this track. Review the diff?"
    -   *Options*: `["Apply", "Edit first", "Skip"]`
7.  **Update `invariants.md`**: Review invariants captured during the track.
    Propose consolidation (merging duplicates, refining scope annotations,
    adjusting categories). Use `ask_question` with a randomized prompt:
    -   "Invariants evolved during this track. Review the updates?"
    -   "Some invariants need tightening after implementation. Take a look?"
    -   *Options*: `["Apply", "Edit first", "Skip"]`
8.  Commit all approved documentation changes as a separate commit with the
    message: `docs(conductor): Synchronize docs for track '<description>'` using
    VCS commands.

### Step 5: Track Cleanup

This step occurs **only** after the track is fully complete and Document
Synchronization has been handled.

1.  **Retrospective ADR Review**: Before proposing cleanup actions, review the
    completed track's `spec.md` under the "## Design Decisions" section.
    Identify any decisions that were recorded in the spec but were *not* written
    as standalone ADR files.
    -   **Print Candidates First**: Output all candidate decisions as a formatted markdown section in your chat response FIRST, detailing the decision title, trade-off rationale, and relevant spec quotes so the user has full context.
    -   Then present these decisions using the `ask_question` tool with `is_multi_select: true`.
    -   Randomly select one of these three phrasings for the question:
        *   "Some decisions from this track weren't captured as ADRs. Looking
            back, should any of these be recorded?"
        *   "Before archiving: any of these spec decisions deserve a permanent
            record?"
        *   "Retrospective check — did any of these quiet decisions turn out to
            be load-bearing?"
    -   For each decision the user selects from the list:
        -   Scan `{PROJECT_ROOT}/conductor/adr/` for the highest sequence
            number, increment it, and write the new ADR file using the template.
        -   Update the corresponding entry in the track's `spec.md` to include
            the relative link to the new ADR.
        -   Commit these retrospective ADR additions.
2.  Present the user with options for the completed track using `ask_question`
    with a structured choice: "How would you like to handle the completed
    track?" [Review](run `/conductor_review`) / [Archive] / [Delete] / [Skip]
3.  If **Archive** is selected:
    -   Ensure `{PROJECT_ROOT}/conductor/archive/` exists.
    -   Move the track folder into the archive directory.
    -   Remove the track's entry from `{PROJECT_ROOT}/conductor/tracks.md`.
    -   Commit the archive changes using VCS commands.
4.  If **Delete** is selected:
    -   Use `ask_question` to double-confirm with a structured choice: "WARNING:
        Deleting a track is irreversible. Proceed with deletion?" [Yes] / [No]
    -   If confirmed, delete the track folder.
    -   Remove the track's entry from `{PROJECT_ROOT}/conductor/tracks.md`.
    -   Commit the deletion changes using VCS commands.
5.  If **Review** is selected, transition directly into the `/conductor_review`
    workflow.
6.  If **Skip** is selected, leave the track as is.
