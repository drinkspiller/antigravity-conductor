---
name: conductor-new-track
description: Start a new feature or bug fix track with a specification and phased plan. Use when asked to create a new track, start a feature, plan a bug fix, or run /conductor-new-track.
persona: Conductor Planner
---

# /conductor-new-track — Create a New Track

**Purpose:** Start a new feature or bug fix track with a specification and
phased plan.

## Protocol

1.  **Setup Check:** Verify that the following files exist:

    -   `{PROJECT_ROOT}/conductor/product.md`
    -   `{PROJECT_ROOT}/conductor/tech-stack.md`
    -   `{PROJECT_ROOT}/conductor/workflow.md` If ANY of these files are
        missing, halt immediately with the message: "Please run
        `/conductor-setup` first to initialize Conductor for this project."

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

5.  **Interactive Spec & Design Elicitation (Grill Protocol):**

    Conduct a rigorous, one-question-at-a-time interview with the user to build a deep shared understanding before drafting the spec and plan.

    -   **Domain Loading**: Silently load context by reading `{PROJECT_ROOT}/conductor/product.md` (for glossary/product context), `{PROJECT_ROOT}/conductor/tech-stack.md` (for technical constraints), and scanning existing `*/spec.md` files.
    -   **Questioning Strategy**: Interview the user one question at a time across all spec sections (Problem Statement, Functional Requirements, Non-Functional Requirements, Scope Boundaries, Acceptance Criteria).
        -   Use `ask_question` with your recommended answer listed first (`(Recommended)`) alongside 2–4 other plausible options.
        -   If a question can be answered by exploring the codebase, explore the codebase instead of asking.
        -   Follow branches where complexity, ambiguity, or trade-offs emerge.
    -   **Domain Enforcement**: Actively challenge glossary conflicts against `product.md`, sharpen fuzzy language (`go/avoid-we`), and cross-reference stated behavior against the codebase.
    -   **Inline Design Decision & ADR Elicitation**: As architectural trade-offs emerge during questioning:
        -   Evaluate the 3-part gate: (1) Hard to reverse, (2) Surprising without context, (3) Real trade-off.
        -   If all three criteria are met, immediately prompt using `ask_question`: "This decision looks worth recording. Create an ADR?" (`["Yes", "No", "Skip all ADR prompts for this track"]`).
        -   If approved, scan `{PROJECT_ROOT}/conductor/adr/` for the next sequence number (`NNNN`) and write `{PROJECT_ROOT}/conductor/adr/NNNN-slug.md` using `adr_template.md`.
    -   **Inline Glossary Elicitation (`terms.md`)**: If a question or decision introduces/refines a domain term not in `terms.md`, offer to add it inline via `ask_question` (`["Yes, with definition", "Yes, I'll write the definition", "No"]`).
    -   **Inline Invariant Elicitation**: If a decision implies a behavioral constraint (ordering requirement, initialization guard, call-sequence dependency), offer to capture it following the Invariant Capture Protocol in `conductor_cdd_protocols.md` §10.
    -   **Termination**: End the grill session when the user signals done ("done", "let's move on") or when natural convergence is reached and you propose ending via `ask_question`: "I think we've covered the key areas. Ready to draft the spec?" (`["Yes, draft the spec", "Not yet — I want to discuss [topic]"]`).
    -   All resolved decisions must be recorded in the track spec under `## Design Decisions`.

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
    `/conductor-implement` to start working through the plan."
