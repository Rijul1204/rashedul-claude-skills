#!/usr/bin/env bash
# install.sh — One-shot installer for rashedul-agentic-engineering skills + agents.
#
# Symlinks (or copies) every skill under skills/ and every agent under agents/
# into the target's .claude/ tree. Designed to be run from the repo root.
#
# Usage:
#   ./scripts/install.sh                          # user-scope (~/.claude/), symlink, all categories
#   ./scripts/install.sh --target ~/Projects/foo  # project-scope (<target>/.claude/)
#   ./scripts/install.sh --copy                   # cp -R instead of symlink (snapshot)
#   ./scripts/install.sh --only skills            # install just skills/ (or "agents")
#   ./scripts/install.sh --dry-run                # preview actions, no filesystem changes
#   ./scripts/install.sh --force                  # overwrite existing targets (default: skip with warning)
#   ./scripts/install.sh -h | --help              # show this help
#
# Flags can be combined, e.g.:
#   ./scripts/install.sh --target ~/Projects/foo --only skills --dry-run

set -euo pipefail

TARGET="${HOME}"
MODE="symlink"   # symlink | copy
ONLY="all"       # all | skills | agents
DRY_RUN=0
FORCE=0

print_help() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)   TARGET="$2"; shift 2 ;;
    --copy)     MODE="copy"; shift ;;
    --only)     ONLY="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    --force)    FORCE=1; shift ;;
    -h|--help)  print_help; exit 0 ;;
    *)          echo "error: unknown flag: $1" >&2; print_help >&2; exit 2 ;;
  esac
done

# Sanity-check: we must be running from the repo root (skills/ + agents/ both exist).
if [[ ! -d skills || ! -d agents ]]; then
  echo "error: must run from the repo root (couldn't find skills/ and agents/ in $(pwd))" >&2
  exit 2
fi

if [[ "$ONLY" != "all" && "$ONLY" != "skills" && "$ONLY" != "agents" ]]; then
  echo "error: --only must be 'skills' or 'agents' (got: $ONLY)" >&2
  exit 2
fi

REPO_ROOT="$(pwd)"
TARGET_SKILLS="${TARGET}/.claude/skills"
TARGET_AGENTS="${TARGET}/.claude/agents"

prefix=""
if [[ $DRY_RUN -eq 1 ]]; then
  prefix="[dry-run] "
fi

# Install one item (file or dir) into a target dir.
#   $1: source path (absolute or repo-relative)
#   $2: target directory
install_item() {
  local src="$1"
  local target_dir="$2"
  local name
  name="$(basename "$src")"
  local dest="${target_dir}/${name}"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ $FORCE -eq 1 ]]; then
      echo "${prefix}rm   ${dest}"
      if [[ $DRY_RUN -eq 0 ]]; then
        rm -rf "$dest"
      fi
    else
      echo "${prefix}skip ${dest} (exists; pass --force to overwrite)"
      return 0
    fi
  fi

  if [[ $DRY_RUN -eq 0 ]]; then
    mkdir -p "$target_dir"
  fi

  if [[ "$MODE" == "symlink" ]]; then
    echo "${prefix}ln   ${src} -> ${dest}"
    if [[ $DRY_RUN -eq 0 ]]; then
      ln -s "$src" "$dest"
    fi
  else
    echo "${prefix}cp   ${src} -> ${dest}"
    if [[ $DRY_RUN -eq 0 ]]; then
      cp -R "$src" "$dest"
    fi
  fi
}

# Skills: each direct subdirectory of skills/
if [[ "$ONLY" == "all" || "$ONLY" == "skills" ]]; then
  for dir in "${REPO_ROOT}"/skills/*/; do
    [[ -d "$dir" ]] || continue
    install_item "${dir%/}" "$TARGET_SKILLS"
  done
fi

# Agents: each .md file directly under agents/
if [[ "$ONLY" == "all" || "$ONLY" == "agents" ]]; then
  for file in "${REPO_ROOT}"/agents/*.md; do
    [[ -f "$file" ]] || continue
    install_item "$file" "$TARGET_AGENTS"
  done
fi

echo ""
echo "${prefix}done. target: ${TARGET}/.claude/"
