#!/bin/bash
# =============================================================================
# Antigravity Conductor Skills & Rules Installer
# Copies Conductor skill, rule, and template files to Antigravity directory.
#
# Usage:
#   bash install.sh
#   bash install.sh --dry_run
#   bash install.sh --force
#   bash install.sh --uninstall
#   bash install.sh --update
#   bash install.sh --release_notes
#
# Target locations:
#   ~/.gemini/antigravity/skills/conductor_*/SKILL.md
#   ~/.gemini/antigravity/rules/conductor_*.md
# =============================================================================

FLAGS_TRUE=0
FLAGS_FALSE=1
FLAGS_dry_run=${FLAGS_FALSE}
FLAGS_force=${FLAGS_FALSE}
FLAGS_uninstall=${FLAGS_FALSE}
FLAGS_update=${FLAGS_FALSE}
FLAGS_release_notes=${FLAGS_FALSE}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry_run)
      FLAGS_dry_run=${FLAGS_TRUE}
      ;;
    --force)
      FLAGS_force=${FLAGS_TRUE}
      ;;
    --uninstall)
      FLAGS_uninstall=${FLAGS_TRUE}
      ;;
    --update)
      FLAGS_update=${FLAGS_TRUE}
      ;;
    --release_notes)
      FLAGS_release_notes=${FLAGS_TRUE}
      ;;
    --help|-h)
      echo "Usage: bash install.sh [OPTIONS]"
      echo "  --dry_run        Preview changes without writing files"
      echo "  --force          Overwrite existing files without backup"
      echo "  --update         Update to the latest version (implies --force)"
      echo "  --uninstall      Remove all installed files"
      echo "  --release_notes  Show release notes for the current version"
      echo "  --help, -h       Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
  shift
done

VERSION="0.3.0"

# --- Resolve source directory (relative to this script) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_TEMPLATE_DIR="${SCRIPT_DIR}/skills/conductor_setup/templates"
# Sub-skill names (each has its own directory under skills/)
SUB_SKILL_NAMES=(conductor_setup conductor_newTrack conductor_newTrack_grill conductor_newTrack_discovery conductor_implement conductor_status conductor_review conductor_revert conductor_chat)
# Rules files (always-on rule files for MVC architecture)
SOURCE_RULES_DIR="${SCRIPT_DIR}/rules"
RULE_FILE_NAMES=(conductor_protocol.md conductor_antigravity.md)
# Reference files (inert protocol extensions loaded on demand by skills)
REFERENCE_FILE_NAMES=(conductor_adr_preflight.md conductor_cdd_protocols.md)
# CHANGELOG for release notes extraction
SOURCE_CHANGELOG="${SCRIPT_DIR}/CHANGELOG.md"

# --- Color helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

msg_info()    { echo -e "  ${CYAN}📋${NC}  $*"; }
msg_success() { echo -e "  ${GREEN}✅${NC}  $*"; }
msg_warn()    { echo -e "  ${YELLOW}⚠️${NC}   $*"; }
msg_error()   { echo -e "  ${RED}❌${NC}  $*"; }
msg_skip()    { echo -e "  ${DIM}⏭️${NC}   ${DIM}$*${NC}"; }

banner() {
  echo ""
  echo -e "${MAGENTA}  ╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}  ║${NC}  ${BOLD}🎵 Antigravity Conductor Installer${NC}  ${DIM}v${VERSION}${NC}      ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}  ║${NC}  ${DIM}Skills & Rules for Antigravity${NC}                  ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}  ╚══════════════════════════════════════════════════╝${NC}"
  echo ""
}

