---
description: Undo work from a track, phase, or task using VCS-aware revert
---

1. Read the Conductor skill instructions at the skill file for Conductor.
2. **Locate the project root:**
   - First, check the current working directory and its parents for a `conductor/` directory.
   - If not found, check the root of the current Git repository (`git rev-parse --show-toplevel`) for a `conductor/` directory.
   - If found, use that path as `{PROJECT_ROOT}` and inform the user: "Found Conductor context at `{PROJECT_ROOT}/conductor/`."
   - If NOT found, ask the user: **"I couldn't find a `conductor/` directory in this workspace. Please specify the project root path where it exists (or should be created)."** Wait for the user's response and use the provided path as `{PROJECT_ROOT}`.
3. **Load Context:** Read `{PROJECT_ROOT}/conductor/tracks.md` to identify the
   active track.
4. Read the active track's `plan.md` to understand current progress, phases,
   and checkpoint SHAs.
5. **Ask the User What to Revert:**
   Present the options: **"What would you like to revert?"**
   - **(A) Entire track** — Revert all commits associated with this track
     back to the start.
   - **(B) Current phase** — Revert to the last phase checkpoint.
   - **(C) Last task** — Revert only the most recent task commit.
     Wait for the user's response.
6. **Detect VCS and Identify Change Range:** Detect the workspace VCS type
   (e.g. git, hg/Mercurial, or jj) and use its history commands with checkpoint SHAs
   from `plan.md` to identify the range of changes to revert:
   - git: `git log --oneline <start_sha>..HEAD`
   - hg: `hg log -r <start_rev>::.`
   - jj: `jj log -r <start_sha>..@`
7. **Preview the Revert:** Write a revert preview as a Jetski artifact (save to
   `{ARTIFACT_DIR}/conductor_revert_preview.md`, `ArtifactType: other`,
   `BlockedOnUser: true`) containing:
   - List of commits that will be undone.
   - List of files that will be affected.
   - "This will revert **N commits** affecting **M files**."
     Present via `notify_user` with `PathsToReview`. **Ask: "Proceed with this
     revert? (yes/no)"**
     **Do not execute the revert without explicit confirmation.**
8. **Execute the Revert:** Use the appropriate VCS command:
   - git: `git revert --no-edit <sha_range>` or `git reset` depending on
     scope.
   - hg: `hg backout -r <rev>` for each commit.
   - jj: `jj restore --from <rev> <files>`
9. **Update Conductor Artifacts:**
   - Update `plan.md`: Reset the reverted tasks from `[x]` back to `[ ]`.
     Remove recorded commit SHAs for reverted tasks.
   - Update `tracks.md`: Adjust the track status if needed (e.g., back to `[
]` if entire track was reverted).
   - Update `metadata.json`: Set status back to `"in_progress"` or `"new"` as
     appropriate.
   - Commit these metadata updates with message: `conductor(revert): Revert
<scope> for track <track_id>`
10. **Confirm Completion:** Display: "✅ Revert complete. The track/phase/task
    has been reset. Run `/conductor_status` to see the current state."
