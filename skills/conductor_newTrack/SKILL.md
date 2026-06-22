---
name: conductor_newTrack
description: Start a new feature or bug fix track with a specification and phased plan. Use when asked to create a new track, start a feature, plan a bug fix, or run /conductor_newTrack.
persona: Conductor Planner
---

# /conductor_newTrack — Create a New Track

**Purpose:** Start a new feature or bug fix track with a specification and
phased plan.

## Protocol

1.  **Setup Check:** Verify that the following files exist:

    -   `{PROJECT_ROOT}/conductor/product.md`
    -   `{PROJECT_ROOT}/conductor/tech-stack.md`
    -   `{PROJECT_ROOT}/conductor/workflow.md` If ANY of these files are
        missing, halt immediately with the message: "Please run
        `/conductor_setup` first to initialize Conductor for this project."

2.  **Get Description & Infer Type:**

    -   If a description was provided in the initial prompt, use it.
    -   If no description was provided, ask: "What feature or bug would you like
        to work on? Describe it in 1-2 sentences."
    -   Analyze the description to infer the track type (Feature vs. Bug/Chore).
        Do NOT ask the user to classify the type.

3.  **Duplicate Track Check & Initialization:**

    -   Before generating a track ID, check the
        `{PROJECT_ROOT}/conductor/tracks/` directory to ensure no existing track
        has a conflicting name.
    -   Generate a unique, short, descriptive `track_id` based on the
        description (e.g., `dark-mode-toggle`).
    -   Create the directory: `{PROJECT_ROOT}/conductor/tracks/<track_id>/`

4.  **Codebase Reconnaissance:**

    -   Read `{PROJECT_ROOT}/conductor/tech-stack.md` and
        `{PROJECT_ROOT}/conductor/product.md` for architectural context.
    -   Read `{PROJECT_ROOT}/conductor/terms.md` (if it exists) to ground term
        usage and prevent symbol/concept drift.
    -   Scan the `{PROJECT_ROOT}/conductor/adr/` directory listing (filenames
        only) to build awareness of existing architectural decisions.
    -   Read ALL existing track specs by scanning
        `{PROJECT_ROOT}/conductor/tracks/` for `*/spec.md` files.
    -   If the user's description references specific code areas, scan those
        files/directories to understand existing patterns, interfaces, and
        constraints.
    -   Use findings to inform the spec questions in the next step — questions
        should reference specific codebase context, not be generic.

5.  **Interactive Spec Generation (Mode Selection):**

    Detect the questioning mode from the user's prompt:

    -   **Grill mode** — if the prompt contains "grill", "grill-me", or "grill
        me" (case-insensitive): Read the `conductor_newTrack_grill` skill
        (`conductor_newTrack_grill/SKILL.md`) and follow its protocol. The grill
        session replaces this step entirely. When the grill session ends,
        proceed to Step 6.
    -   **Discovery mode** — if the prompt contains `[experimental-discovery]`:
        Read the `conductor_newTrack_discovery` skill
        (`conductor_newTrack_discovery/SKILL.md`) and follow its protocol. When
        the discovery session ends, proceed to Step 6.
    -   **Default mode** — if neither keyword is present:
        -   Ask clarifying questions using structured choices.
        -   For Features, ask 3-5 questions (e.g., UI/UX, Edge cases, Scope).
        -   For Bugs/Chores, ask 2-3 questions (e.g., Reproduction, Expected
            behavior).
        -   Batch up to 4 questions in a single interaction when possible.
        -   Present the questions using the `ask_question` tool when multiple
            choices are applicable. Define the `question` string, `options`
            (array of strings), and `is_multi_select` (boolean).
        -   Note that `ask_question` only supports multiple-choice options. If a
            question requires free-text input where predefined choices do not
            make sense, ask it as a standard text message instead of using the
            tool.
        -   Wait for the user's answers.