section() { echo -e "\n${BLUE}━━━${NC} ${BOLD}$*${NC} ${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# --- Validate source files exist ---
validate_sources() {
  local missing=0
  if [[ ! -f "${SOURCE_TEMPLATE_DIR}/workflow_template.md" ]]; then
    msg_error "Source not found: ${SOURCE_TEMPLATE_DIR}/workflow_template.md"
    ((missing++))
  fi
  for sub_skill in "${SUB_SKILL_NAMES[@]}"; do
    if [[ ! -f "${SCRIPT_DIR}/skills/${sub_skill}/SKILL.md" ]]; then
      msg_error "Source not found: ${SCRIPT_DIR}/skills/${sub_skill}/SKILL.md"
      ((missing++))
    fi
  done
  for rule_file in "${RULE_FILE_NAMES[@]}"; do
    if [[ ! -f "${SOURCE_RULES_DIR}/${rule_file}" ]]; then
      msg_error "Source not found: ${SOURCE_RULES_DIR}/${rule_file}"
      ((missing++))
    fi
  done
  if [[ $missing -gt 0 ]]; then
    msg_error "Missing ${missing} source file(s). Run from the correct directory."
    exit 1
  fi
}

# =============================================================================
# Target Selection
# =============================================================================

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  USER_HOME="${USERPROFILE:-$HOME}"
else
  USER_HOME="$HOME"
fi

INSTALL_TARGET="antigravity"
TARGET_SKILLS_ROOT="${USER_HOME}/.gemini/antigravity/skills"
TARGET_RULES_ROOT="${USER_HOME}/.gemini/antigravity/rules"
LEGACY_WORKFLOW_DIR="${USER_HOME}/.gemini/antigravity/global_workflows"

build_target_list() {
  TARGET_TEMPLATE_DIR="${TARGET_SKILLS_ROOT}/conductor_setup/templates"
  ALL_TARGET_FILES=(
    "${TARGET_TEMPLATE_DIR}/workflow_template.md"
    "${TARGET_TEMPLATE_DIR}/adr_template.md"
    "${TARGET_SKILLS_ROOT}/conductor_setup/.conductor_version"
  )
  # Add each sub-skill SKILL.md
  for sub_skill in "${SUB_SKILL_NAMES[@]}"; do
    ALL_TARGET_FILES+=("${TARGET_SKILLS_ROOT}/${sub_skill}/SKILL.md")
  done
}

# --- Helper: install a single file ---
install_file() {
  local source="$1"
  local target="$2"
  local target_dir
  target_dir=$(dirname "$target")
  local base_name
  base_name=$(basename "$target")

  if [[ ! -d "$target_dir" ]]; then
    if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
      msg_info "${YELLOW}[dry-run]${NC} Would create directory: ${CYAN}${target_dir}${NC}"
    else
      mkdir -p "$target_dir"
      msg_info "📂 Created directory: ${CYAN}${target_dir}${NC}"
    fi
  fi

  if [[ -f "$target" ]]; then
    if diff -q "$source" "$target" &>/dev/null; then
      msg_skip "${base_name} ${DIM}(already up-to-date)${NC}"
      return 0
    fi

    if [[ "${FLAGS_force}" -ne "${FLAGS_TRUE}" ]]; then
      local backup="${target}.bak"
      if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
        msg_info "${YELLOW}[dry-run]${NC} Would backup: ${CYAN}${base_name}${NC} → ${CYAN}${base_name}.bak${NC}"
      else
        cp "$target" "$backup"
        msg_warn "💾 Backed up: ${CYAN}${base_name}${NC} → ${CYAN}${base_name}.bak${NC}"
      fi
    fi
  fi

  if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
    msg_info "${YELLOW}[dry-run]${NC} Would install: ${GREEN}${base_name}${NC}"
  else
    cp "$source" "$target"
    msg_success "Installed: ${GREEN}${base_name}${NC}  →  ${DIM}${target}${NC}"
  fi
}

# =============================================================================
# Legacy workflow migration
# =============================================================================

migrate_from_workflows() {
  if [[ -z "${LEGACY_WORKFLOW_DIR}" ]]; then
    return 0
  fi

  local legacy_files=()
  for wf in implement newTrack revert review setup status; do
    local legacy_file="${LEGACY_WORKFLOW_DIR}/conductor_${wf}.md"
    if [[ -f "$legacy_file" ]]; then
      legacy_files+=("$legacy_file")
    fi
  done

  if [[ ${#legacy_files[@]} -eq 0 ]]; then
    return 0
  fi

  section "🔄 Legacy Workflow Migration"
  echo ""
  msg_warn "Found ${BOLD}${#legacy_files[@]}${NC}${YELLOW} legacy Conductor workflow file(s) in:${NC}"
  echo -e "     ${DIM}${LEGACY_WORKFLOW_DIR}${NC}"
  echo ""
  echo -e "  ${DIM}Antigravity Workflows are deprecated in favor of Skills.${NC}"
  echo -e "  ${DIM}Conductor commands are now individual skills under:${NC}"
  echo -e "     ${CYAN}${TARGET_SKILLS_ROOT}/conductor_*/${NC}"
  echo ""

  if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
    for f in "${legacy_files[@]}"; do
      msg_info "${YELLOW}[dry-run]${NC} Would remove legacy: ${CYAN}$(basename "$f")${NC}"
    done
    return 0
  fi

  read -r -p "  Remove legacy workflow files? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    for f in "${legacy_files[@]}"; do
      rm "$f"
      msg_success "Removed legacy: ${CYAN}$(basename "$f")${NC}"
    done
    echo ""
    msg_success "Legacy workflow cleanup complete."
  else
    msg_warn "Skipping cleanup. Legacy workflows will coexist with skill commands."
    msg_warn "You can remove them manually from: ${CYAN}${LEGACY_WORKFLOW_DIR}${NC}"
  fi
}

# --- Migrate from hub skill (pre-v0.3.0 → v0.3.0) ---
migrate_from_hub_skill() {
  local hub_dir="${TARGET_SKILLS_ROOT}/conductor"
  local hub_skill="${hub_dir}/SKILL.md"

  if [[ ! -f "$hub_skill" ]]; then
    return 0
  fi

  section "🔄 Hub Skill Migration (v0.3.0)"
  echo ""
  msg_warn "Found legacy hub skill at:"
  echo -e "     ${DIM}${hub_skill}${NC}"
  echo ""
  echo -e "  ${DIM}The hub skill was removed in v0.3.0. Directory structure and${NC}"
  echo -e "  ${DIM}context loading now live in conductor_protocol.md (always-on rule).${NC}"
  echo ""

  if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
    msg_info "${YELLOW}[dry-run]${NC} Would migrate version stamp from ${CYAN}conductor/${NC} to ${CYAN}conductor_setup/${NC}"
    msg_info "${YELLOW}[dry-run]${NC} Would remove hub skill directory: ${CYAN}${hub_dir}${NC}"
    return 0
  fi

  # Migrate version stamp if it exists at the old location
  local old_version_file="${hub_dir}/.conductor_version"
  local new_version_file="${TARGET_SKILLS_ROOT}/conductor_setup/.conductor_version"
  if [[ -f "$old_version_file" ]] && [[ ! -f "$new_version_file" ]]; then
    mkdir -p "${TARGET_SKILLS_ROOT}/conductor_setup"
    mv "$old_version_file" "$new_version_file"
    msg_success "Migrated version stamp to ${CYAN}conductor_setup/.conductor_version${NC}"
  fi

  # Remove hub directory (SKILL.md, templates/, .conductor_version)
  rm -rf "$hub_dir"
  msg_success "Removed legacy hub skill directory: ${CYAN}${hub_dir}${NC}"
}

# --- Version check ---
check_for_updates() {
  local latest_version="${VERSION}"

  local install_dirs=(
    "${USER_HOME}/.gemini/antigravity/skills/conductor_setup"
  )
  local found_any=false

  for dir in "${install_dirs[@]}"; do
    local version_file="${dir}/.conductor_version"
    local skill_file="${dir}/SKILL.md"
    local target_name="antigravity"

    if [[ -f "$version_file" ]]; then
      found_any=true
      local installed_version
      installed_version=$(cat "$version_file" 2>/dev/null | tr -d '[:space:]')

      if [[ "$installed_version" == "$latest_version" ]]; then
        msg_success "${WHITE}${target_name}${NC}: Up to date (${WHITE}v${installed_version}${NC})"
      else
        echo -e "  ${YELLOW}🆕${NC}  ${WHITE}${target_name}${NC}: Update available — ${DIM}v${installed_version}${NC} → ${GREEN}v${latest_version}${NC}"
      fi
    elif [[ -f "$skill_file" ]]; then
      found_any=true
      echo -e "  ${YELLOW}🆕${NC}  ${WHITE}${target_name}${NC}: Legacy install detected (pre-v0.2.1) — update to ${GREEN}v${latest_version}${NC}"
    fi
  done

  if [[ "$found_any" == false ]]; then
    msg_info "No existing Conductor installations found."
    msg_info "Run ${CYAN}install.sh${NC} to install."
  else
    echo ""
    echo -e "  ${DIM}To update, run:${NC}"
    echo -e "  ${CYAN}bash install.sh --update${NC}"
  fi
}

# =============================================================================
# Main flow
# =============================================================================

banner

if [[ "${FLAGS_release_notes}" -eq "${FLAGS_TRUE}" ]]; then
  if [[ -f "${SOURCE_CHANGELOG:-}" ]]; then
    section "📝 Release Notes — v${VERSION}"
    echo ""
    awk -v ver="${VERSION}" '
      /^## \[/ { if (found) exit; if (index($0, ver)) found=1 }
      found { print "  " $0 }
    ' "${SOURCE_CHANGELOG}"
    echo ""
  else
    msg_warn "CHANGELOG.md not found."
  fi
  exit 0
fi

if [[ "${FLAGS_update}" -eq "${FLAGS_TRUE}" ]]; then
  FLAGS_force="${FLAGS_TRUE}"

  build_target_list

  version_file="${TARGET_SKILLS_ROOT}/conductor_setup/.conductor_version"
  if [[ -f "$version_file" ]]; then
    installed_version=$(cat "$version_file" 2>/dev/null | tr -d '[:space:]')
    if [[ "$installed_version" == "$VERSION" ]]; then
      msg_success "Already up to date (${WHITE}v${VERSION}${NC})"
      exit 0
    fi
    echo -e "  ${DIM}Installed:${NC} ${WHITE}v${installed_version}${NC}  →  ${GREEN}v${VERSION}${NC}"
  elif [[ -f "${TARGET_SKILLS_ROOT}/conductor_setup/SKILL.md" ]]; then
    echo -e "  ${DIM}Installed:${NC} ${YELLOW}pre-v0.2.1 (legacy)${NC}  →  ${GREEN}v${VERSION}${NC}"
  else
    msg_info "No existing installation found. Performing fresh install."
  fi
  echo ""
fi

if [[ -z "${INSTALL_TARGET:-}" ]]; then
  build_target_list
fi

echo -e "  ${DIM}Target:${NC}  ${WHITE}${INSTALL_TARGET}${NC}"

# =============================================================================
# Uninstall
# =============================================================================
if [[ "${FLAGS_uninstall}" -eq "${FLAGS_TRUE}" ]]; then
  section "🗑️  Uninstalling Conductor"
  echo ""

  removed=0
  for file in "${ALL_TARGET_FILES[@]}"; do
    if [[ -f "$file" ]]; then
      local_name=$(basename "$file")
      if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
        msg_info "${YELLOW}[dry-run]${NC} Would remove: ${CYAN}${local_name}${NC}"
      else
        rm "$file"
        msg_success "Removed: ${CYAN}${local_name}${NC}"
      fi
      ((removed++))
    fi
  done

  # Also clean up any legacy workflow files
  if [[ -n "${LEGACY_WORKFLOW_DIR}" ]]; then
    for wf in implement newTrack revert review setup status; do
      local legacy_file="${LEGACY_WORKFLOW_DIR}/conductor_${wf}.md"
      if [[ -f "$legacy_file" ]]; then
        local_name=$(basename "$legacy_file")
        if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
          msg_info "${YELLOW}[dry-run]${NC} Would remove legacy: ${CYAN}${local_name}${NC}"
        else
          rm "$legacy_file"
          msg_success "Removed legacy: ${CYAN}${local_name}${NC}"
        fi
        ((removed++))
      fi
    done
  fi

  # Also clean up sub-skill directories
  for sub_skill in "${SUB_SKILL_NAMES[@]}"; do
    local sub_skill_file="${TARGET_SKILLS_ROOT}/${sub_skill}/SKILL.md"
    if [[ -f "$sub_skill_file" ]]; then
      local_name="${sub_skill}/SKILL.md"
      if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
        msg_info "${YELLOW}[dry-run]${NC} Would remove: ${CYAN}${local_name}${NC}"
      else
        rm "$sub_skill_file"
        msg_success "Removed: ${CYAN}${local_name}${NC}"
      fi
      ((removed++))
    fi
  done

  # Clean up empty directories
  for sub_skill in "${SUB_SKILL_NAMES[@]}"; do
    local sub_dir="${TARGET_SKILLS_ROOT}/${sub_skill}"
    if [[ -d "$sub_dir" ]] && [[ -z "$(ls -A "$sub_dir" 2>/dev/null)" ]]; then
      if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
        msg_info "${YELLOW}[dry-run]${NC} Would remove empty directory: ${DIM}${sub_dir}${NC}"
      else
        rmdir "$sub_dir"
        msg_success "Cleaned up empty directory: ${DIM}${sub_dir}${NC}"
      fi
    fi
  done
  for dir in "${TARGET_SKILLS_ROOT}/conductor_setup/templates"; do
    if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
      if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
        msg_info "${YELLOW}[dry-run]${NC} Would remove empty directory: ${DIM}${dir}${NC}"
      else
        rmdir "$dir"
        msg_success "Cleaned up empty directory: ${DIM}${dir}${NC}"
      fi
    fi
  done

  echo ""
  if [[ $removed -eq 0 ]]; then
    msg_info "Nothing to uninstall — no Conductor files found."
  else
    echo -e "  ${GREEN}🧹 Uninstalled ${BOLD}${removed}${NC}${GREEN} file(s). All clean!${NC}"
  fi
  echo ""
  exit 0
fi

# =============================================================================
# Install
# =============================================================================

validate_sources

if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
  echo -e "  ${YELLOW}👀 DRY RUN MODE — no files will be written${NC}"
fi

# --- Migrate legacy workflows (if any) ---
migrate_from_workflows

# --- Migrate hub skill (pre-v0.3.0 → v0.3.0) ---
migrate_from_hub_skill

# --- Templates ---
section "📄 Installing Conductor Templates"
echo ""
install_file "${SOURCE_TEMPLATE_DIR}/workflow_template.md" "${TARGET_TEMPLATE_DIR}/workflow_template.md"
install_file "${SOURCE_TEMPLATE_DIR}/adr_template.md" "${TARGET_TEMPLATE_DIR}/adr_template.md"

# --- Write version stamp ---
if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
  msg_info "${YELLOW}[dry-run]${NC} Would write version file: ${GREEN}.conductor_version${NC}"
else
  mkdir -p "${TARGET_SKILLS_ROOT}/conductor_setup"
  echo "$VERSION" > "${TARGET_SKILLS_ROOT}/conductor_setup/.conductor_version"
  msg_success "Wrote version stamp: ${GREEN}v${VERSION}${NC}"
fi

# --- Sub-Skills ---
section "🔧 Installing Conductor Command Skills"
echo ""
for sub_skill in "${SUB_SKILL_NAMES[@]}"; do
  install_file "${SCRIPT_DIR}/skills/${sub_skill}/SKILL.md" "${TARGET_SKILLS_ROOT}/${sub_skill}/SKILL.md"
done

# --- Rules ---
section "📏 Installing Conductor Rules"
echo ""
for rule_file in "${RULE_FILE_NAMES[@]}"; do
  install_file "${SOURCE_RULES_DIR}/${rule_file}" "${TARGET_RULES_ROOT}/${rule_file}"
done
# Install reference files (inert, no YAML frontmatter)
for ref_file in "${REFERENCE_FILE_NAMES[@]}"; do
  install_file "${SOURCE_RULES_DIR}/${ref_file}" "${TARGET_RULES_ROOT}/${ref_file}"
done

# --- Summary ---
section "📊 Summary"
echo ""
echo -e "  ${DIM}Version:${NC}       ${WHITE}${VERSION}${NC}"
echo -e "  ${DIM}Target:${NC}        ${WHITE}${INSTALL_TARGET}${NC}"
echo -e "  ${DIM}Source:${NC}        ${CYAN}${SCRIPT_DIR}${NC}"
echo -e "  ${DIM}Skills:${NC}        ${CYAN}${TARGET_SKILLS_ROOT}/conductor_*/${NC}"
echo -e "  ${DIM}Rules dir:${NC}     ${CYAN}${TARGET_RULES_ROOT}${NC}"
echo -e "  ${DIM}Files:${NC}         ${WHITE}${#ALL_TARGET_FILES[@]}${NC} total"
echo ""

check_for_updates

# --- Optional dependency check ---
if ! command -v sg &>/dev/null; then
  echo -e "  ${YELLOW}[optional]${NC} ast-grep (sg) not found"
  echo -e "           API surface extraction will use regex fallback."
  echo -e "           For higher-quality glossary suggestions, install ast-grep:"
  echo -e "           ${CYAN}https://ast-grep.github.io/guide/quick-start.html${NC}"
  echo ""
fi

if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
  echo -e "  ${YELLOW}🔍 Dry run complete. Re-run without --dry_run to apply changes.${NC}"
else
  echo -e "  ${GREEN}🚀 Installation complete! You're ready to conduct.${NC}"
fi
echo ""
