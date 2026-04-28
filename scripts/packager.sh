#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Starte Prüfungen..."

ADDON_NAME=""
REPO_NAME=$(basename $(git rev-parse --show-toplevel))

PACKAGER_REPO="https://github.com/BigWigsMods/packager.git"
PACKAGER_DIR="vendor/packager"

GAME=""
VERSION=""
LAST_RELEASE_VERSION=""
RELEASE_CF=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --game) GAME="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --last-release-version) LAST_RELEASE_VERSION="$2"; shift 2 ;;
    *) echo "⚠️ Unbekanntes Argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$VERSION" || -z "$LAST_RELEASE_VERSION" ]]; then
  echo "⚠️ Benötigt: --version und --last-version"
  exit 99
fi

TOC_FILE=".release/config/pkgmeta.yaml"
MAPPING_FILE=".release/config/release.ini"
SECTION_FOUND=false

while IFS= read -r line; do
  case "$line" in
    "[global]") SECTION_FOUND=true ;;
    \[*]) SECTION_FOUND=false ;;
  esac

  if $SECTION_FOUND && [[ "$line" =~ ^name[[:space:]]*=[[:space:]]*(.*) ]]; then
    ADDON_NAME="${BASH_REMATCH[1]}"
    break
  fi
done < "$MAPPING_FILE"

if [[ ! -f "${TOC_FILE}" ]]; then
  echo "⚠️ TOC-Datei fehlt: ${TOC_FILE}"
  exit 99
fi

if [[ -f CHANGELOG.md ]]; then
  if [[ "${LAST_RELEASE_VERSION}" == "None" ]]; then
    link="https://github.com/wow-addon-dev/${REPO_NAME}/commits/${VERSION}"
  else
    link="https://github.com/wow-addon-dev/${REPO_NAME}/compare/${LAST_RELEASE_VERSION}...${VERSION}"
  fi

  sed -i "s|@full-changelog@|${link}|g" CHANGELOG.md
else
  echo "⚠️ CHANGELOG.md nicht gefunden."
  exit 99
fi

ZIP_NAME="${ADDON_NAME}-${VERSION}"
VERSION_NAME="${VERSION}"

CMD=(
  bash "$PACKAGER_DIR/release.sh"
  -m "${TOC_FILE}"
  -n "${ZIP_NAME}:${VERSION_NAME}{nolib}"
  -p "$CF_PROJECT_ID"
)

echo "🚀 Klone BigWigs-Packager..."
git clone --depth 1 --branch master "$PACKAGER_REPO" "$PACKAGER_DIR"

echo "📦 Starte Packaging: ${CMD[*]}"
"${CMD[@]}"

echo "✅ Packaging abgeschlossen."
