#!/usr/bin/env bash
set -euo pipefail

ADDON="MaxDps_PriorityIcon"
TOC="$ADDON/$ADDON.toc"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <version> [changelog line]"; exit 1
fi

VER="$1"; shift || true
CHANGE="${*:-Release $VER}"

# 1) Bump version in .toc (macOS-compatible sed)
sed -i '' -E "s/^(## Version: ).*/\\1${VER}/" "$TOC"

# 2) Zip (clean, reproducible)
ZIP="${ADDON}-${VER}.zip"
rm -f "$ZIP"
zip -r -X "$ZIP" "$ADDON" -x "$ADDON/.git/*" "**/.DS_Store"

# 3) Update CHANGELOG
DATE="$(date +%Y-%m-%d)"
{
  echo "## ${VER} - ${DATE}"
  echo "- ${CHANGE}"
  echo
  cat CHANGELOG.md 2>/dev/null || true
} > CHANGELOG.tmp && mv CHANGELOG.tmp CHANGELOG.md

# 4) Commit and tag (do not add zip; it's ignored)
git add "$TOC" CHANGELOG.md
git commit -m "Release ${VER}: ${CHANGE}"
git tag -a "v${VER}" -m "v${VER}"

echo "Done: $ZIP created, tagged v${VER}"
