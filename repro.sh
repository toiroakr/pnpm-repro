#!/usr/bin/env bash
# Reproduces both steps end to end against whatever `pnpm` is on PATH.
# Run with pnpm 11.22.0+ to see the expected (working) behavior, and with
# pnpm 12.x to see the regression.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf node_modules pnpm-lock.yaml
git checkout -- package.json pnpm-workspace.yaml

echo "== pnpm --version =="
pnpm --version

echo "== step 1: install is-odd@2.0.0 (a real resolution, not a hypothetical exclude entry) =="
cp package.step1.json package.json
pnpm install --no-frozen-lockfile

echo "== step 2: switch to is-odd@3.0.1 only, then install+dedupe with the prune flag =="
git checkout -- package.json
pnpm install --no-frozen-lockfile --ignore-scripts --config.minimum-release-age-exclude-prune=true
pnpm dedupe --ignore-scripts --config.minimum-release-age-exclude-prune=true

echo
echo "== pnpm-workspace.yaml after both steps =="
cat pnpm-workspace.yaml
echo
echo "== is-odd@2.0.0 still resolved anywhere in pnpm-lock.yaml? =="
if grep -q "is-odd@2.0.0" pnpm-lock.yaml; then
  echo "yes -- still referenced"
else
  echo "no -- fully gone, confirms nothing still needs it"
fi
