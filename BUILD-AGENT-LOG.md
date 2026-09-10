# DCC Build Agent Log

Append-only log of DCC Build Agent runs against this repo.

## 2026-09-10 — SCRUM-87 — PR opened

Fixed two confirmed non-cycling icon instances (`figure.run`) in non-protected
files: `GlassComponents.swift` (`GlassMemberCard` ride-count badge) and
`MemberStatsChartView.swift` (`MemberDetailView` "Activities" stat card), both
now `figure.outdoor.cycle`.

Also found, but did **not** fix (protected file `RootView.swift`, needs
approval): line ~1523 `Label("Club Total", systemImage: "figure.2.and.child.holdinghands")`
and line ~1938 the Activities tab item still using `figure.run`.

Separately: found that this ticket's own Jira history (comments dated 2026-08-21
and 2026-08-26) references commits `bfd92e3` and `e58c5d0` that do not exist
anywhere in this repository (verified directly against GitHub — not on `main`,
not on any branch). The fixes those comments describe were never actually
applied. Same pattern independently confirmed on SCRUM-74 (target file
`FeatureRequestView.swift` does not exist in the repo at all) and SCRUM-85
(claimed commits `dc42be2`/`4f1f6da` don't exist; `BiometricAuth.swift` has no
single-flight guard as claimed). Flagged to Amit directly — see email.

## 2026-09-10 — SCRUM-91 — escalated, no code change

PRODUCTION OUTAGE (Strava club endpoints deprecated 1 Sep 2026). Root cause
requires Amit to request Strava Extended Access + written display permission
(Client ID 161984) before any migration code can be written. Confirmed the
dcc-strava Cloudflare Worker source isn't in any of the three DCC repos this
routine has access to, so the 1 Sep deprecation diagnosis couldn't be
independently verified against Worker logs (no Cloudflare grant). Commented
on SCRUM-91, notified Amit. PR #3 logs this outcome only (no product code).

## 2026-09-10 — SCRUM-88 — PR opened (see PR #2)

Ticket's premise (missing/uncommitted `ActivityDetailView.swift`) doesn't
reproduce on current `main` — `ActivityRow`/`ActivityDetailView` are already
defined once in `RootView.swift` and match every call site. Found two stale
duplicate copies of both types committed under `DCC-Weekly-Activities.xcodeproj/`
(outside any build target's synchronized source group) and removed them as a
small cleanup. Not build-verified (no Xcode/simulator in this environment).
