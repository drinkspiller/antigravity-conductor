---
name: conductor-setup
description: Initialize or update a project's Conductor context. Use when asked to set up conductor, initialize project context, create conductor directory, or run /conductor-setup.
persona: Conductor Architect
---

# /conductor-setup — Initialize Project Context

**Purpose:** Initialize or update the project's Conductor context (run once per
project).

## Protocol

1.  **Project Audit (§1.2):**

    -   Check if `{PROJECT_ROOT}/conductor/` exists.
    -   If it exists, read `{PROJECT_ROOT}/conductor/setup_state.json` to
        determine which artifacts are already configured. Map existing artifacts
        to their target sections, skip completed ones, and resume from the next
        incomplete artifact.
    -   If it does not exist, create the directory and a
        `{PROJECT_ROOT}/conductor/setup_state.json` file to track setup
        progress.

2.  **Brownfield / Greenfield Detection (§2.0):**

    -   Detect project maturity by checking for existing dependency manifests
        (e.g., `package.json`, `pom.xml`, `requirements.txt`, `go.mod`,
        `Cargo.toml`) and Bazel `BUILD` files.
    -   Check for common source code directories (e.g., `src/`, `app/`, `lib/`,
        `bin/`).
    -   If indicators are found, this is a **Brownfield** project. Before
        scanning, use `ask_question` to gate access: "A brownfield project
        detected. May I perform a read-only scan?"
        -   Upon approval, perform a read-only scan to extract the tech stack
            from manifests and infer the architecture from the file tree.
        -   Respect `.geminiignore` and `.gitignore` when scanning.
        -   Handle large files (>1MB) carefully: only read the head and tail 20
            lines.
    -   If no indicators are found, this is a **Greenfield** project.

3.  **Artifact Generation Protocol:** For each missing artifact, follow the
    steps below. Generate one artifact at a time.

    -   Present structured choices to the user using `ask_question` or write
        clarifying questions as a Jetski artifact (`write_to_file` with
        `IsArtifact: true` and `ArtifactType: other`).
    -   **Draft Review Loop**: After drafting an artifact, present it for review
        using `ask_question` with options: "Approve" or "Suggest changes". Loop
        until approved.
    -   Present each generated conductor file using `notify_user` with
        `PathsToReview` pointing to the file.
    -   Update `{PROJECT_ROOT}/conductor/setup_state.json` after each approval.

--------------------------------------------------------------------------------

### Artifact 1: `product.md`

Use `ask_question` to present structured options: "Interactive" or
"Autogenerate" for drafting `{PROJECT_ROOT}/conductor/product.md`. -
**Interactive**: Guide the user through questions about the project name, target
users, core value proposition, key features, and competitive landscape. -
**Autogenerate**: Draft the document based on a brief project goal provided by
the user.

