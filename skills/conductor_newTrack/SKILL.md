---
name: conductor_newTrack
description: Start a new feature or bug fix track with a specification and phased plan. Use when asked to create a new track, start a feature, plan a bug fix, or run /conductor_newTrack.
---

# /conductor_newTrack — Create a New Track

**Purpose:** Start a new feature or bug fix track with a specification and
phased plan.

**Before executing:** Read the Conductor skill (SKILL.md in the `conductor`
skill folder) for full context on directory structure, conventions, and
lifecycle rules.

## Protocol

1.  **Get Project Root:** Ask the user to specify the project root path
    containing the `conductor/` directory (e.g., the repository path). Use
    this path as `{PROJECT_ROOT}` for all operations in this session.

2.  **Setup Check:** Verify that the following files exist:

    -   `{PROJECT_ROOT}/conductor/product.md`
    -   `{PROJECT_ROOT}/conductor/tech-stack.md`
    -   `{PROJECT_ROOT}/conductor/workflow.md` If ANY of these files are
        missing, halt immediately with the message: "Please run
        `/conductor_setup` first to initialize Conductor for this project."

3.  **Get Description & Infer Type:**

    -   If a description was provided in the initial prompt, use it.
    -   If no description was provided, ask: "What feature or bug would you like
        to work on? Describe it in 1-2 sentences."
    -   Analyze the description to infer the track type (Feature vs. Bug/Chore).
        Do NOT ask the user to classify the type.

4.  **Duplicate Track Check & Initialization:**

    -   Before generating a track ID, check the
        `{PROJECT_ROOT}/conductor/tracks/` directory to ensure no existing track
        has a conflicting name.
    -   Generate a unique, short, descriptive `track_id` based on the
        description (e.g., `dark-mode-toggle`).
    -   Create the directory: `{PROJECT_ROOT}/conductor/tracks/<track_id>/`

5.  **Codebase Reconnaissance:**

    -   Read `{PROJECT_ROOT}/conductor/tech-stack.md` and
        `{PROJECT_ROOT}/conductor/product.md` for architectural context.
    -   Read ALL existing track specs by scanning
        `{PROJECT_ROOT}/conductor/tracks/` for `*/spec.md` files.
    -   If the user's description references specific code areas, scan those
        files/directories to understand existing patterns, interfaces, and
        constraints.
    -   Use findings to inform the spec questions in the next step — questions
        should reference specific codebase context, not be generic.

6.  **Interactive Spec Generation (Initial Questions):**

    -   Announce the spec generation goal to the user based on your research.
    -   Check if the track description or prompt contains the tag
        `[experimental-discovery]`.
    -   If the tag is present, enable **Categorized Discovery** with dynamic
        follow-ups:
        -   Perform relevance triage to identify applicable categories (e.g.,
            Tech choices, UX, Risk/Security, Edge cases, Proactive Opportunities) based on the task
            description and codebase scan.
        -   For each relevant category, ask a baseline of 2-5 questions.
        -   Allow follow-up questions if the user's answers reveal complexity or
            ambiguity. Ask until confident that you understand the requirements
            and design intent.
    -   If the tag is absent, use the default protocol (original fixed-limit):
        -   Ask clarifying questions using structured choices.
        -   For Features, ask 3-5 questions (e.g., UI/UX, Edge cases, Scope).
        -   For Bugs/Chores, ask 2-3 questions (e.g., Reproduction, Expected
            behavior).
    -   Batch up to 4 questions in a single interaction when possible.
    -   Present the questions using the `ask_question` tool when multiple
        choices are applicable. Define the `question` string, `options` (array
        of strings), and `is_multi_select` (boolean).
    -   Note that `ask_question` only supports multiple-choice options. If a
        question requires free-text input where predefined choices do not make
        sense, ask it as a standard text message instead of using the tool.
    -   Wait for the user's answers.

