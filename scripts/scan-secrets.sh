#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"

PATTERN='(sk-[a-zA-Z0-9]{20,}|sk_live_[a-zA-Z0-9]+|sk_test_[a-zA-Z0-9]+|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|glpat-[a-zA-Z0-9_-]+|AKIA[A-Z0-9]{16}|xox[baprs]-[a-zA-Z0-9-]+|-----BEGIN.*PRIVATE KEY|eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.)'

TARGETS=(
  "$ROOT_DIR/.planning"
  "$ROOT_DIR/README.md"
  "$ROOT_DIR/AGENTS.md"
  "$ROOT_DIR/idea.md"
)

MATCHES="$(grep -RInE --include='*.md' "$PATTERN" "${TARGETS[@]}" 2>/dev/null || true)"

if [ -n "$MATCHES" ]; then
  echo "Potential secret-like patterns found:"
  echo "$MATCHES"
  exit 1
fi

echo "No potential secrets found in planning/docs targets."
