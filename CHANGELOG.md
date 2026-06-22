# Changelog

All notable changes to Antigravity Conductor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-06-22

### Breaking

-   **Removed hub skill** (`conductor/SKILL.md`): The directory structure and
    context loading priorities now live in `conductor_protocol.md` §0/§0a.
    Individual command skills (`conductor_setup`, `conductor_newTrack`, etc.)
    are discoverable via their YAML frontmatter descriptions. No routing table
    or hub orientation doc is needed.

### Added

-   **API Surface Auto-Extraction**: Phase checkpoints in `/conductor_implement`
    now run full-file AST extraction (via `ast-grep`) on changed files, compare
    against a cached snapshot (`.api_surface_cache.json`), and propose novel
    symbols for addition to `terms.md`. Catches new methods on existing classes,
    interface properties, and enum members — not just top-level exports.

-   **Invariants as First-Class Artifact**: New `conductor/invariants.md` file
    for behavioral contracts (ordering constraints, null-check requirements,
    data-flow rules). Capture triggers fire during spec generation (Devil's
    Advocate), design decisions, implementation, review, and user-initiated
    statements.

-   **Pre-Execution Drift Scan**: Every Conductor command now performs a
    lightweight drift check during context loading. Changed files are
    cross-referenced against ADR scopes and invariant scopes; contradictions are
    flagged with resolution options before the command proceeds.

-   **Per-Directory GEMINI.md Context**: Conductor manages a `## Conductor
    Context` section inside existing `GEMINI.md` files for large directories.
    Sections include Purpose, Invariants, Key Types, and Term Overrides,
    delimited by boundary comments to prevent merge conflicts. Created during
    `/conductor_setup` (brownfield) and `/conductor_implement` (on first
    directory access).

-   **Grill mode** for `/conductor_newTrack` — conductor-aware relentless
    interview mode, triggered by "grill", "grill-me", or "grill me" in the
    prompt. Merges grill-me's recursive questioning with conductor domain
    awareness (glossary enforcement, code cross-referencing, spec-section
    targeting). New sub-skill: `conductor_newTrack_grill` (persona: Conductor
    Interrogator).

-   **Discovery mode** extracted to its own sub-skill — the
    `[experimental-discovery]` categorized questioning is now
    `conductor_newTrack_discovery` (persona: Conductor Explorer), keeping the
    newTrack protocol clean.

-   **ADR & Glossary Preflight Interceptor**: When any Conductor command
    executes against an existing brownfield project that lacks
    `conductor/adr/*.md` files, execution pauses to perform an automated
    document sweep, filter trade-offs through the 3-part gate, and backfill
    historical ADRs before resuming the primary command.

-   **Domain Modeling & ADR Integration**:
    -   **Project Glossary (`terms.md`)**: Semi-mandatory, skippable glossary
        step in `/conductor_setup`. Auto-populates from codebase scans in
        Brownfield projects; interviews the developer in Greenfield.
    -   **Inline ADR Gating**: 3-part gate (hard to reverse × surprising × real
        trade-off) evaluated per-decision in `/conductor_newTrack`.
    -   **Immediate ADR Writing**: Confirmed decisions written immediately to
        `conductor/adr/NNNN-slug.md` using the bundled `adr_template.md`.
    -   **Verification Bridge**: `plan.md` generation scans ADR `Confirmation`
        sections and injects their criteria as explicit verification tasks.
    -   **ADR Compliance Reviews**: `/conductor_review` checks code changes
        against active ADRs, warning on drift and offering to fix, update the
        ADR, or record tech debt.

-   **MVC rules architecture**: Extracted universal guardrails and Antigravity
    UX adapter into always-on rule files (`conductor_protocol.md`,
    `conductor_antigravity.md`). Extended protocols extracted to inert reference
    files (`conductor_adr_preflight.md`, `conductor_cdd_protocols.md`) loaded
    on demand by skills.

-   **Agent personas**: Each sub-skill defines a named persona (Conductor
    Architect, Conductor Planner, Conductor Implementer, Principal Software
    Engineer, Conductor Observer, Conductor Surgeon, Conductor Guide, Conductor
    Interrogator, Conductor Explorer).

-   **`--release_notes` flag** in installer: Shows changes for the installed
    version from CHANGELOG.md.

### Changed

-   **Token footprint reduction (~68%)**: Always-on protocol rule is compact.
    Extended protocols extracted to inert reference files loaded on demand by
    skills. Hub skill eliminated entirely.
-   **Glossary file renamed**: `TERMS.md` → `terms.md` for consistency with
    all other lowercase conductor artifact filenames.
-   **Templates relocated**: `workflow_template.md` and `adr_template.md` moved
    from `conductor/templates/` to `conductor_setup/templates/` — the only
    skill that uses them.
-   **Version stamp relocated**: `.conductor_version` now lives under
    `conductor_setup/` instead of the removed `conductor/` directory.
-   **Installer**: Installs rules and reference files alongside skills. Removed
    hub skill installation. Hub skill migration auto-removes old `conductor/`
    directory during upgrade. Added `ast-grep` optional dependency check.
-   **`conductor_newTrack` Step 6** refactored to a mode dispatch point —
    detects grill/discovery/default mode from the user's prompt and delegates
    to the appropriate sub-skill.

## [0.2.2] - 2026-04-10

### Added

-   `/conductor_chat` — Lightweight ceremony-free context mode
-   Enhanced `/conductor_newTrack` discovery pipeline (gap analysis, cross-track
    awareness, devil's advocate)
-   Individual `ask_question` calls for gap analysis and devil's advocate items
-   `ask_question` best practices with positive/negative examples

### Changed

-   Hub skill expanded with detailed artifact output conventions
-   Sub-skills updated with per-item structured questioning

## [0.2.1] - 2026-03-01

### Added

-   Skills-based architecture (migrated from workflows)
-   Hub-and-spoke model with central conductor skill
-   Version stamping (`.conductor_version`)
-   Legacy workflow migration in installer
-   Dry-run mode, backup-by-default, idempotent installs

## [0.1.0] - 2026-02-01

### Added

-   Initial conductor implementation as Antigravity workflows
-   Core commands: setup, newTrack, implement, status, review, revert
