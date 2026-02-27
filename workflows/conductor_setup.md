---
description: Initialize or update the project's Conductor context (run once per project)
---

1. Read the Conductor skill instructions at the skill file for Conductor.
2. **Locate the project root:**
   - First, check the current working directory and its parents for a `conductor/` directory.
   - If not found, check the root of the current Git repository (`git rev-parse --show-toplevel`) for a `conductor/` directory.
   - If found, use that path as `{PROJECT_ROOT}` and inform the user: "Found existing Conductor context at `{PROJECT_ROOT}/conductor/`."
   - If NOT found, ask the user: **"Where should I create the `conductor/` directory? Please specify the project root path (e.g., the root of your repository)."** Wait for the user's response and use the provided path as `{PROJECT_ROOT}`.
3. Check if `{PROJECT_ROOT}/conductor/` exists.
   - If it exists, read `conductor/setup_state.json` to determine which artifacts are already configured. Skip completed artifacts and resume from the next incomplete one.
   - If it does not exist, create the directory and start from the beginning.

4. **For each missing artifact, follow the interactive protocol below.** Generate one artifact at a time. **Do not generate two artifacts without a user interaction in between.**

---

### Artifact 1: `product.md`

Ask the user the following questions and wait for their response before generating:

- "What is the **name** of your project?"
- "Who are the **target users**? (e.g., developers, end users, internal team)"
- "What is the **core value proposition** — what problem does it solve?"
- "What are the **3-5 key features** you want to build or already have?"
- "Is there any **competitive landscape or prior art** worth noting?"

After receiving answers, generate `conductor/product.md` with an Overview, Target Users, Core Features, and Goals section. Present it to the user and ask: **"Does this accurately capture your product? Reply yes to continue, or provide corrections."**

Update `setup_state.json` to mark `product` as complete.

---

### Artifact 2: `product-guidelines.md`

Ask the user:

- "What **tone** should the product have? (e.g., professional, casual, playful, technical)"
- "Are there **brand colors, fonts, or visual identity** guidelines to follow?"
- "What **UX patterns** do you prefer? (e.g., modals vs inline editing, toasts vs banners, dark mode support)"
- "Any **accessibility requirements**? (e.g., WCAG AA, screen reader support)"

After receiving answers, generate `conductor/product-guidelines.md`. Present it and ask for confirmation.

Update `setup_state.json` to mark `product-guidelines` as complete.

---

### Artifact 3: `tech-stack.md`

Ask the user:

- "What **programming languages** does the project use?"
- "What **frameworks and libraries** are central? (e.g., React, Angular, Express, Flask)"
- "What **database** and **hosting/infrastructure** are in use? (e.g., PostgreSQL, Firebase, GCP, AWS)"
- "What **build tools and CI/CD** pipeline is used? (e.g., Webpack, Vite, Bazel, GitHub Actions)"
- "Any **key architectural patterns**? (e.g., monorepo, microservices, event-driven)"

After receiving answers, generate `conductor/tech-stack.md`. Present it and ask for confirmation.

Update `setup_state.json` to mark `tech-stack` as complete.

---

### Artifact 4: `workflow.md`

Copy the workflow template from `skills/conductor/templates/workflow_template.md` into `conductor/workflow.md`.

Then ask the user to customize it:

- "Do you follow **Test-Driven Development (TDD)**? (yes/no)"
- "What **commit message format** do you use? (e.g., Conventional Commits, free-form)"
- "What **code coverage target** do you aim for? (e.g., 80%, or none)"
- "Any **specific commands** for building, testing, or linting? (e.g., `blaze test`, `npm test`, `pnpm lint`)"
- "Do you want **phase checkpointing** with git notes? (yes/no)"

After receiving answers, customize the template accordingly. Present the final `workflow.md` and ask for confirmation.

Update `setup_state.json` to mark `workflow` as complete.

---

### Artifact 5: `code_styleguides/`

Based on the languages identified in `tech-stack.md`, generate a style guide for each language. For each language:

- Search the existing codebase for patterns and conventions.
- Generate a concise style guide (naming conventions, file organization, import ordering, formatting rules).
- Present each guide and ask for confirmation.

Update `setup_state.json` to mark `code_styleguides` as complete.

---

### Artifact 6: `tracks.md` and `index.md`

Generate:
- `conductor/tracks.md` — An empty track registry with the heading and format example.
- `conductor/index.md` — Links to all context files created above.

Present both to the user and confirm.

Update `setup_state.json` to mark `tracks` and `index` as complete.

---

5. After all artifacts are created, display a summary:
   - "✅ Conductor setup complete! Here's what was created:"
   - List all files with their paths.
   - "Run `/conductor_newTrack` to start your first feature or bug fix track."
