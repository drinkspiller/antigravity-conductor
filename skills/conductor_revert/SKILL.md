---
name: conductor_revert
description: Undo work from a track, phase, or task using VCS-aware revert. Use when asked to revert a track, undo changes, roll back work, or run /conductor_revert.
---

# /conductor_revert — Undo Work

**Purpose:** Undo work from a track, phase, or task using VCS-aware revert.

## Protocol

### 1. Setup Check

1.  **Ask for `{PROJECT_ROOT}`:** Ask the user to specify the project root path
    containing the `conductor/` directory (e.g., the repository path). Use
    this path as `{PROJECT_ROOT}` for all operations in this session.
2.  **Verify tracks.md:** Check if `{PROJECT_ROOT}/conductor/tracks.md` exists
    and is not empty. If it is missing or empty, halt execution and inform the
    user that Conductor is not initialized or there are no tracks to revert.

### 2. Interactive Target Selection

Determine what the user wants to revert.

*   **PATH A (Direct):** If the user provided a target argument (e.g., a task
    description or track name), find it in `{PROJECT_ROOT}/conductor/tracks.md`
    or the active `plan.md`. Present a structured choice to the user via
    `ask_question` to confirm:
    *   1. Yes, revert this target.
    *   2. No, select something else.
*   **PATH B (Guided Menu):** If no argument was provided, or if the user chose
    to select something else:
    *   Scan ALL `tracks.md` AND every track's `plan.md`.
    *   Prioritize in-progress items (`[~]`).
    *   Fallback to the 3 most recently completed items (`[x]`).
    *   Present a unified hierarchical menu (max 4 items) as a structured choice
        via `ask_question`.
        *   Example options:
            *   1. "[Task] Update user model" — Description: "Track:
                track_20251208_user_profile"
            *   2. "[Phase] Integration" — Description: "Track:
                track_20251208_user_profile"
            *   3. "[Track] track_20251208_user_profile"
            *   4. Other (let me specify)

Wait for the user to make a selection.

### 3. VCS Reconciliation

Once the target is selected, gather the commits to revert from the VCS history
(git, Mercurial, etc.).

1.  **Find Primary SHAs:** Locate the primary SHA(s) or revisions recorded in
    `plan.md` for the target.
2.  **Handle "Ghost" Commits:** If a recorded SHA is missing (e.g., rewritten
    from rebase or squash), search the VCS log for a similar commit message. If
    found, ask the user to confirm using the new SHA via `ask_question`.
3.  **Find Associated Updates:** Find any associated plan-update commits
    (commits that modified `plan.md` after each implementation commit).
4.  **Find Track Creation Commits:** For TRACK level reverts, also find the
    track creation commit (the first commit adding the track to `tracks.md` and
    creating its files).
5.  **Compile List:** Compile the full list of commits to revert. Check for
    merge commits and cherry-pick duplicates to avoid duplicate revert
    operations.

### 4. Final Execution Plan

Before executing the revert, present a plan to the user using an artifact.

1.  **Preview the Revert:** Write a revert preview as an artifact (using
    `write_to_file` with `IsArtifact: true`, `ArtifactType: other`). Save it to
    a logical artifact path (e.g.,
    `{PROJECT_ROOT}/conductor/artifacts/revert_preview.md`). The artifact should
    contain:
    *   The target being reverted.
    *   The total number of commits.
    *   List of each SHA/revision with its commit message.
    *   The planned action: reverting commits in reverse order.
2.  **Ask for Approval:** Present the artifact to the user and offer the
    following structured options via `ask_question`:

    *   1. Approve
    *   2. Revise

    **Do not execute the revert without explicit confirmation.**

### 5. Execution & Verification

1.  **Execute the Revert:** Use the appropriate VCS command for each commit,
    working from most recent to oldest:
    *   **git:** `git revert --no-edit <sha>`
    *   **hg:** `hg backout -r <rev>`
    *   **Other VCS:** Use the appropriate revert/rollback command.
2.  **Handle Conflicts:** If merge conflicts occur during the revert process,
    halt execution immediately and provide the user with manual resolution
    instructions. Do not attempt to auto-resolve complex revert conflicts.
3.  **Verify Plan State:** After successful revert operations, read
    `{PROJECT_ROOT}/conductor/<track_id>/plan.md` (or the relevant file) to
    ensure the reverted items are correctly reset (e.g., tasks back to `[ ]`,
    SHAs removed).
4.  **Fix Plan State:** If the revert operations did not correctly reset the
    `plan.md` or `tracks.md` state, manually edit the files to reflect the
    reverted state and commit the correction with a message like:
    `conductor(revert): Manually fix plan state for <target>`.
5.  **Confirm Completion:** Inform the user: "✅ Revert complete. The target has
    been reset. Run `/conductor_status` to see the current state."
