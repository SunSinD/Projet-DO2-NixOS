# Task Proposals from Codebase Review

## 1) Typo fix task
**Title:** Fix typo in desktop entry name-matching pattern (`Icon Browser`) in menu cleanup script.

**Why:** In `do2-setup-user.sh`, the name-matching case for Icon Browser uses `con...rowser` instead of `icon...browser`, making the match brittle and likely ineffective.

**Proposed change:** Update the pattern to correctly match `Icon Browser` variants (case-insensitive style used elsewhere), then verify the launcher is hidden as intended.

**Acceptance criteria:**
- Pattern matches desktop names containing `Icon Browser`.
- The related app is hidden after running setup.

---

## 2) Bug fix task
**Title:** Avoid misleading script source comment in installer header.

**Why:** `do2-install.sh` says it is "downloaded by install.sh", but the documented one-liner in `README.md` downloads `do2`, not `install.sh`. This can mislead maintainers when debugging install flow.

**Proposed change:** Update the installer header comment so it matches the real bootstrap path (`do2` -> `do2-install.sh`) or explicitly mention both supported bootstraps.

**Acceptance criteria:**
- Installer comment reflects actual supported entry points.
- README install path and installer header are consistent.

---

## 3) Comment/documentation discrepancy task
**Title:** Reconcile default username documentation mismatch between README and user guide.

**Why:** `README.md` documents default username `user`, while `guides/Guide-DO2.html` says the default username is `Utilisateur`.

**Proposed change:** Decide the canonical default username and update both docs accordingly.

**Acceptance criteria:**
- All user-facing docs show the same default username/password pair.
- A quick grep for default credentials returns consistent values.

---

## 4) Test improvement task
**Title:** Add automated regression tests for menu cleanup classification rules.

**Why:** `do2-setup-user.sh` has rule-heavy logic (hide/move decisions based on names and categories) but no automated tests, making regressions easy when patterns change.

**Proposed change:** Extract classification logic into testable functions and add shell tests (e.g., Bats) for:
- known apps to hide,
- allowed categories to keep,
- disallowed categories moved to Office,
- the `Icon Browser` hide rule.

**Acceptance criteria:**
- Test suite runs in CI/local and covers representative desktop-entry fixtures.
- A typo in a hide pattern causes a failing test.
