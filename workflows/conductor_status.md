---
description: Get a high-level overview of project progress across all tracks
---

1. Read the Conductor skill instructions at the skill file for Conductor.
2. **Locate the project root:**
   - First, check the current working directory and its parents for a `conductor/` directory.
   - If not found, check the root of the current Git repository (`git rev-parse --show-toplevel`) for a `conductor/` directory.
   - If found, use that path as `{PROJECT_ROOT}` and inform the user: "Found Conductor context at `{PROJECT_ROOT}/conductor/`."
   - If NOT found, ask the user: **"I couldn't find a `conductor/` directory in this workspace. Please specify the project root path where it exists (or should be created)."** Wait for the user's response and use the provided path as `{PROJECT_ROOT}`.

3. **Load Context:** Read `{PROJECT_ROOT}/conductor/tracks.md`.

4. **Generate the Track Registry Summary:**

   For each track entry in `tracks.md`, determine its status:
   - `[x]` = ✅ Complete
   - `[~]` = 🔄 In Progress
   - `[ ]` = ⬜ Pending

   Display in table format:

   ```
   ## Project Status

   ### Track Registry
   | # | Track | Status |
   |---|-------|--------|
   | 1 | <Track Title> | ✅ Complete |
   | 2 | <Track Title> | 🔄 In Progress |
   | 3 | <Track Title> | ⬜ Pending |
   ```

4. **For Each In-Progress Track, Show Phase/Task Breakdown:**

   Read the track's `plan.md` and display:

   ```
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

5. **Display Summary Statistics:**
   - Total tracks: N
   - Completed: N
   - In progress: N
   - Pending: N