6.  **Design Decision Elicitation:**

    -   After gathering initial answers, analyze the feature description against
        the codebase scan results.
    -   Identify 2-4 key architectural/design decisions (e.g., "extend existing
        X vs new module", "feature flag vs always-on", "client-side vs
        server-side").
    -   Present each decision using the `ask_question` tool, listing the options
        (you can include pros/cons in the option descriptions).
    -   Wait for the user to make their selections.
    -   **ADR Gating Loop**: For each decision the user resolves:
        -   Evaluate the 3-part gate:
            1.  **Hard to reverse** — the cost of changing this mind later is
                meaningful.
            2.  **Surprising without context** — a future reader would look at
                the code and wonder "why on earth did they do it this way?"
            3.  **Real trade-off** — there were genuine alternatives and you
                picked one for specific reasons.
        -   If all three criteria are met, the decision qualifies for an ADR.
            Present an `ask_question` prompt. Randomly select one of these four
            phrasings for the question:
            *   "This decision looks worth recording. Create an ADR?"
            *   "Hard to reverse, non-obvious, real trade-off — this one
                qualifies for an ADR. Record it?"
            *   "ADR candidate detected. Want to capture the rationale?"
            *   "Worth preserving? An ADR would help future-you understand why."
            *   *Options*: `["Yes", "No", "Skip all ADR prompts for this
                track"]`
        -   If the user selects "Yes":
            -   Scan the `{PROJECT_ROOT}/conductor/adr/` directory for the
                highest existing `NNNN` sequence number and increment it by one
                (default to `0001` if empty).
            -   Generate the ADR file at
                `{PROJECT_ROOT}/conductor/adr/NNNN-slug.md` (e.g.,
                `0001-use-postgres.md`) using the
                `{PROJECT_ROOT}/conductor/templates/adr_template.md` structure.
                Proactively fill the Context, Decision, and any relevant
                Considered Options or Consequences. Write this immediately using
                `write_to_file`.
        -   If the user selects "Skip all ADR prompts for this track", bypass
            the gating check for all remaining decisions in this session.
    -   **Glossary Elicitation**: If a decision introduces or refines a
        project-specific domain term that isn't in `terms.md`, offer to add it.
        Present an `ask_question` prompt. Randomly select one of these three
        phrasings:
        *   "A new domain term emerged: '{term}'. Add it to terms.md?"
        *   "'{term}' isn't in the project glossary yet. Pin it down?"
        *   "New vocab: '{term}'. Worth defining for consistency?"
        *   *Options*: `["Yes, with definition", "Yes, I'll write the
            definition", "No"]`
        *   If approved, update `{PROJECT_ROOT}/conductor/terms.md` following
            the glossary formatting rules.
    -   **Invariant Elicitation**: If a decision implies a behavioral constraint
        (ordering requirement, initialization guard, data-flow rule, call-
        sequence dependency), offer to capture it as an invariant. Follow the
        Invariant Capture Protocol defined in `conductor_cdd_protocols.md` §10.
    -   Record all decisions in the track spec under the "## Design Decisions"
        section. If a decision was recorded as an ADR, include a summary and a
        relative link to the ADR file.

7.  **Draft Specification:**

    -   Generate the draft specification incorporating the user's answers and
        design decisions. The spec MUST contain these sections:
        -   `## Overview`
        -   `## Functional Requirements`
        -   `## Non-Functional Requirements`
        -   `## Design Decisions`
        -   `## Acceptance Criteria`
        -   `## Out of Scope`
        -   `## Opportunities for Consideration` (Optional, included when
            discovery mode identified opportunities during Step 6)
    -   Write this draft to `{PROJECT_ROOT}/conductor/tracks/<track_id>/spec.md`
        using `write_to_file` with `IsArtifact: true` (using `ArtifactType:
        other`).

8.  **Gap Analysis & Suggestions:**

    -   Before presenting the spec for final approval, run a structured gap
        check against these categories: Error handling, Edge cases, Backwards
        compatibility, Security (PII, auth, input validation), Performance
        (scale, bundle size), Accessibility, and Testing strategy.
    -   For each gap found, generate a concrete suggestion.
    -   Present ALL findings as a numbered list in your regular markdown
        response first (where formatting renders properly).
    -   Then, for **each individual gap**, call `ask_question` with a short
        question and options **tailored to that specific finding**. Do NOT
        combine all gaps into a single question. Each question should offer
        meaningful choices relevant to the nature of that gap (e.g., for an
        error handling gap: "Add retry + error toast", "Add error toast only",
        "Skip — handle during implementation", "Discuss further").
    -   After all individual gap questions have been answered, incorporate the
        user's per-gap decisions into the spec.
    -   **Opportunities Selection:** If `## Opportunities for Consideration`
        section is present in the draft spec (from discovery mode):
        -   Present the brainstormed opportunities to the user using the
            `ask_question` tool with `is_multi_select: true`.
        -   For each selected opportunity, move it from `## Opportunities for
            Consideration` to `## Functional Requirements` or `## Non-Functional
            Requirements` as appropriate.

9.  **Cross-Track Awareness:**

    -   Read `{PROJECT_ROOT}/conductor/tracks.md` and review the existing
        `*/spec.md` files.
    -   **ADR Cross-Reference**: Scan `{PROJECT_ROOT}/conductor/adr/` (if it
        exists).
        -   To conserve tokens, perform a **title-scan** (reading filenames
            only) by default.
        -   Identify ADRs whose slugs contain domain terms that match the active
            terms identified in the current track's scope (based on
            `{PROJECT_ROOT}/conductor/terms.md`).
        -   For matching ADRs, load their full text to check for architectural
            constraints or precedents.
    -   Identify: overlapping scope with existing tracks, sequencing
        dependencies, shared component opportunities, or contradictions with
        historical ADRs.
    -   If conflicts/dependencies are found, present findings and **present
        options** using the `ask_question` tool: "Adjust scope", "Acknowledge
        dependency", "No action needed". Update the spec if requested.
    -   If no issues found, announce "No cross-track conflicts detected" and
        proceed.

