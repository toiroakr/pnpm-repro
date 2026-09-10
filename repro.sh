#!/usr/bin/env bash
# Reproduces the bug end to end against whatever `pnpm` is on PATH, and
# fails (exit 1) exactly when the bug reproduces. `package.json`
# intentionally has no `packageManager` field: pnpm's self-managed-version-
# switching would otherwise silently re-exec as that pinned version
# regardless of what's on PATH, defeating a version comparison.
set -uo pipefail
cd "$(dirname "$0")"

rm -rf node_modules pnpm-lock.yaml

echo "== pnpm --version =="
pnpm --version

pnpm install --no-frozen-lockfile

echo
echo "== time pnpm run --no-bail \"/^check:/\" =="
OUTPUT=$(time pnpm run --no-bail "/^check:/" 2>&1)
echo "$OUTPUT"

echo
if echo "$OUTPUT" | grep -q "check:slow-ok: slow-ok finished"; then
  echo "OK: check:slow-ok ran to completion as expected"
else
  echo "FAIL: check:slow-ok was killed before finishing (pnpm 12 bug reproduced)"
  exit 1
fi
