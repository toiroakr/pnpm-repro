# pnpm bug repros

Minimal reproductions for pnpm regressions/bugs, one case per branch.

- [`no-bail`](https://github.com/toiroakr/pnpm-repro/tree/no-bail) —
  `pnpm run "/pattern/" --no-bail` kills sibling scripts before they finish
  (regression vs pnpm/pnpm#8705). Filed as
  [pnpm/pnpm#14718](https://github.com/pnpm/pnpm/issues/14718).
- [`exclude-prune`](https://github.com/toiroakr/pnpm-repro/tree/exclude-prune) —
  `minimumReleaseAgeExcludePrune` doesn't prune a stale
  `minimumReleaseAgeExclude` entry after a real resolved -> unresolved
  transition. Filed as
  [pnpm/pnpm#14759](https://github.com/pnpm/pnpm/issues/14759).

Each branch is self-contained: check it out and follow its own README. Each
case also has a matching workflow under `.github/workflows/` that runs its
`repro.sh` against a pnpm-version matrix on every push to `main`, so the
Actions tab shows the regression directly (green on a fixed version, red on
a buggy one).
