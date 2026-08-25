# Cervid Ballistics — Claude Project Instructions

This document is for the **custom instructions / knowledge base of a Claude Project**, not for briefing a single chat. It codifies the engineering conventions this codebase has accumulated over many sessions — conventions that otherwise only exist in a given chat's own history and get silently dropped the moment a new conversation starts. `CervidBallistics_ProjectBrief.md` covers *what the app does* (features, architecture); this document covers *how work on it gets done*. Read both before making a change — this one first, since it governs process regardless of which feature is being touched.

If anything below turns out to be wrong or the codebase has moved on, fix this document in the same commit as the code change that made it wrong. A process doc that drifts from reality is worse than no process doc.

---

## The four canonical files, and why they must stay paired

There is one app, shipped as two variants, each duplicated into two locations:

- **Variant A** (full-feature build): `CervidBallistics.html` ≡ `Personal/index.html` — byte-identical.
- **Variant B** (general-release build): `CervidBallistics_GeneralRelease.html` ≡ `index.html` — byte-identical.

`CervidBallistics.html` is the canonical source. Every code change is written there first, verified, and then propagated to the other three. After every edit that touches any of the four, confirm the pairing with:

```
md5sum CervidBallistics.html Personal/index.html
md5sum CervidBallistics_GeneralRelease.html index.html
```

Both pairs must match. If they don't, something was propagated incompletely or a stray edit landed on only one side — do not commit until this is fixed.

The guide file follows the same rule with only one variant: `cervid-guide.html` (root) ≡ `Personal/cervid-guide.html`, verified the same way.

## Propagation workflow

1. Make the change in `CervidBallistics.html` only. Syntax-check it (extract the inline `<script>` blocks and run them through `new Function()`) and smoke-test it before touching anything else.
2. `git diff CervidBallistics.html > /tmp/x.diff`
3. Apply the same diff to the other three files: `patch --fuzz=5 -p1 <target> < /tmp/x.diff` for `CervidBallistics_GeneralRelease.html`, `index.html`, and `Personal/index.html`.
4. Check for `.rej` files after each apply — none should appear. If one does, the target file has drifted from canonical in that region and needs a manual merge, not a forced patch.
5. Delete any `.orig` backup files `patch` leaves behind.
6. Re-verify both md5 pairs, and re-run the syntax check against all four files.
7. Re-run the full test suite (see below) against all four files before committing.

`--fuzz=5` is deliberately generous — line numbers drift between the two variants because General Release lacks some features Variant A has, so hunks land at different offsets. This is expected and fine as long as every hunk reports "succeeded," not "FAILED."

## Testing

Tests are plain Node scripts (not a framework) living in the working/outputs directory, not committed to the git repo. Each one builds a fake DOM by hand — `makeEl()`/`getEl()` stubs for `document.getElementById`, a stub canvas context, a `localStorage` shim — loads the app's inline `<script>` content into a `vm.createContext` sandbox via `vm.runInContext`, sets `sandbox.simpleMode = false`, and then drives the app's own functions directly (`sandbox.calculate()`, `sandbox.renderReticleView()`, etc.), asserting against a small local `check(label, cond, detail)` counter. Run as `node test_x.js "<path-to-html>"`.

When adding a new feature, write a dedicated test file for it (named `test_<feature>.js`) rather than folding assertions into an existing file, and run it against all four canonical files before considering the feature done. After any change, re-run the *entire* existing suite against all four files, not just the new test — regressions in unrelated features have been caught this way more than once (see the `isLive`-branch bug class below).

Two pre-existing test failures are permanently excluded from "the suite is clean" — they predate this workflow discipline and are unrelated to any feature since: `test_chart_energy_smoothing.js` and `test_export_amended_builtins.js`. Do not try to fix these as a side effect of unrelated work; if they ever get fixed, remove them from this exclusion list explicitly.

If a test fails, check which side is wrong before "fixing" anything: it might be the code, or it might be a stale assertion that predates an intentional architecture change (this has happened — see the changelog entry from 2026-08-21 where `test_compare_loads.js` had to be updated because an earlier feature changed how `buildParamsFromPreset()` reads wind, and the old test's assumption about that was never updated to match).

## Design patterns already established — reuse them, don't reinvent

**Auto-suggest / customize / reset.** Any override field that should default to a live or computed value but let the user take control follows this shape: the field mirrors the source value until a `xCustomized` flag latches true (set on user input), after which it stops re-syncing; a "Reset" link (`<a href="#" onclick="...;return false;" style="font-size:11px;color:var(--accent2);">Reset</a>`) clears the latch and re-syncs immediately. Used for Compare's distance override, Compare's wind override, Reticle View's wind override, and Reticle View's velocity override. A fifth instance should look like the first four unless there's a specific reason not to (Compare's per-slot velocity override is that exception — see below).