10. **Devil's Advocate:**

    -   Generate 2-3 challenges to the spec's assumptions based on codebase
        context.
    -   Format as: "What happens if [X]?", "Have you considered [Y]?", "This
        assumes [Z] — is that still valid?"
    -   Present ALL challenges as a numbered list in your regular markdown
        response first (with full context, code references, and reasoning).
    -   Then, for **each individual challenge**, call `ask_question` with the
        challenge as the question and options **tailored to that specific
        concern**. Do NOT combine all challenges into a single question. Each
        question should offer actionable responses relevant to the nature of
        that challenge (e.g., for a race condition concern: "Add initialization
        guard to the spec", "Acceptable risk — document the limitation", "Needs
        investigation before deciding").
    -   After all individual challenge questions have been answered, apply the
        user's per-challenge decisions: update the spec for items the user chose
        to address, and note acknowledged risks for items the user chose to
        accept.
    -   **Invariant Sweep**: For each challenge the user chose to address (e.g.,
        adding an initialization guard, enforcing call ordering), evaluate
        whether the fix establishes a behavioral invariant that extends beyond
        this track. If so, follow the Invariant Capture Protocol defined in
        `conductor_cdd_protocols.md` §10.

11. **Final Spec Confirmation:**

    -   Ensure `{PROJECT_ROOT}/conductor/tracks/<track_id>/spec.md` incorporates
        all accepted suggestions and refinements.
    -   Use `notify_user` with `PathsToReview` pointing to the updated `spec.md`
        to request a final review.
    -   **Present options** using the `ask_question` tool: "Approve" (Proceed to
        planning), "Revise" (Suggest manual edits). Do not proceed until
        approved.

12. **Interactive Plan Generation:**

    -   Read the confirmed spec and `{PROJECT_ROOT}/conductor/workflow.md`.
    -   Generate a hierarchical plan with Phases, Tasks, and Sub-tasks.
    -   Include status markers `[ ]` for EVERY task and sub-task.
    -   **Verification Bridge**: Scan any ADR files created or referenced during
        this track for `## Confirmation` sections. For each verification
        checkbox `[ ]` defined in an ADR's Confirmation section, inject a
        corresponding explicit verification task into the relevant Phase of
        `plan.md` (e.g., `[ ] Verify ADR-0001: <criteria>`).
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

13. **Generate Remaining Track Artifacts:**

    -   Create `{PROJECT_ROOT}/conductor/tracks/<track_id>/metadata.json`
        containing: `track_id`, inferred `type`, `status` (set to `planned`),
        current `createdAt` and `updatedAt` timestamps, and the original
        `description`.
    -   Write `{PROJECT_ROOT}/conductor/tracks/<track_id>/index.md` containing a
        summary and relative links to `spec.md`, `plan.md`, and `metadata.json`.
    -   Append the new track to `{PROJECT_ROOT}/conductor/tracks.md`: `- [ ]
        **Track: <Track Title>** _Link:
        [./tracks/<track_id>/](./tracks/<track_id>/)_`

14. **Commit Changes:**

    -   Commit the new track directory and the updated `tracks.md` using VCS
        commands.
    -   The commit message MUST be: `chore(conductor): Add new track
        '<description>'`

15. **Confirm Completion:** Display: "✅ Track `<track_id>` created! Run
    `/conductor_implement` to start working through the plan."
