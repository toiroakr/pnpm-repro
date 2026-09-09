# repro: `minimumReleaseAgeExcludePrune` doesn't prune a stale `minimumReleaseAgeExclude` entry after a real resolved -> unresolved transition (pnpm 12)

`pnpm-workspace.yaml` has:

```yaml
minimumReleaseAge: 4320
minimumReleaseAgeExcludePrune: true
minimumReleaseAgeExclude:
  - is-odd@3.0.1 || 2.0.0
```

`package.json` depends on `is-odd@2.0.0`, which `pnpm install` actually
resolves (`is-odd@2.0.0` and its dependency `is-number@4.0.0` are real entries
in `pnpm-lock.yaml`, not a hypothetical/never-resolved exclude candidate).
`package.json` is then changed to depend on `is-odd@3.0.1` only, and
`pnpm install`/`pnpm dedupe` are run again with
`--config.minimum-release-age-exclude-prune=true`. After that, `is-odd@2.0.0`
and `is-number@4.0.0` are completely gone from `pnpm-lock.yaml` — nothing in
the project resolves that version anymore.

Per the pnpm team's own description of the feature
(https://github.com/pnpm/pnpm/issues/14424#issuecomment-5496121426, and
https://github.com/pnpm/pnpm/pull/13653), `minimumReleaseAgeExcludePrune` is
resolution-based: an exclude entry is dropped once the freshly-written
lockfile no longer resolves that version anywhere. That's exactly what
happened here — is-odd@2.0.0 is provably unresolved — so at minimum the
`2.0.0` member of the `is-odd@3.0.1 || 2.0.0` disjunction should be pruned.
(`is-odd@3.0.1` was released in 2018, far older than the 3-day
`minimumReleaseAge` here, so it was never actually blocked by the age policy
either — an accurate prune drops the whole entry, see "Expected" below.)

This isn't https://github.com/pnpm/pnpm/issues/14424 (closed: that report's
version was still resolved transitively through another dependency,
`better-call`'s peer dep — see the reporter's own confirmation at
https://github.com/pnpm/pnpm/issues/14424#issuecomment-5496559720 — not the
case here, see the `pnpm-lock.yaml` check in `repro.sh`'s output) and it isn't
https://github.com/pnpm/pnpm/issues/14612 (open: that's about
`sharedWorkspaceLockfile: false` in a multi-project workspace; this repro has
no `packages:` field and `sharedWorkspaceLockfile` at its default `true`).

## Expected (pnpm 11.22.0, TS CLI)

By the end of `repro.sh`'s two steps, `minimumReleaseAgeExclude` is gone
entirely — `is-odd@2.0.0` is pruned as unresolved, and `is-odd@3.0.1` is
pruned too since it was never actually within the `minimumReleaseAge` window:

```yaml
minimumReleaseAge: 4320
minimumReleaseAgeExcludePrune: true
```

## Actual (pnpm 12.3.4, Rust CLI)

Neither `install` nor the follow-up `dedupe` prunes it — `pnpm-workspace.yaml`
is untouched:

```yaml
minimumReleaseAgeExclude:
  - is-odd@3.0.1 || 2.0.0
```

even though `pnpm-lock.yaml` proves `is-odd@2.0.0` is no longer resolved
anywhere. Reproduces identically with an unrelated, non-deprecated package
(`ms@2.0.0` -> `ms@2.1.3`), so it isn't specific to `is-odd`.

## Run it

`package.json` intentionally has no `packageManager` field: pnpm's
self-managed-version-switching reads that field and silently re-execs as the
pinned version, even when you explicitly invoke a different one (e.g. via
`npx pnpm@11.22.0`) — which would defeat the version comparison below.

Put the pnpm version you want to test on `PATH`, then:

```sh
./repro.sh
```

To test pnpm 12.3.4: `npm install -g pnpm@12.3.4` (or any wrapper that puts
`pnpm@12.3.4` first on `PATH`).

To compare against the expected pnpm 11.22.0 behavior, install that version
instead (`npm install -g pnpm@11.22.0`) and run `./repro.sh` again.

## Suspected cause

pnpm 12's core is a full Rust reimplementation (the CLI is not the historical
TypeScript one anymore). `minimumReleaseAgeExcludePrune` was added in 13653
against the TS implementation; the Rust port's post-install prune pass
appears not to match it for this case. See
https://github.com/pnpm/pnpm/issues/13322 for other TS/Rust parity gaps found
in the v12 rewrite (unrelated to this feature, but same class of issue).
