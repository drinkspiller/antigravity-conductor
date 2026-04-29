---
name: conductor_setup
description: Initialize or update a project's Conductor context. Use when asked to set up conductor, initialize project context, create conductor directory, or run /conductor_setup.
---

# /conductor_setup — Initialize Project Context

**Purpose:** Initialize or update the project's Conductor context (run once per
project).

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

**BAD — scan results dumped into the question:**

```
question: "A brownfield project detected. Found package.json with React 18,
TypeScript 5.3, 47 source files in src/, 12 test files, BUILD files present.
May I perform a read-only scan of the codebase to extract the tech stack?"
options: ["Yes", "No"]
```

**GOOD — scan summary as text, question is short with nuanced options:**

First, output findings as regular markdown:

> **Brownfield project detected.** I found `package.json` with React 18,
> TypeScript 5.3, 47 source files in `src/`, and BUILD files present.

Then call `ask_question`:

```
question: "May I perform a read-only codebase scan?"
options: [
  "Yes, scan everything",
  "Yes, but skip test files",
  "No, I'll describe the stack manually",
  "Show me what directories you'd scan first"
]
```

**More good examples:**

```
question: "How should I draft product.md?"
options: [
  "Interactive — walk me through questions",
  "Autogenerate from project context",
  "Start from a template I'll customize"
]
```

```
question: "Here's the draft. What do you think?"
options: [
  "Approve — looks good",
  "Suggest changes — I'll describe them",
  "Start over with a different approach"
]
```

## Protocol

1.  **Get Project Root:** Ask the user to specify the project root path where
    the `conductor/` directory should be created or already exists. Use this
    path as `{PROJECT_ROOT}` for all operations.

2.  **Project Audit (§1.2):**

    -   Check if `{PROJECT_ROOT}/conductor/` exists.
    -   If it exists, read `{PROJECT_ROOT}/conductor/setup_state.json` to
        determine which artifacts are already configured. Map existing artifacts
        to their target sections, skip completed ones, and resume from the next
        incomplete artifact.
    -   If it does not exist, create the directory and a
        `{PROJECT_ROOT}/conductor/setup_state.json` file to track setup
        progress.

3.  **Brownfield / Greenfield Detection (§2.0):**

    -   Detect project maturity by checking for existing dependency manifests
        (e.g., `package.json`, `pom.xml`, `requirements.txt`, `go.mod`,
        `Cargo.toml`) and build files (e.g., `BUILD`, `CMakeLists.txt`).
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

4.  **Artifact Generation Protocol:** For each missing artifact, follow the
    steps below. Generate one artifact at a time.

    -   Present structured choices to the user using `ask_question` or write
        clarifying questions as an artifact (`write_to_file` with
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

### Finalization (§2.7)

1.  **Commit Setup Files**: Commit all generated `conductor/` files to the
    project's Version Control System (VCS). Detect and adapt to the available
    VCS (git, Mercurial, etc.). Create a commit or changelist with a clear
    message like `chore: initialize conductor context`.
2.  **Summarize Actions**: Display a summary of all actions taken and list all
    created files.
3.  **Closing**: Present the final message: "✅ Conductor setup complete! Run
    `/conductor_newTrack` to start your first feature or bug fix track."
