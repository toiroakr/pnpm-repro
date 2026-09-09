# repro: `pnpm run "/pattern/" --no-bail` kills sibling scripts before they finish (pnpm 12)

`pnpm run "/^check:/" --no-bail` matches two scripts in this single package.json:

- `check:fast-fail` exits 1 after 100ms
- `check:slow-ok` exits 0 after 1000ms

Per pnpm's own docs and https://github.com/pnpm/pnpm/issues/8705 (closed as
"the bail option will meet your needs" -> https://pnpm.io/cli/recursive#--no-bail),
`--no-bail` should let every matched script run to completion regardless of
sibling failures.

## Expected (pnpm 11.x)

Both scripts run to completion; "slow-ok finished" is printed; total time ~1s.

## Actual (pnpm 12.x)

`slow-ok` is killed before its timeout fires; "slow-ok finished" is never
printed; total time ~100-200ms.

## Run it

```sh
pnpm install
time pnpm run --no-bail "/^check:/"
```

Swap the `packageManager` field between `pnpm@12.3.4` and `pnpm@12.3.4` (or
run the corresponding `pnpm/dist/pnpm.cjs` directly) to compare.

## Suspected cause

pnpm 12.1.0's changelog (Patch Changes) says:

> Stop in-flight recursive `run` and `exec` commands when bailing after the
> first failure.

That entry is scoped to *recursive* `run`/`exec` (`pnpm -r run`), and the same
release documents that under `--no-bail`, "tasks whose dependencies failed are
reported as skipped, not failed" (i.e. --no-bail should keep unrelated tasks
running). This repro is a *non-recursive*, single-package.json, pattern-matched
`pnpm run "/pattern/"` (no `-r`) — but it appears to share the same workspace
task-orchestration engine (RFC 23) introduced in 12.1.0, and the "stop
in-flight on bail" logic seems to fire here too even under `--no-bail`,
regressing the documented/expected behavior from #8705.
