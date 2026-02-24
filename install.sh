#!/bin/bash
# =============================================================================
# Antigravity Conductor Skills & Workflows Installer
# Copies Conductor skill and workflow files to Antigravity directory.
#
# Usage:
#   bash install.sh
#   bash install.sh --dry_run
#   bash install.sh --force
#   bash install.sh --uninstall
#
# Target locations:
#   ~/.gemini/antigravity/skills/conductor/SKILL.md
#   ~/.gemini/antigravity/global_workflows/conductor_*.md
# =============================================================================

FLAGS_TRUE=0
FLAGS_FALSE=1
FLAGS_dry_run=${FLAGS_FALSE}
FLAGS_force=${FLAGS_FALSE}
FLAGS_uninstall=${FLAGS_FALSE}

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
    --help|-h)
      echo "Usage: bash install.sh [OPTIONS]"
      echo "  --dry_run    Preview changes without writing files"
      echo "  --force      Overwrite existing files without backup"
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

VERSION="0.2.0"

# --- Resolve source directory (relative to this script) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILL_DIR="${SCRIPT_DIR}/skills/conductor"
SOURCE_WORKFLOW_DIR="${SCRIPT_DIR}/workflows"

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
  echo -e "${MAGENTA}  ║${NC}  ${DIM}Skills & Workflows for Antigravity${NC}               ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}  ╚══════════════════════════════════════════════════╝${NC}"
  echo ""
}

section() { echo -e "\n${BLUE}━━━${NC} ${BOLD}$*${NC} ${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# --- Validate source files exist ---
validate_sources() {
  local missing=0
  if [[ ! -f "${SOURCE_SKILL_DIR}/SKILL.md" ]]; then
    msg_error "Source not found: ${SOURCE_SKILL_DIR}/SKILL.md"
    ((missing++))
  fi
  for wf in implement newTrack revert review setup status; do
    if [[ ! -f "${SOURCE_WORKFLOW_DIR}/conductor_${wf}.md" ]]; then
      msg_error "Source not found: ${SOURCE_WORKFLOW_DIR}/conductor_${wf}.md"
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
TARGET_SKILL_DIR="${USER_HOME}/.gemini/antigravity/skills/conductor"
TARGET_WORKFLOW_DIR="${USER_HOME}/.gemini/antigravity/global_workflows"

build_target_list() {
  ALL_TARGET_FILES=(
    "${TARGET_SKILL_DIR}/SKILL.md"
    "${TARGET_WORKFLOW_DIR}/conductor_implement.md"
    "${TARGET_WORKFLOW_DIR}/conductor_newTrack.md"
    "${TARGET_WORKFLOW_DIR}/conductor_revert.md"
    "${TARGET_WORKFLOW_DIR}/conductor_review.md"
    "${TARGET_WORKFLOW_DIR}/conductor_setup.md"
    "${TARGET_WORKFLOW_DIR}/conductor_status.md"
  )
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
# Main flow
# =============================================================================

banner
build_target_list

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

  if [[ -d "$TARGET_SKILL_DIR" ]] && [[ -z "$(ls -A "$TARGET_SKILL_DIR" 2>/dev/null)" ]]; then
    if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
      msg_info "${YELLOW}[dry-run]${NC} Would remove empty directory: ${DIM}${TARGET_SKILL_DIR}${NC}"
    else
      rmdir "$TARGET_SKILL_DIR"
      msg_success "Cleaned up empty directory: ${DIM}${TARGET_SKILL_DIR}${NC}"
    fi
  fi

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

# --- Skill ---
section "🧠 Installing Conductor Skill"
echo ""
install_file "${SOURCE_SKILL_DIR}/SKILL.md" "${TARGET_SKILL_DIR}/SKILL.md"

# --- Workflows ---
section "🔧 Installing Conductor Workflows"
echo ""
for wf in implement newTrack revert review setup status; do
  install_file "${SOURCE_WORKFLOW_DIR}/conductor_${wf}.md" "${TARGET_WORKFLOW_DIR}/conductor_${wf}.md"
done

# --- Summary ---
section "📊 Summary"
echo ""
echo -e "  ${DIM}Version:${NC}       ${WHITE}${VERSION}${NC}"
echo -e "  ${DIM}Target:${NC}        ${WHITE}${INSTALL_TARGET}${NC}"
echo -e "  ${DIM}Source:${NC}        ${CYAN}${SCRIPT_DIR}${NC}"
echo -e "  ${DIM}Skill dir:${NC}     ${CYAN}${TARGET_SKILL_DIR}${NC}"
echo -e "  ${DIM}Workflow dir:${NC}  ${CYAN}${TARGET_WORKFLOW_DIR}${NC}"
echo -e "  ${DIM}Files:${NC}         ${WHITE}${#ALL_TARGET_FILES[@]}${NC} total"
echo ""

if [[ "${FLAGS_dry_run}" -eq "${FLAGS_TRUE}" ]]; then
  echo -e "  ${YELLOW}🔍 Dry run complete. Re-run without --dry_run to apply changes.${NC}"
else
  echo -e "  ${GREEN}🚀 Installation complete! You're ready to conduct.${NC}"
fi
echo ""
