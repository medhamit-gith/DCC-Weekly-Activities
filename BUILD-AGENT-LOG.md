# Build Agent Log

Chronological log of DCC Build Agent runs. One line per run: date, ticket, outcome, why.

- 2026-09-10: SCRUM-88 — PR opened (cleanup, not the originally-described fix). Diagnosis: on main@53537ad9, `ActivityRow`/`ActivityDetailView` are already defined once in `RootView.swift` (inside the Xcode file-system-synchronized source group) and match every call site (`JustMyStatsView.swift`, `RootViewTests.swift`, `SampleTests.swift`) — the "types referenced but never committed" premise does not reproduce on a fresh clone of main. Found the likely source of the confusion instead: stray duplicate copies of both types were committed under `DCC-Weekly-Activities.xcodeproj/` (outside any target's synchronized source root per `project.pbxproj`, so never compiled). Removed the two dead files as a small, additive-safe cleanup and flagged the discrepancy to Amit for a call on whether to close SCRUM-88.
