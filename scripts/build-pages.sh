#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"
BEND2_DIR="${BEND2_DIR:-}"
BEND2_REPO="${BEND2_REPO:-https://github.com/HigherOrderCO/bend2.git}"
BEND2_REF="${BEND2_REF:-90633f663e90f6e6955975a36ed24e3be40bef09}"

cleanup() {
  if [[ -n "${TMP_BEND2_DIR:-}" && -d "${TMP_BEND2_DIR}" ]]; then
    rm -rf "${TMP_BEND2_DIR}"
  fi
}

trap cleanup EXIT

if [[ -z "$BEND2_DIR" ]]; then
  TMP_BEND2_DIR="$(mktemp -d)"
  git clone "$BEND2_REPO" "$TMP_BEND2_DIR"
  git -C "$TMP_BEND2_DIR" checkout "$BEND2_REF"
  BEND2_DIR="$TMP_BEND2_DIR"
fi

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

bun run "$BEND2_DIR/bend-ts/src/CLI.ts" "$ROOT_DIR/src/chess_line/main.bend" --to-web > "$OUT_DIR/index.html"
cp -R "$ROOT_DIR/src/chess_line/assets" "$OUT_DIR/assets"
touch "$OUT_DIR/.nojekyll"

printf 'Built %s\n' "$OUT_DIR/index.html"
