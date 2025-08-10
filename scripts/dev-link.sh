#!/usr/bin/env bash
set -euo pipefail

# Symlink this repo's addon into a WoW AddOns directory for local testing.
# Usage:
#   scripts/dev-link.sh [<AddOns directory>]
# You can also set WOW_ADDONS_DIR env var to point to the AddOns directory.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "${SCRIPT_DIR}/.." && pwd )"
ADDON_NAME="MaxDps_PriorityIcon"
SRC_DIR="${ROOT_DIR}/${ADDON_NAME}"

if [[ ! -d "${SRC_DIR}" ]]; then
  echo "Error: addon source not found at ${SRC_DIR}" >&2
  exit 1
fi

choose_addons_dir() {
  if [[ -n "${1:-}" ]]; then
    echo "$1"; return 0
  fi
  if [[ -n "${WOW_ADDONS_DIR:-}" ]]; then
    echo "${WOW_ADDONS_DIR}"; return 0
  fi
  # Common macOS install locations (Retail/Classic and legacy)
  candidates=(
    "/Applications/World of Warcraft/Interface/AddOns" \
    "/Applications/World of Warcraft/_retail_/Interface/AddOns" \
    "/Applications/World of Warcraft/_classic_/Interface/AddOns" \
    "/Applications/World of Warcraft/_classic_era_/Interface/AddOns" \
    "/Applications/World of Warcraft/_classic_ptr_/Interface/AddOns" \
    "/Applications/World of Warcraft/_retail_/Interface/AddOns"
  )
  for d in "${candidates[@]}"; do
    if [[ -d "$d" ]]; then
      echo "$d"; return 0
    fi
  done
  return 1
}

ADDONS_DIR="$(choose_addons_dir "${1:-}")" || {
  echo "Error: Could not auto-detect WoW AddOns directory." >&2
  echo "Pass it explicitly, e.g.: scripts/dev-link.sh '/Applications/World of Warcraft/Interface/AddOns'" >&2
  echo "Or set WOW_ADDONS_DIR to your AddOns path." >&2
  exit 1
}

TARGET="${ADDONS_DIR}/${ADDON_NAME}"

if [[ -L "${TARGET}" ]]; then
  rm -f "${TARGET}"
elif [[ -e "${TARGET}" ]]; then
  echo "Error: ${TARGET} exists and is not a symlink. Move it aside or remove it first." >&2
  exit 1
fi

ln -s "${SRC_DIR}" "${TARGET}"
echo "Linked: ${SRC_DIR} -> ${TARGET}"
echo "Reload UI in-game with /reload to pick up changes."