7.  **Design Decision Elicitation:**

    -   After gathering initial answers, analyze the feature description against
        the codebase scan results.
    -   Identify 2-4 key architectural/design decisions (e.g., "extend existing
        X vs new module", "feature flag vs always-on", "client-side vs
        server-side").
    -   Present each decision using the `ask_question` tool, listing the options
        (you can include pros/cons in the option descriptions).
    -   Wait for the user to make their selections. These will be recorded in
        the spec under a "## Design Decisions" section.

8.  **Draft Specification:**

    -   Generate the draft specification incorporating the user's answers and
        design decisions. The spec MUST contain these sections:
        -   `## Overview`
        -   `## Functional Requirements`
        -   `## Non-Functional Requirements`
        -   `## Design Decisions`
        -   `## Acceptance Criteria`
        -   `## Out of Scope`
        -   `## Opportunities for Consideration` (Optional, if `[experimental-discovery]` is enabled and opportunities were identified)
    -   Write this draft to `{PROJECT_ROOT}/conductor/tracks/<track_id>/spec.md`
        using `write_to_file` with `IsArtifact: true` (using `ArtifactType:
        other`).

9.  **Gap Analysis & Suggestions:**

    -   Before presenting the spec for final approval, run a structured gap
        check against these categories: Error handling, Edge cases, Backwards
        compatibility, Security (PII, auth, input validation), Performance
        (scale, bundle size), Accessibility, and Testing strategy.
    -   For each gap found, generate a concrete suggestion.
    -   Present findings: "I identified the following gaps in the draft spec.
        Here are my suggestions: [list]"
    -   **Present options** using the `ask_question` tool: "Incorporate
        suggestions into spec", "Acknowledge and proceed", "Discuss further".
        Update the spec if requested.
    -   **Opportunities Selection (Experimental):** If `[experimental-discovery]`
        is enabled and `## Opportunities for Consideration` section is present in
        the draft spec:
        -   Present the brainstormed opportunities to the user using the
            `ask_question` tool with `is_multi_select: true`.
        -   For each selected opportunity, move it from `## Opportunities for
            Consideration` to `## Functional Requirements` or `## Non-Functional
            Requirements` as appropriate.

10. **Cross-Track Awareness:**

    -   Read `{PROJECT_ROOT}/conductor/tracks.md` and review the existing
        `*/spec.md` files.
    -   Identify: overlapping scope with existing tracks, sequencing
        dependencies, or shared component opportunities.
    -   If conflicts/dependencies are found, present findings and **present
        options** using the `ask_question` tool: "Adjust scope", "Acknowledge
        dependency", "No action needed". Update the spec if requested.
    -   If no issues found, announce "No cross-track conflicts detected" and
        proceed.

11. **Devil's Advocate:**

    -   Generate 2-3 challenges to the spec's assumptions based on codebase
        context.
    -   Format as: "What happens if [X]?", "Have you considered [Y]?", "This
        assumes [Z] — is that still valid?"
    -   **Present options** using the `ask_question` tool: "Address these
        concerns", "Acknowledged, proceed anyway", "Revise spec".

12. **Final Spec Confirmation:**

    -   Ensure `{PROJECT_ROOT}/conductor/tracks/<track_id>/spec.md` incorporates
        all accepted suggestions and refinements.
    -   Use `notify_user` with `PathsToReview` pointing to the updated `spec.md`
        to request a final review.
    -   **Present options** using the `ask_question` tool: "Approve" (Proceed to
        planning), "Revise" (Suggest manual edits). Do not proceed until
        approved.

13. **Interactive Plan Generation:**

    -   Read the confirmed spec and `{PROJECT_ROOT}/conductor/workflow.md`.
    -   Generate a hierarchical plan with Phases, Tasks, and Sub-tasks.
    -   Include status markers `[ ]` for EVERY task and sub-task.
    -   **CRITICAL:** If `workflow.md` defines phase checkpointing, you must
        inject Phase Completion meta-tasks at the end of each Phase.
    -   Write this to `{PROJECT_ROOT}/conductor/tracks/<track_id>/plan.md` using
        `write_to_file` with `IsArtifact: true` (using `ArtifactType:
        implementation_plan`).
    -   Use `notify_user` with `PathsToReview` pointing to the written `plan.md`
        to request review.
    -   **Present options** using the `ask_question` tool: "Approve" (Proceed to
        track creation), "Revise" (Suggest changes). Do not proceed until
        approved.

14. **Generate Remaining Track Artifacts:**

    -   Create `{PROJECT_ROOT}/conductor/tracks/<track_id>/metadata.json`
        containing: `track_id`, inferred `type`, `status` (set to `planned`),
        current `createdAt` and `updatedAt` timestamps, and the original
        `description`.
    -   Write `{PROJECT_ROOT}/conductor/tracks/<track_id>/index.md` containing a
        summary and relative links to `spec.md`, `plan.md`, and `metadata.json`.
    -   Append the new track to `{PROJECT_ROOT}/conductor/tracks.md`: `- [ ]
        **Track: <Track Title>** _Link:
        [./tracks/<track_id>/](./tracks/<track_id>/)_`

15. **Commit Changes:**

    -   Use the appropriate VCS tool (e.g., `git`, `hg`, etc.) to add
        and commit the new track directory and the updated `tracks.md`.
    -   The commit message MUST be: `chore(conductor): Add new track
        '<description>'`

16. **Confirm Completion:** Display: "✅ Track `<track_id>` created! Run
    `/conductor_implement` to start working through the plan."
