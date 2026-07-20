#!/bin/bash
# =============================================================================
# Antigravity Conductor Skills & Rules Installer
# Copies Conductor skill and rule files to Antigravity directory.
#
# Usage:
#   bash install.sh
#   bash install.sh --dry_run
#   bash install.sh --force
#   bash install.sh --uninstall
#   bash install.sh --update
#
# Target locations:
#   ~/.gemini/antigravity/skills/conductor-*/SKILL.md
#   ~/.gemini/antigravity/rules/conductor_*.md
# =============================================================================

FLAGS_TRUE=0
FLAGS_FALSE=1
FLAGS_dry_run=${FLAGS_FALSE}
FLAGS_force=${FLAGS_FALSE}
FLAGS_uninstall=${FLAGS_FALSE}
FLAGS_update=${FLAGS_FALSE}

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
    --help|-h)
      echo "Usage: bash install.sh [OPTIONS]"
      echo "  --dry_run    Preview changes without writing files"
      echo "  --force      Overwrite existing files without backup"
      echo "  --update     Update to the latest version (implies --force)"
      echo "  --uninstall  Remove all installed files"
      echo "  --help, -h   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
  shift
done

VERSION="0.11.0"

# --- Resolve source directory (relative to this script) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_TEMPLATE_DIR="${SCRIPT_DIR}/skills/conductor-setup/templates"
# Sub-skill names (each has its own directory under skills/)
SUB_SKILL_NAMES=(conductor-setup conductor-new-track conductor-implement conductor-status conductor-review conductor-revert conductor-chat)
# Rules files (always-on rule files for MVC architecture)
SOURCE_RULES_DIR="${SCRIPT_DIR}/rules"
RULE_FILE_NAMES=(conductor_protocol.md conductor_jetski.md conductor_adr_preflight.md conductor_cdd_protocols.md)

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
  echo -e "${MAGENTA}  ║${NC}  ${DIM}Skills & Rules for Antigravity${NC}                    ${MAGENTA}║${NC}"
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
TARGET_TEMPLATE_DIR="${TARGET_SKILLS_ROOT}/conductor-setup/templates"