Draft the document, enter the Draft Review Loop ("Approve" or "Suggest
changes"), and upon approval, write it to `{PROJECT_ROOT}/conductor/product.md`
and update `setup_state.json`.

--------------------------------------------------------------------------------

### Artifact 2: `product-guidelines.md`

Use `ask_question` to present structured options: "Interactive" or
"Autogenerate" for drafting `{PROJECT_ROOT}/conductor/product-guidelines.md`. -
**Interactive**: Guide the user through questions about product tone, brand
colors/fonts/visual identity, UX patterns (e.g., modals vs inline editing), and
accessibility requirements (e.g., WCAG AA). - **Autogenerate**: Draft the
document based on project goals or brownfield codebase insights.

Draft the document, enter the Draft Review Loop ("Approve" or "Suggest
changes"), and upon approval, write the file and update `setup_state.json`.

--------------------------------------------------------------------------------

### Artifact 3: `tech-stack.md`

For drafting `{PROJECT_ROOT}/conductor/tech-stack.md`: - **For Greenfield**: Use
`ask_question` to present structured options: "Interactive" or "Autogenerate".
If Interactive, ask about programming languages, frameworks, databases, and
CI/CD tools. - **For Brownfield**: State the inferred tech stack from the
read-only scan and confirm it with the user via `ask_question`.

Draft the document, enter the Draft Review Loop ("Approve" or "Suggest
changes"), and upon approval, write the file and update `setup_state.json`.

--------------------------------------------------------------------------------

### Artifact 4: `code_styleguides/`

Based on the tech stack identified, recommend a set of style guides for each
language. - Use `ask_question` to present structured options: "Select from
library" or "Auto-generate based on project patterns" (if brownfield). -
Generate a concise style guide (naming conventions, file organization, import
ordering, formatting rules) for each language. - Write them to
`{PROJECT_ROOT}/conductor/code_styleguides/` (e.g., `python.md`,
`javascript.md`). - Enter the Draft Review Loop ("Approve" or "Suggest changes")
for each. Upon approval, update `setup_state.json`.

--------------------------------------------------------------------------------

### Artifact 5: `workflow.md`

Use `ask_question` to present structured options: "Default" or "Customize" for
drafting `{PROJECT_ROOT}/conductor/workflow.md`. - **Default**: Use standard
Test-Driven Development (TDD) conventions, default commit frequency, and generic
coverage targets. - **Customize**: Ask the user about their preferred code
coverage target, commit frequency, summary storage, commit message format (e.g.,
Conventional Commits), specific build/test commands, and whether they want phase
checkpointing.

Draft the document, enter the Draft Review Loop ("Approve" or "Suggest
changes"), and upon approval, write the file and update `setup_state.json`.

--------------------------------------------------------------------------------

### Artifact 6: Skills Selection (§2.6)

Check for an existing skills catalog or directories containing agent skills. -
Recommend specific skills based on the tech stack (e.g., testing skills,
formatting skills). - Use `ask_question` to present structured options: "Install
recommended", "Hand-pick skills", or "Skip". - If skills are installed or
configured, present a confirmation step instructing the user to reload their
window or environment if necessary. - Update `setup_state.json`.

--------------------------------------------------------------------------------

### Artifact 7: `tracks.md` and `index.md`

Generate: - `{PROJECT_ROOT}/conductor/tracks.md` — An empty track registry with
a standard heading and format example. - `{PROJECT_ROOT}/conductor/index.md` — A
central index linking to all newly created context files.

Enter the Draft Review Loop ("Approve" or "Suggest changes") for both. Upon
approval, write the files and update `setup_state.json`.

--------------------------------------------------------------------------------

### Artifact 8: `terms.md`

Use `ask_question` to present structured options: "Interactive", "Autogenerate",
or "Skip for now".

-   **Interactive**: Guide the user through 2 key questions: "What are the core
    domain concepts in this project?" and "Are there any terms your team uses
    differently from industry convention or standard coding vocabulary?"
-   **Autogenerate (Brownfield only)**: Perform a read-only scan of the codebase
    to identify domain-specific nouns (e.g., class names, proto message types,
    API resource names). Propose a draft glossary with definitions inferred from
    context.
-   **Skip for now**: Proceed without creating a glossary. The file can be
    created lazily during track planning if needed.

Draft the document following the `terms.md` format rules (opinionated
vocabulary, tight 1-2 sentence definitions, `_Avoid_` lists for synonyms). Enter
the Draft Review Loop ("Approve" or "Suggest changes"). Upon approval, write it
to `{PROJECT_ROOT}/conductor/terms.md` and update `setup_state.json`.

--------------------------------------------------------------------------------

### Artifact 9: `invariants.md`

Use `ask_question` to present structured options: "Interactive", "Autogenerate",
or "Skip for now".

-   **Interactive**: Guide the user through 2 key questions: "Are there ordering
    constraints or call-sequence rules your team follows?" and "Are there 'never
    do X' patterns that aren't written down but everyone knows?"
-   **Autogenerate (Brownfield only)**: Perform a read-only scan of the codebase
    for guard patterns (`if (!x) throw`, assertions, initialization checks,
    comments containing "must", "always", "never", "before", "after"). Propose
    candidate invariants with categories inferred from context.
-   **Skip for now**: Proceed without creating invariants. The file is created
    lazily during track work when the first invariant is captured (see
    `conductor_cdd_protocols.md` §10).

Draft the document following the invariant format rules (category headers,
`{CAT}-{NNN}` IDs, source attribution, scope annotations). Enter the Draft
Review Loop ("Approve" or "Suggest changes"). Upon approval, write it to
`{PROJECT_ROOT}/conductor/invariants.md` and update `setup_state.json`.

--------------------------------------------------------------------------------

### Artifact 10: Per-Directory Context Enrichment (Brownfield Only)

This step is offered for brownfield project directories with concrete architectural justification (e.g., multiple interacting services, complex stateful controllers, subtle local invariants, or domain gotchas). Simple directories (straightforward UI components, basic utilities, CRUD wrappers) are skipped.

1.  Scan the project source tree for complex directories with architectural justification.
2.  For each candidate directory, check case-insensitively for existing agent context files: `GEMINI.md`, `CLAUDE.md`, `AGENTS.md`, or `AGENT.md`.
    -   If any of these files exist and contain a `## Conductor Context` section, use that file and do NOT prompt.
    -   If exactly one exists without `## Conductor Context`, append the section to that file.
    -   If multiple exist or none exist, present an `ask_question` prompt asking the user which filename (`GEMINI.md`, `AGENTS.md`, `AGENT.md`, `CLAUDE.md`) they prefer for that directory.
3.  Present candidate directories using `ask_question` with `is_multi_select: true`: "These directories have complex architecture or local invariants. Enrich their context files?"
4.  For each selected directory:
    -   Create or update the chosen context file with the `## Conductor Context` section.
    -   Populate the section with: Purpose (inferred from file contents and directory name), Invariants (scoped from `invariants.md` if it exists), Key Types (extracted via AST scan), and Term Overrides (if the directory uses terms differently from `terms.md`).
    -   Wrap the section in boundary comments:
        `<!-- Conductor Context: START (manual edits go above this line) -->`
        and `<!-- Conductor Context: END (manual edits go below this line) -->`.
5.  Enter the Draft Review Loop ("Approve" or "Suggest changes") for each
    generated section. Upon approval, update `setup_state.json`.

--------------------------------------------------------------------------------

### Finalization (§2.7)

1.  **Commit Setup Files**: Commit all generated `conductor/` files using VCS
    commands with a clear message like `chore: initialize conductor context`.
2.  **Summarize Actions**: Display a summary of all actions taken and list all
    created files.
3.  **Closing**: Present the final message: "✅ Conductor setup complete! Run
    `/conductor_newTrack` to start your first feature or bug fix track." x
    track."