**Full recompute, never a cheap rescale.** Any control that changes wind or velocity and feeds a displayed trajectory figure must trigger a genuine `computeTrajectory()` call under the new parameters, not a linear scaling of an already-computed row. Both wind's headwind/tailwind component and velocity are physics inputs with second-order effects (on drop and time-of-flight, not just the obvious axis), so a rescale would silently disagree with what Compare or the Results table would show for the same conditions. This has been treated as a hard rule since the Reticle View wind override, and extended to velocity without re-litigating it.

**The `isLive`-branch bug class.** `runCompare()`'s live-matched slot clones `lastResults.params` directly rather than calling `buildParamsFromPreset()`. Any override wired only into `buildParamsFromPreset()` will silently fail to apply to whichever slot is the live-matched one, unless it's also re-injected into that clone. This has bitten both the wind override and the velocity override during development (caught by testing, not by a user report, both times) — when adding any new Compare override, explicitly check both paths.

**Per-slot vs. shared state.** Compare's distance and wind overrides are shared across the whole comparison (one field, applies to every selected load). Compare's velocity override is deliberately per-slot instead, keyed by `compareRefKey(ref)` — a `"mode:type:idx"` string — rather than by column position, because column order reshuffles as slots are toggled on and off. Before building a new per-load Compare feature, decide explicitly which shape it needs; don't default to "shared" just because that's what came first.

**Unit conversion factors**, used consistently everywhere a field needs to convert between the canonical (imperial) internal unit and the metric display unit: wind mph↔kph ×/÷1.60934; distance yd↔m ×/÷0.9144; velocity fps↔m/s ×/÷0.3048.

## Documentation that must stay in sync with code

Three documents get updated alongside a feature, not after the fact as cleanup:

- **`CervidBallistics_ProjectBrief.md`'s Changelog section** — one entry per feature, newest at the top, dated, naming every file touched in the entry's bold lead-in. Voice: explain the user request or observation that prompted the change, the reasoning behind the design chosen (including alternatives considered and rejected, where relevant), what was actually built, what was tested and how many checks passed, and which docs were updated as a result. This is a design-history record, not a terse commit log — a reader should be able to understand *why* a decision was made, not just *what* changed.
- **`cervid-guide.html`** (root + `Personal/`, kept byte-identical via `cp` and `md5sum`) — a user-facing topic per feature, in the relevant numbered section, written for the shooter using the app rather than for a future engineer.
- **`Cervid Ballistics - Mathematical Models and Design Methodology.docx`** — updated **only** for Compare Loads features. Reticle View features have never been documented here (zero mentions, by deliberate precedent) and should stay that way unless that precedent is explicitly revisited. When a Compare feature does need a new section, it goes into Part 3 ("The Compare Loads Feature") as a new numbered `Heading2` section, with all following sections renumbered — including their visible heading text, not just bookmark names, which can stay as-is since they're not user-visible. Cross-reference any in-body "(Section N)" mentions elsewhere in the document that might now be pointing at the wrong section after a renumber.

### Editing the docx

The docx is edited as a zip archive, not through a document-generation library, because existing structure (styles, bookmark IDs, `w14:paraId`s, numbering) must be preserved exactly:

1. Extract with Python's `zipfile` module.
2. Edit `word/document.xml` directly — new body paragraphs use the same `BodyText`/`FirstParagraph` styles as their neighbors; new section headings use `Heading2` with a unique `w:bookmarkStart`/`w:bookmarkEnd` id (check existing ids first, e.g. `grep -o 'w:bookmarkStart w:id="[0-9]*"'`) and a unique `w14:paraId` (8 hex chars, check it isn't already used).
3. Re-zip with `zipfile.ZIP_DEFLATED`, preserving the original file list and order.
4. Verify by rendering to PDF (`soffice --headless --convert-to pdf`) and extracting text with `pdfplumber` — confirm the section numbering reads correctly end-to-end and the new prose rendered without encoding artifacts (curly quotes, em dashes) turning into mojibake.

## Committing and deploying

Commit locally with a message that mirrors the changelog's own level of detail (what changed, why, what was tested) — this environment can commit but **cannot push**. After every commit, remind the user to run `./github_push.sh` from their own Terminal to deploy to `mybc.cervid.net` via GitHub → Netlify.

## Where to start on a new task

1. Read `CervidBallistics_ProjectBrief.md` for what the app currently does (treat its "Features" list as a stable high-level summary, not a changelog — it isn't updated per-feature, and that's intentional).
2. Read this document for how to do the work.
3. Read the actual current code in `CervidBallistics.html` for the feature being touched — the changelog explains *why* past decisions were made, but the code is the only reliable source for *current* exact behavior.
4. If the task touches Compare Loads or Reticle View specifically, skim the most recent changelog entries for those features first — both have accumulated enough incremental refinement (wind overrides, velocity overrides, dial geometry, isLive re-injection) that a new feature almost certainly needs to follow one of the established patterns above rather than inventing a new one.