build_target_list() {
  ALL_TARGET_FILES=(
    "${TARGET_TEMPLATE_DIR}/workflow_template.md"
    "${TARGET_TEMPLATE_DIR}/adr_template.md"
    "${TARGET_SKILLS_ROOT}/conductor-setup/.conductor_version"
  )
  for sub_skill in "${SUB_SKILL_NAMES[@]}"; do
    ALL_TARGET_FILES+=("${TARGET_SKILLS_ROOT}/${sub_skill}/SKILL.md")
  done
  for rule_file in "${RULE_FILE_NAMES[@]}"; do
    ALL_TARGET_FILES+=("${TARGET_RULES_ROOT}/${rule_file}")
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

# --- Migrate to hyphenated skills & remove deprecated skills (v0.10.0 → v0.11.0) ---
migrate_to_v0_11_0() {
  local old_skills=(
    "conductor_setup"
    "conductor_newTrack"
    "conductor_newTrack_grill"
    "conductor_newTrack_discovery"
    "conductor_implement"
    "conductor_status"
    "conductor_review"
    "conductor_revert"
    "conductor_chat"
    "conductor"
  )

  local deprecated_found=()
  for old_skill in "${old_skills[@]}"; do
    local old_dir="${TARGET_SKILLS_ROOT}/${old_skill}"
    if [[ -d "$old_dir" ]]; then
      deprecated_found+=("$old_dir")
    fi
  done

  if [[ ${#deprecated_found[@]} -eq 0 ]]; then
    return 0
  fi

  section "🔄 Skill Renaming & Cleanup (v0.11.0)"
  echo ""
  msg_warn "Found ${#deprecated_found[@]} deprecated/underscore skill directory(ies):"
  for d in "${deprecated_found[@]}"; do
    echo -e "     ${DIM}${d}${NC}"
  done
  echo ""

  if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
    for d in "${deprecated_found[@]}"; do
      msg_info "${YELLOW}[dry-run]${NC} Would remove deprecated skill directory: ${CYAN}${d}${NC}"
    done
    return 0
  fi

  for d in "${deprecated_found[@]}"; do
    rm -rf "$d"
    msg_success "Removed deprecated skill directory: ${CYAN}${d}${NC}"
  done
}

# --- Version check ---
check_for_updates() {
  local latest_version="${VERSION}"
  local version_file="${TARGET_SKILLS_ROOT}/conductor-setup/.conductor_version"

  if [[ -f "$version_file" ]]; then
    local installed_version
    installed_version=$(cat "$version_file" 2>/dev/null | tr -d '[:space:]')
    if [[ "$installed_version" == "$latest_version" ]]; then
      msg_success "${WHITE}antigravity${NC}: Up to date (${WHITE}v${installed_version}${NC})"
    else
      echo -e "  ${YELLOW}🆕${NC}  ${WHITE}antigravity${NC}: Update available — ${DIM}v${installed_version}${NC} → ${GREEN}v${latest_version}${NC}"
    fi
  else
    msg_info "No existing Conductor installation found."
  fi
}

# =============================================================================
# Main flow
# =============================================================================

banner

build_target_list

if [[ "${FLAGS_update}" -eq "${FLAGS_TRUE}" ]]; then
  FLAGS_force="${FLAGS_TRUE}"
  version_file="${TARGET_SKILLS_ROOT}/conductor-setup/.conductor_version"
  if [[ -f "$version_file" ]]; then
    installed_version=$(cat "$version_file" 2>/dev/null | tr -d '[:space:]')
    if [[ "$installed_version" == "$VERSION" ]]; then
      msg_success "Already up to date (${WHITE}v${VERSION}${NC})"
      exit 0
    fi
    echo -e "  ${DIM}Installed:${NC} ${WHITE}v${installed_version}${NC}  →  ${GREEN}v${VERSION}${NC}"
  else
    msg_info "No existing installation found. Performing fresh install."
  fi
  echo ""
fi

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

migrate_to_v0_11_0

section "📄 Installing Conductor Templates"
echo ""
install_file "${SOURCE_TEMPLATE_DIR}/workflow_template.md" "${TARGET_TEMPLATE_DIR}/workflow_template.md"
install_file "${SOURCE_TEMPLATE_DIR}/adr_template.md" "${TARGET_TEMPLATE_DIR}/adr_template.md"

if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
  msg_info "${YELLOW}[dry-run]${NC} Would write version file: ${GREEN}.conductor_version${NC}"
else
  mkdir -p "${TARGET_SKILLS_ROOT}/conductor-setup"
  echo "$VERSION" > "${TARGET_SKILLS_ROOT}/conductor-setup/.conductor_version"
  msg_success "Wrote version stamp: ${GREEN}v${VERSION}${NC}"
fi

section "🔧 Installing Conductor Command Skills"
echo ""
for sub_skill in "${SUB_SKILL_NAMES[@]}"; do
  install_file "${SCRIPT_DIR}/skills/${sub_skill}/SKILL.md" "${TARGET_SKILLS_ROOT}/${sub_skill}/SKILL.md"
done

section "📏 Installing Conductor Rules"
echo ""
for rule_file in "${RULE_FILE_NAMES[@]}"; do
  install_file "${SOURCE_RULES_DIR}/${rule_file}" "${TARGET_RULES_ROOT}/${rule_file}"
done

section "📊 Summary"
echo ""
echo -e "  ${DIM}Version:${NC}       ${WHITE}${VERSION}${NC}"
echo -e "  ${DIM}Target:${NC}        ${WHITE}${INSTALL_TARGET}${NC}"
echo -e "  ${DIM}Source:${NC}        ${CYAN}${SCRIPT_DIR}${NC}"
echo -e "  ${DIM}Skills:${NC}        ${CYAN}${TARGET_SKILLS_ROOT}/conductor-*/${NC}"
echo -e "  ${DIM}Rules dir:${NC}     ${CYAN}${TARGET_RULES_ROOT}${NC}"
echo -e "  ${DIM}Files:${NC}         ${WHITE}${#ALL_TARGET_FILES[@]}${NC} total"
echo ""

check_for_updates

if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
  echo -e "  ${YELLOW}🔍 Dry run complete. Re-run without --dry_run to apply changes.${NC}"
else
  echo -e "  ${GREEN}🚀 Installation complete! You're ready to conduct.${NC}"
fi
echo ""
