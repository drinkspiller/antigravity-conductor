# Antigravity Conductor Skills & Workflows

## Background

[Gemini CLI Conductor](https://github.com/gemini-cli-extensions/conductor) is a
Gemini CLI extension that enables Context-Driven Development. It manages the
full lifecycle of software development tracks: context setup, specification,
planning, implementation, and review.

This installer creates an **Antigravity Skill and workflows** that bring Conductor's
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

## What Gets Installed

File                     | Location                             | Purpose
------------------------ | ------------------------------------ | -------
`SKILL.md`               | `~/.gemini/antigravity/skills/conductor/` | Core skill definition (commands, context loading, track lifecycle)
`conductor_setup.md`     | `~/.gemini/antigravity/global_workflows/` | `/conductor_setup` — Initialize project context
`conductor_newTrack.md`  | `~/.gemini/antigravity/global_workflows/` | `/conductor_newTrack` — Start a new feature or bug fix
`conductor_implement.md` | `~/.gemini/antigravity/global_workflows/` | `/conductor_implement` — Execute plan tasks sequentially
`conductor_status.md`    | `~/.gemini/antigravity/global_workflows/` | `/conductor_status` — View project progress
`conductor_review.md`    | `~/.gemini/antigravity/global_workflows/` | `/conductor_review` — Review work against spec
`conductor_revert.md`    | `~/.gemini/antigravity/global_workflows/` | `/conductor_revert` — Undo work via VCS-aware revert
`workflow_template.md`   | `~/.gemini/antigravity/skills/conductor/templates/` | Bundled workflow template copied to projects during `/conductor_setup`
`.conductor_version`     | `~/.gemini/antigravity/skills/conductor/` | Version stamp for update detection

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

Flag          | Description
------------- | --------------------------------------------------------
`--dry_run`   | Preview changes without writing or deleting files
`--force`     | Overwrite existing files without creating `.bak` backups
`--update`    | Update to the latest version (implies `--force`)
`--uninstall` | Remove all installed Conductor files
`--help`      | Show usage information

## Checking for Updates

The `--update` flag checks if your installed version is current and, if not,
performs the update automatically (implying `--force`):

```bash
bash install.sh --update
```

If already up to date, it exits immediately. A version check also runs
automatically at the end of every regular install.

## Usage After Installation

In Antigravity, typing `/` opens an autocomplete dropdown listing available workflows. The conductor commands are available globally once installed:

```
/conductor_setup          # Initialize a project's conductor/ context
/conductor_newTrack       # Create a new feature or bug fix track
/conductor_implement      # Execute the current track's plan
/conductor_status         # View progress across all tracks
/conductor_review         # Review completed work against spec
/conductor_revert         # Undo work from a track, phase, or task
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

## Version

Current: **v0.2.1**
