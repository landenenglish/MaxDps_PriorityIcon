#!/usr/bin/env bash
set -euo pipefail

# Remove the dev symlink from the WoW AddOns directory.
# Usage:
#   scripts/dev-unlink.sh [<AddOns directory>]
# You can also set WOW_ADDONS_DIR env var to point to the AddOns directory.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "${SCRIPT_DIR}/.." && pwd )"
ADDON_NAME="MaxDps_PriorityIcon"
SRC_DIR="${ROOT_DIR}/${ADDON_NAME}"

choose_addons_dir() {
  if [[ -n "${1:-}" ]]; then
    echo "$1"; return 0
  fi
  if [[ -n "${WOW_ADDONS_DIR:-}" ]]; then
    echo "${WOW_ADDONS_DIR}"; return 0
  fi
  candidates=(
    "/Applications/World of Warcraft/Interface/AddOns" \
    "/Applications/World of Warcraft/_retail_/Interface/AddOns" \
    "/Applications/World of Warcraft/_classic_/Interface/AddOns" \
    "/Applications/World of Warcraft/_classic_era_/Interface/AddOns" \
    "/Applications/World of Warcraft/_classic_ptr_/Interface/AddOns"
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
  exit 1
}

TARGET="${ADDONS_DIR}/${ADDON_NAME}"

if [[ -L "${TARGET}" ]]; then
  rm -f "${TARGET}"
  echo "Unlinked: ${TARGET}"
  # If we have a recorded backup and it still exists, restore it
  LAST_BACKUP_FILE="${ROOT_DIR}/.devlink_last_backup"
  if [[ -f "${LAST_BACKUP_FILE}" ]]; then
    LAST_BACKUP_PATH="$(cat "${LAST_BACKUP_FILE}")"
    if [[ -d "${LAST_BACKUP_PATH}" ]]; then
      mv "${LAST_BACKUP_PATH}" "${TARGET}"
      echo "Restored backup to: ${TARGET}"
      rm -f "${LAST_BACKUP_FILE}" || true
    else
      echo "Note: recorded backup not found at ${LAST_BACKUP_PATH}." >&2
    fi
  fi
else
  echo "Nothing to unlink at ${TARGET} (not a symlink)."
fi
