# Antigravity Conductor Skills

## Background

[Gemini CLI Conductor](https://github.com/gemini-cli-extensions/conductor) is a
Gemini CLI extension that enables Context-Driven Development. It manages the
full lifecycle of software development tracks: context setup, specification,
planning, implementation, and review.

This installer creates **Antigravity Skills** that bring Conductor's
capabilities to Antigravity.

## Motivation

Standard IDE-based AI agents are powerful, but store their plans, context, and
knowledge on the developer's machine. The intelligence accumulated during
development **doesn't travel with the code and is invisible to teammates**.

Conductor takes a different approach: **context is a managed artifact that lives
alongside your code.** Specs, plans, and progress live along side the project
source in a `conductor/` directory as self-updating, curated knowledge
artifacts. Context travels with the codebase and can be shared by the whole
team.

Agents and engineers both draw from a common knowledge base, so the AI
understands the codebase, and so do the developers. Centralized technical
constraints (style guides, workflow rules, tech-stack choices) guide every agent
interaction's adherence to the team's practices and preferences. And all present
and future work benefits from the evolving project context — it gets smarter
over time, not stale.

By installing Conductor as an Antigravity Skill, you get both: Antigravity's visual,
powerful agentic coding tools and session-level knowledge, *plus* shared project
context that the whole team can use.

## Domain Modeling & Architecture Decision Records (ADRs)

Conductor integrates Bounded Context domain modeling and Architecture Decision
Records (ADRs) into the track lifecycle. This fixes two common ways
agent-managed codebases decay: vocabulary drift and unverified architecture.

Without a shared glossary, an agent might use `invoice` in one track, `bill` in
another, and `payment_request` in a third. This leaves the codebase cluttered
with synonyms. Conductor now initializes a `terms.md` file during setup to force
consistent naming across all tracks.

Similarly, an agent might specify client-side validation for speed, but
implement it on the backend during implementation because nothing forced them to
test the client-side bridge. The code runs, but the architecture is broken.
Conductor now enforces testable gates.

### Inspiration

This workflow combines two ideas:

- **Castor ADRs**: Establishes testing rigor. Every major decision requires a
  confirmation section defining exactly how it will be verified.
- **Matt Pocock's Domain Modeling
  ([mattpocock/domain-modeling](https://github.com/mattpocock/skills/tree/main/skills/engineering/domain-modeling)):**
  Establishes vocabulary steering via a glossary and filters decision records
  through a strict three-part gate (is it hard to reverse, is it surprising,
  and does it represent a real trade-off?).

### How it Works

The glossary (`terms.md`) is created during setup. It defines canonical terms
and lists forbidden synonyms. The agent is forced to use these terms when
drafting specifications and writing code.

Architectural decisions are written to `conductor/adr/` as `NNNN-slug.md`.
Simple choices use a light template. Major pivots use a rich template with a
mandatory confirmation section. For instance, an ADR mandating client-side
validation must include a testable requirement, such as verifying a WebKit
handshake completes under 150ms.

The planner reads these confirmation blocks and injects them as concrete testing
tasks directly into `plan.md`. This ensures decisions are actually verified
before the code is marked complete.

For legacy projects, a preflight sweep checks for undocumented trade-offs in
existing docs and offers to backfill them as ADRs before starting new work.

Finally, the review command checks the workspace diff against active ADRs. If
the code contradicts a decision, the agent flags it and prompts the user to
either fix the code, update the ADR, or record the divergence as tech debt.

### The Operational Loop

```
/conductor_setup     →  Initialize glossary (terms.md), invariants, adr/ dir,
                        per-directory GEMINI.md context (brownfield)
/conductor_newTrack  →  Enforce glossary terms in spec; gate decisions → ADRs
                        Translate ADR Confirmation blocks → plan.md tasks
                        Capture invariants from Devil's Advocate challenges
/conductor_implement →  Execute plan including ADR verification checkpoints
                        Auto-extract API surfaces at phase boundaries
                        Capture invariants from implementation guards
                        On completion, sync glossary + invariants + GEMINI.md
/conductor_review    →  Check code against ADRs + invariants; warn on drift
```

## Context-Driven Development (CDD) Enhancements

Conductor v0.3.0 extends the framework with four capabilities that make context
maintenance continuous rather than manual:

- **Invariants** (`conductor/invariants.md`): Behavioral contracts (ordering
  constraints, initialization guards, data-flow rules) captured during spec
  generation, implementation, and review. The agent checks invariant compliance
  automatically during review and drift detection.
- **Pre-Execution Drift Scan**: Every Conductor command cross-references
  uncommitted changes against ADR scopes and invariant scopes. Contradictions
  are flagged before the agent does more work on top of them.
- **API Surface Auto-Extraction**: Phase checkpoints use AST extraction to
  identify new public symbols and propose glossary updates.
- **Per-Directory GEMINI.md Context**: Large directories get scoped context
  sections that reduce the agent's context loading tax and provide
  directory-specific invariants, key types, and term overrides.

## What Gets Installed

### Skills

| File                            | Location                                                          | Purpose                                                                                   |
| ------------------------------- | ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `conductor_setup/`              | `~/.gemini/antigravity/skills/conductor_setup/`                   | `/conductor_setup` — Initialize project context (persona: Conductor Architect)             |
| `workflow_template.md`          | `~/.gemini/antigravity/skills/conductor_setup/templates/`         | Bundled project workflow template copied during `/conductor_setup`                         |
| `adr_template.md`               | `~/.gemini/antigravity/skills/conductor_setup/templates/`         | Bundled project ADR template copied during `/conductor_setup`                              |
| `.conductor_version`            | `~/.gemini/antigravity/skills/conductor_setup/`                   | Version stamp for update detection                                                        |
| `conductor_newTrack/`           | `~/.gemini/antigravity/skills/conductor_newTrack/`                | `/conductor_newTrack` — Start a new feature or bug fix (persona: Conductor Planner)        |
| `conductor_newTrack_grill/`     | `~/.gemini/antigravity/skills/conductor_newTrack_grill/`          | Grill mode for newTrack — relentless interview (persona: Conductor Interrogator)           |
| `conductor_newTrack_discovery/` | `~/.gemini/antigravity/skills/conductor_newTrack_discovery/`      | Discovery mode for newTrack — categorized questioning (persona: Conductor Explorer)        |
| `conductor_implement/`          | `~/.gemini/antigravity/skills/conductor_implement/`               | `/conductor_implement` — Execute plan tasks sequentially (persona: Conductor Implementer)  |
| `conductor_status/`             | `~/.gemini/antigravity/skills/conductor_status/`                  | `/conductor_status` — View project progress (persona: Conductor Observer)                  |
| `conductor_review/`             | `~/.gemini/antigravity/skills/conductor_review/`                  | `/conductor_review` — Review work against spec (persona: Principal Software Engineer)      |
| `conductor_revert/`             | `~/.gemini/antigravity/skills/conductor_revert/`                  | `/conductor_revert` — Undo work via VCS-aware revert (persona: Conductor Surgeon)          |
| `conductor_chat/`               | `~/.gemini/antigravity/skills/conductor_chat/`                    | `/conductor_chat` — Ceremony-free context mode (persona: Conductor Guide)                  |

### Rules (MVC Architecture)

| File                           | Location                               | Purpose                                                                           |
| ------------------------------ | -------------------------------------- | --------------------------------------------------------------------------------- |
| `conductor_protocol.md`        | `~/.gemini/antigravity/rules/`         | Always-on: directory structure, context loading, guardrails, interaction standards |
| `conductor_antigravity.md`     | `~/.gemini/antigravity/rules/`         | Always-on: Antigravity platform UI adapter (`ask_question`, artifact rendering)   |
| `conductor_adr_preflight.md`   | `~/.gemini/antigravity/rules/`         | On-demand: ADR preflight interceptor for brownfield projects                      |
| `conductor_cdd_protocols.md`   | `~/.gemini/antigravity/rules/`         | On-demand: Drift scan, invariant capture, per-directory GEMINI.md context         |

## Installation

You can run the installer script on Mac/Linux or Windows.

### Mac, Linux, and WSL

```bash
# Standard installation
bash install.sh

# Preview what will happen (no files written)
bash install.sh --dry_run

# Overwrite without creating backups
bash install.sh --force
```

### Windows (CMD or PowerShell)

```bat
:: Standard installation
install.bat

:: Preview what will happen (no files written)
install.bat --dry_run

:: Overwrite without creating backups
install.bat --force
```

## Uninstall

**Mac, Linux, and WSL:**
```bash
bash install.sh --uninstall
```

**Windows:**
```bat
install.bat --uninstall
```

## Flags

Flag              | Description
----------------- | --------------------------------------------------------
`--dry_run`       | Preview changes without writing or deleting files
`--force`         | Overwrite existing files without creating `.bak` backups
`--update`        | Update to the latest version (implies `--force`)
`--uninstall`     | Remove all installed Conductor files
`--release_notes` | Show release notes for the current version from CHANGELOG.md
`--help`          | Show usage information

## Checking for Updates

The `--update` flag checks if your installed version is current and, if not,
performs the update automatically (implying `--force`):

```bash
bash install.sh --update
```

If already up to date, it exits immediately. A version check also runs
automatically at the end of every regular install.

## Upgrading

```bash
bash install.sh --update
```

The installer handles all migrations automatically (including legacy workflow
cleanup and hub skill removal). See [CHANGELOG.md](CHANGELOG.md) for what
changed in each version.

## Usage After Installation

In Antigravity, typing `/` opens an autocomplete dropdown listing available workflows. The conductor commands are available globally once installed:

```
/conductor_setup          # Initialize a project's conductor/ context
/conductor_newTrack       # Create a new feature or bug fix track
/conductor_implement      # Execute the current track's plan
/conductor_status         # View progress across all tracks
/conductor_review         # Review completed work against spec
/conductor_revert         # Undo work from a track, phase, or task
/conductor_chat           # Ingest conductor knowledge, then go — no tracks or gates.
                          # Ideal for asking how things work, exploring the codebase
                          # with full context, or diving into lightweight implementations
                          # that don't warrant a dedicated track.
```

### Via Natural Language

The Conductor skill is also attached as a global skill, so you can invoke it
with **natural language** instead of workflow commands. For example:

> *"Start a new track for adding dark mode support to the settings page"*

> *"Show me the current status of all my tracks"*

> *"Implement the next task in the active track"*

> *"Review the work I've done on the current track against the spec"*

Antigravity will automatically read the Conductor skill and execute the
appropriate command based on your prompt.

### `/conductor_newTrack` Modes

`/conductor_newTrack` supports three questioning modes for spec generation. The
mode is detected from keywords in your prompt:

| Mode          | Trigger                    | Behavior                                             |
| ------------- | -------------------------- | ---------------------------------------------------- |
| **Default**   | No keyword                 | Fixed 3-5 clarifying questions, then design decisions |
| **Grill**     | `grill`, `grill-me`, `grill me` | Relentless interview walking every branch of the decision tree until shared understanding. Enforces domain glossary, cross-references code, targets spec sections. |
| **Discovery** | `[experimental-discovery]` | Categorized questioning (Tech, UX, Risk, Edge cases, Opportunities) with dynamic follow-ups per category |

**Examples:**

```
# Default mode — quick, structured
/conductor_newTrack add dark mode to settings

# Grill mode — deep, exhaustive interview
/conductor_newTrack grill me — add dark mode to settings

# Discovery mode — category-driven exploration
/conductor_newTrack [experimental-discovery] add dark mode to settings
```

All three modes feed into the same downstream pipeline: draft spec → gap
analysis → cross-track awareness → devil's advocate → plan generation.

## Version

Current: **v0.3.0** — See [CHANGELOG.md](CHANGELOG.md) for release notes.
