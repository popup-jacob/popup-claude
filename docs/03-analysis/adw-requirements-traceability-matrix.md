# ADW Improvement - Requirements Traceability Matrix

> **Summary**: Comprehensive traceability matrix for all 44 functional requirements from adw-improvement.plan.md
>
> **Project**: popup-claude (AI-Driven Work Installer)
> **Author**: Gap Detector Agent
> **Created**: 2026-02-12
> **Last Modified**: 2026-02-12
> **Status**: Draft
> **Reference Plan**: `docs/01-plan/features/adw-improvement.plan.md`

---

## 0. Requirement Count Verification

The plan document contains **44 functional requirements** (not 46 as initially estimated):

| Sprint | Range | Count |
|--------|-------|:-----:|
| Sprint 1 | FR-S1-01 ~ FR-S1-10 | 10 |
| Sprint 2 | FR-S2-01 ~ FR-S2-10 | 10 |
| Sprint 3 | FR-S3-01 ~ FR-S3-08 | 8 |
| Sprint 4 | FR-S4-01 ~ FR-S4-10 | 10 |
| Sprint 5 | FR-S5-01 ~ FR-S5-06 | 6 |
| **Total** | | **44** |

---

## 1. Full Requirements Traceability Matrix

### Sprint 1 -- Critical Security (Immediate)

| # | ID | Description | Priority | Target Files | Complexity | Dependencies | Status |
|:-:|:---|:-----------|:--------:|:------------|:----------:|:-------------|:------:|
| 1 | FR-S1-01 | OAuth state parameter -- add CSRF state token to `generateAuthUrl()` and validate in callback | Critical | `oauth.ts:113-118` | Medium | None | Pending |
| 2 | FR-S1-02 | Drive API query escaping -- escape single quotes in `drive_search`, `drive_list` user input | Critical | `drive.ts:18,59` | Simple | None | Pending |
| 3 | FR-S1-03 | osascript template injection -- replace backtick interpolation with stdin pipe in `parse_json()` | Critical | `install.sh:29-39` | Medium | Merges with FR-S2-01 | Pending |
| 4 | FR-S1-04 | Atlassian API token security -- move plaintext token from `.mcp.json` to env var reference | High | `atlassian/install.sh:147-172` | Medium | None | Pending |
| 5 | FR-S1-05 | Figma token security -- ensure env var reference works in `module.json`, install script creates `.env` | Low | `figma/module.json:24`, `figma/install.sh` | Simple | None (downgraded to Informational) | Pending |
| 6 | FR-S1-06 | Docker non-root user -- add `addgroup`/`adduser` + `USER app` to Dockerfile | High | `google-workspace-mcp/Dockerfile` | Simple | None | Pending |
| 7 | FR-S1-07 | token.json file permissions -- add `fs.chmodSync(TOKEN_PATH, 0o600)` after `writeFileSync` | High | `oauth.ts:105-108` | Simple | None | Pending |
| 8 | FR-S1-08 | Config directory permissions -- set `mode: 0o700` in `ensureConfigDir()` mkdirSync | High | `oauth.ts:51-55` | Simple | None | Pending |
| 9 | FR-S1-09 | Atlassian install.sh variable escaping -- pass user input via env vars to Node.js `-e` blocks | High | `atlassian/install.sh:147-172` | Medium | FR-S1-04 (same file) | Pending |
| 10 | FR-S1-10 | Gmail email header injection -- strip `\r\n` from `to`, `cc`, `bcc` fields in `gmail_send` | Medium | `gmail.ts` (send handler) | Simple | None | Pending |

### Sprint 2 -- Platform & Stability (Within 1 Week)

| # | ID | Description | Priority | Target Files | Complexity | Dependencies | Status |
|:-:|:---|:-----------|:--------:|:------------|:----------:|:-------------|:------:|
| 11 | FR-S2-01 | Cross-platform JSON parser -- reimplement `parse_json()` with node/python3/osascript fallback chain | Critical | `install.sh:29-39` | Complex | Absorbs FR-S1-03 | Pending |
| 12 | FR-S2-02 | Remote execution shared script download -- download `oauth-helper.sh` to temp dir before module run | High | `install.sh:346-352`, `notion/install.sh:54`, `figma/install.sh:58` | Complex | None | Pending |
| 13 | FR-S2-03 | MCP config path unification -- change Mac/Linux to `~/.claude/mcp.json` (3 files) | High | `install.sh:406`, `google/install.sh:328`, `atlassian/install.sh:145` | Medium | Risk R-01 (user config loss) | Pending |
| 14 | FR-S2-04 | Linux package manager expansion -- add `dnf` (Fedora/RHEL) and `pacman` (Arch) detection | Medium | `base/install.sh:46-49, 88-93` | Medium | FR-S2-01 (Linux must work first) | Pending |
| 15 | FR-S2-05 | Figma module.json fix -- change `type` to `remote-mcp`, set `requirements.node: false` | Medium | `figma/module.json` | Simple | None | Pending |
| 16 | FR-S2-06 | Atlassian module.json Docker fix -- set `docker: "optional"` or add `modes` field | Medium | `atlassian/module.json:15` | Simple | None | Pending |
| 17 | FR-S2-07 | Module execution order sorting -- sort `SELECTED_MODULES` by `MODULE_ORDERS` array | Low | `install.sh:376` | Medium | None | Pending |
| 18 | FR-S2-08 | Docker wait timeout -- add 300s timeout wrapper to `docker wait` in google install | Low | `google/install.sh:315` | Simple | None | Pending |
| 19 | FR-S2-09 | Python 3 dependency declaration -- add `requirements.python3: true` to Notion/Figma module.json | Medium | `notion/module.json`, `figma/module.json` | Simple | FR-S2-05 (Figma module.json) | Pending |
| 20 | FR-S2-10 | Windows admin privilege conditional -- skip admin elevation for non-base modules | Medium | `install.ps1:130-153` | Medium | None | Pending |

### Sprint 3 -- Quality & Testing (Within 2 Weeks)

| # | ID | Description | Priority | Target Files | Complexity | Dependencies | Status |
|:-:|:---|:-----------|:--------:|:------------|:----------:|:-------------|:------:|
| 21 | FR-S3-01 | Google MCP unit tests -- introduce Vitest, write tests for all tool files, target 60%+ coverage | Critical | `google-workspace-mcp/` (new) | Complex | FR-S1-* (security fixes first) | Pending |
| 22 | FR-S3-02 | Installer smoke tests -- Bash-based test scripts for module.json parsing and basic execution | High | `installer/tests/` (new) | Complex | FR-S2-* (platform fixes first) | Pending |
| 23 | FR-S3-03 | CI auto-trigger -- add push/PR triggered workflow for build + unit tests + smoke tests | High | `.github/workflows/test-installer.yml` | Medium | FR-S3-01, FR-S3-02 | Pending |
| 24 | FR-S3-04 | CI test scope expansion -- add google, atlassian modules to CI test targets | Medium | `.github/workflows/test-installer.yml:17-22` | Simple | FR-S3-03 | Pending |
| 25 | FR-S3-05 | Shared utility modularization -- extract color definitions, Docker check, MCP config update to `shared/` | Medium | `installer/modules/shared/` | Medium | None | Pending |
| 26 | FR-S3-06 | ESLint + Prettier setup -- add linter/formatter config to Google MCP TypeScript project | Low | `google-workspace-mcp/` (new) | Simple | None | Pending |
| 27 | FR-S3-07 | Remove `any` types -- replace `async (params: any)` with proper types in `index.ts:32` | Low | `google-workspace-mcp/src/index.ts:32` | Simple | None | Pending |
| 28 | FR-S3-08 | Error message English unification -- convert Korean error messages to English | Low | `index.ts:48`, `oauth.ts` | Simple | None | Pending |

### Sprint 4 -- Google MCP Hardening (Within 3 Weeks)

| # | ID | Description | Priority | Target Files | Complexity | Dependencies | Status |
|:-:|:---|:-----------|:--------:|:------------|:----------:|:-------------|:------:|
| 29 | FR-S4-01 | Google API rate limiting -- exponential backoff retry for 429/503 (max 3 retries, 1s/2s/4s) | High | `google-workspace-mcp/src/tools/*.ts` | Complex | None | Pending |
| 30 | FR-S4-02 | OAuth scope dynamic config -- `GOOGLE_SCOPES` env var for selective scope request | High | `oauth.ts:17-25` | Medium | FR-S1-01 (OAuth changes) | Pending |
| 31 | FR-S4-03 | Calendar timezone dynamic -- replace hardcoded `Asia/Seoul` with `Intl` API + `TIMEZONE` env var | High | `calendar.ts:161,170,175` | Simple | None | Pending |
| 32 | FR-S4-04 | getGoogleServices() singleton/caching -- module-level auth client and service instance caching | Medium | `oauth.ts:227-238` | Medium | FR-S4-05, FR-S4-06 (auth changes) | Pending |
| 33 | FR-S4-05 | Token refresh_token validation -- check `refresh_token` presence in `loadToken()`, prompt re-auth if missing | Medium | `oauth.ts:196-211` | Medium | None | Pending |
| 34 | FR-S4-06 | Concurrent auth request handling -- mutex/semaphore to prevent race conditions in auth flow | Medium | `oauth.ts:113-182` | Complex | FR-S4-04 (caching interaction) | Pending |
| 35 | FR-S4-07 | Gmail nested MIME parsing -- recursive `parts` traversal for multipart email body extraction | Medium | `gmail.ts:70-75` | Medium | None | Pending |
| 36 | FR-S4-08 | Gmail attachment download fix -- remove 1000-char truncation, return full base64 with size limit option | Low | `gmail.ts:358` | Medium | FR-S4-07 (MIME parsing) | Pending |
| 37 | FR-S4-09 | Node.js 22 migration -- update Dockerfile `node:20-slim` to `node:22-slim` | Medium | `Dockerfile` | Simple | FR-S1-06 (Dockerfile changes) | Pending |
| 38 | FR-S4-10 | .dockerignore addition -- exclude `.google-workspace/`, `node_modules/`, `.git/` from build context | Low | `google-workspace-mcp/` (new) | Simple | None | Pending |

### Sprint 5 -- UX & Documentation (Within 1 Month)

| # | ID | Description | Priority | Target Files | Complexity | Dependencies | Status |
|:-:|:---|:-----------|:--------:|:------------|:----------:|:-------------|:------:|
| 39 | FR-S5-01 | Post-install auto-verification -- MCP server health check after each module install, guidance on failure | High | `install.sh` (completion section) | Complex | FR-S2-01, FR-S2-03 (installer changes) | Pending |
| 40 | FR-S5-02 | Rollback mechanism -- backup `.mcp.json` before install, restore on failure | Medium | `install.sh` | Medium | FR-S2-03 (MCP path unification) | Pending |
| 41 | FR-S5-03 | ARCHITECTURE.md sync -- add Pencil module, Remote MCP type, `shared/` directory | Low | `installer/ARCHITECTURE.md` | Simple | FR-S3-05 (shared/ created) | Pending |
| 42 | FR-S5-04 | package.json version update -- `0.1.0` to `1.0.0` (SemVer for production) | Low | `google-workspace-mcp/package.json:3` | Simple | None | Pending |
| 43 | FR-S5-05 | Google MCP tool message English -- unify all tool descriptions and response messages to English | Low | `google-workspace-mcp/src/tools/*.ts` | Medium | FR-S3-08 (error messages) | Pending |
| 44 | FR-S5-06 | .gitignore reinforcement -- add `client_secret.json` pattern, `.env` file patterns | Medium | `.gitignore` | Simple | None | Pending |

---

## 2. Priority Distribution Summary

| Priority | Count | Percentage | Sprint Distribution |
|----------|:-----:|:----------:|:--------------------|
| Critical | 5 | 11.4% | S1: 3, S2: 1, S3: 1 |
| High | 15 | 34.1% | S1: 5, S2: 2, S3: 2, S4: 3, S5: 1 |
| Medium | 15 | 34.1% | S1: 1, S2: 4, S3: 2, S4: 4, S5: 2 |
| Low | 9 | 20.5% | S1: 1, S2: 2, S3: 3, S4: 2, S5: 3 |

---

## 3. Complexity Distribution Summary

| Complexity | Count | Percentage | Effort Indicator |
|------------|:-----:|:----------:|:----------------:|
| Simple | 19 | 43.2% | 1-2h each |
| Medium | 16 | 36.4% | 2-6h each |
| Complex | 9 | 20.5% | 6-16h each |

---

## 4. Critical Path Analysis

### 4.1 Critical Path Requirements (Blocking Others)

These requirements are on the critical path -- delays here cascade to dependent requirements.

```
CRITICAL PATH:

FR-S1-03 ──> FR-S2-01 ──> FR-S2-04 ──> FR-S5-01
(osascript     (cross-       (Linux        (post-install
 injection)     platform)     packages)     verification)

FR-S1-01 ──> FR-S4-02
(OAuth state)  (dynamic scopes)

FR-S3-01 ──> FR-S3-03 ──> FR-S3-04
(unit tests)   (CI auto)    (CI scope)

FR-S2-03 ──> FR-S5-02
(MCP path)    (rollback)

FR-S3-05 ──> FR-S5-03
(shared/)     (ARCH.md sync)

FR-S1-06 ──> FR-S4-09
(Dockerfile   (Node 22
 non-root)     migration)
```

### 4.2 Critical Path Table

| Rank | ID | Blocks | Blocked Items | Risk if Delayed |
|:----:|:---|:------:|:-------------|:----------------|
| 1 | FR-S1-03 | 1 | FR-S2-01 | Entire Linux support chain blocked |
| 2 | FR-S2-01 | 2 | FR-S2-04, FR-S5-01 | Linux unusable, no post-install verification |
| 3 | FR-S3-01 | 2 | FR-S3-03, FR-S3-04 | No automated quality gate |
| 4 | FR-S1-01 | 1 | FR-S4-02 | OAuth security incomplete |
| 5 | FR-S2-03 | 1 | FR-S5-02 | Rollback targets wrong config path |
| 6 | FR-S3-03 | 1 | FR-S3-04 | CI scope expansion impossible |
| 7 | FR-S3-05 | 1 | FR-S5-03 | Documentation references nonexistent structure |
| 8 | FR-S1-06 | 1 | FR-S4-09 | Node 22 migration on root container |

### 4.3 Parallel-Executable Requirements

Requirements within the same sprint that have NO mutual dependencies and CAN be worked on simultaneously.

**Sprint 1 Parallel Groups:**

| Group | Requirements | Can Run In Parallel |
|:-----:|:-------------|:-------------------:|
| S1-WP1 | FR-S1-01, FR-S1-08 | Yes (oauth.ts different sections) |
| S1-WP2 | FR-S1-02, FR-S1-03, FR-S1-10 | Yes (drive.ts, install.sh, gmail.ts) |
| S1-WP3 | FR-S1-04, FR-S1-05, FR-S1-06, FR-S1-07 | Yes (all different files) |
| S1-Serial | FR-S1-09 | After FR-S1-04 (same file region) |

**Sprint 2 Parallel Groups:**

| Group | Requirements | Can Run In Parallel |
|:-----:|:-------------|:-------------------:|
| S2-WP1 | FR-S2-01, FR-S2-10 | Yes (install.sh vs install.ps1) |
| S2-WP2 | FR-S2-05, FR-S2-06 | Yes (figma/module.json vs atlassian/module.json) |
| S2-WP3 | FR-S2-02, FR-S2-08 | Yes (different installer sections) |
| S2-Serial | FR-S2-03 | Can parallel with WP1, WP2; different file sections |
| S2-Serial | FR-S2-04 | After FR-S2-01 (depends on Linux parse_json) |
| S2-Serial | FR-S2-07 | Independent, can parallel with any |
| S2-Serial | FR-S2-09 | After FR-S2-05 (shares figma/module.json) |

**Sprint 3 Parallel Groups:**

| Group | Requirements | Can Run In Parallel |
|:-----:|:-------------|:-------------------:|
| S3-WP1 | FR-S3-01, FR-S3-02, FR-S3-06 | Yes (different directories) |
| S3-WP2 | FR-S3-05 | Independent |
| S3-WP3 | FR-S3-07, FR-S3-08 | Yes (different files) |
| S3-Serial | FR-S3-03 | After FR-S3-01 + FR-S3-02 |
| S3-Serial | FR-S3-04 | After FR-S3-03 |

**Sprint 4 Parallel Groups:**

| Group | Requirements | Can Run In Parallel |
|:-----:|:-------------|:-------------------:|
| S4-WP1 | FR-S4-01, FR-S4-03, FR-S4-07 | Yes (tools/*.ts different files) |
| S4-WP2 | FR-S4-02, FR-S4-05 | Yes (different oauth.ts sections) |
| S4-WP3 | FR-S4-09, FR-S4-10 | Yes (Dockerfile vs .dockerignore) |
| S4-Serial | FR-S4-04 | After FR-S4-05, FR-S4-06 |
| S4-Serial | FR-S4-06 | Can parallel with WP1; coordinates with FR-S4-04 |
| S4-Serial | FR-S4-08 | After FR-S4-07 (MIME parsing dependency) |

**Sprint 5 Parallel Groups:**

| Group | Requirements | Can Run In Parallel |
|:-----:|:-------------|:-------------------:|
| S5-WP1 | FR-S5-04, FR-S5-05, FR-S5-06 | Yes (all different files) |
| S5-WP2 | FR-S5-03 | After FR-S3-05 |
| S5-Serial | FR-S5-01 | After FR-S2-01, FR-S2-03 |
| S5-Serial | FR-S5-02 | After FR-S2-03 |

**Cross-Sprint Parallelism:**

```
Sprint 4 can run in parallel with Sprint 3 (per plan Section 8.1)

Specifically:
- S4-WP1 (rate limiting, timezone, MIME) has zero S3 dependencies
- S4-WP2 (scopes, token validation) has zero S3 dependencies
- S4-WP3 (Dockerfile, dockerignore) has zero S3 dependencies
- Only FR-S4-04 (caching) benefits from S3 test infrastructure
```

---

## 5. Risk Assessment Per Requirement

### 5.1 High-Risk Requirements

| ID | Risk Level | Risk Description | Mitigation |
|:---|:----------:|:-----------------|:-----------|
| FR-S2-01 | **High** | parse_json() rewrite touches core installer; could break macOS existing behavior | Keep osascript fallback; test on macOS/Linux/WSL (R-04) |
| FR-S2-03 | **High** | MCP config path change may lose existing user configurations | Migration script + legacy path fallback (R-01) |
| FR-S1-01 | **High** | OAuth state addition may break existing auth flow for current users | Accept stateless callbacks with warning log (R-02) |
| FR-S3-01 | **High** | Google API mock complexity for 71 tools; risk of low-value tests | Use MSW or googleapis-mock library (R-06) |
| FR-S4-09 | **High** | Node.js 22 may have googleapis compatibility issues | Local test + CI verification before merge (R-03) |
| FR-S4-06 | **High** | Mutex implementation for concurrent auth is error-prone in Node.js single-thread model | Use promise-based lock pattern, not OS mutex |

### 5.2 Medium-Risk Requirements

| ID | Risk Level | Risk Description | Mitigation |
|:---|:----------:|:-----------------|:-----------|
| FR-S2-02 | Medium | Remote execution temp directory cleanup; security of downloaded scripts | Validate downloaded script hash; cleanup in trap handler |
| FR-S2-04 | Medium | Edge cases across dnf/pacman distributions | Support only top 3 (apt, dnf, pacman); manual guide for others (R-07) |
| FR-S2-10 | Medium | Windows UAC behavior varies by system policy | Detect and inform; do not force |
| FR-S4-01 | Medium | Rate limit retry may cause timeout in interactive MCP sessions | Cap total retry time at 15s; fail fast with helpful message |
| FR-S4-04 | Medium | Caching stale tokens may cause auth failures | Cache with TTL; re-auth on 401 response |
| FR-S5-01 | Medium | Health check may fail for legitimate reasons (slow start, network) | Retry with backoff; clear error differentiation |
| FR-S5-02 | Medium | Rollback may not cover all side effects (Docker containers, env changes) | Document rollback scope limitations |

### 5.3 Low-Risk Requirements

| ID | Risk Level | Notes |
|:---|:----------:|:------|
| FR-S1-02 | Low | Simple string escape; well-understood pattern |
| FR-S1-05 | Low | Downgraded to Informational; minimal change needed |
| FR-S1-06 | Low | Standard Docker best practice; well-documented |
| FR-S1-07 | Low | One-line chmod addition |
| FR-S1-08 | Low | One-line mode parameter addition |
| FR-S1-10 | Low | Simple regex strip |
| FR-S2-05 | Low | module.json field update only |
| FR-S2-06 | Low | module.json field update only |
| FR-S2-07 | Low | Array sort; PowerShell already implements this |
| FR-S2-08 | Low | Timeout wrapper; standard pattern |
| FR-S2-09 | Low | module.json field addition only |
| FR-S3-05 | Low | Refactoring; no behavioral change |
| FR-S3-06 | Low | Config file additions only |
| FR-S3-07 | Low | Type narrowing; localized change |
| FR-S3-08 | Low | String replacements only |
| FR-S4-03 | Low | Well-understood Intl API usage |
| FR-S4-07 | Low | Recursive traversal; well-known pattern |
| FR-S4-08 | Low | Remove truncation; add parameter |
| FR-S4-10 | Low | New file creation only |
| FR-S5-03 | Low | Documentation update only |
| FR-S5-04 | Low | Version string change only |
| FR-S5-05 | Low | String replacements only |
| FR-S5-06 | Low | .gitignore pattern addition only |

---

## 6. Dependency Graph (Full)

```
Legend:
  ──> = "must complete before"
  ~~> = "soft dependency (benefits from but not blocked)"
  [C] = Critical, [H] = High, [M] = Medium, [L] = Low

Sprint 1 (No external dependencies -- can start immediately)
  FR-S1-01 [C] ──> FR-S4-02 [H]
  FR-S1-03 [C] ──> FR-S2-01 [C]
  FR-S1-04 [H] ~~> FR-S1-09 [H]  (same file, coordinate changes)
  FR-S1-06 [H] ──> FR-S4-09 [M]
  FR-S1-02 [C]  (independent)
  FR-S1-05 [L]  (independent)
  FR-S1-07 [H]  (independent)
  FR-S1-08 [H]  (independent)
  FR-S1-10 [M]  (independent)

Sprint 2 (After Sprint 1 completion)
  FR-S2-01 [C] ──> FR-S2-04 [M]
  FR-S2-01 [C] ──> FR-S5-01 [H]
  FR-S2-03 [H] ──> FR-S5-02 [M]
  FR-S2-05 [M] ~~> FR-S2-09 [M]  (same file)
  FR-S2-02 [H]  (independent)
  FR-S2-06 [M]  (independent)
  FR-S2-07 [L]  (independent)
  FR-S2-08 [L]  (independent)
  FR-S2-10 [M]  (independent)

Sprint 3 (After Sprint 2 completion; parallel with Sprint 4)
  FR-S3-01 [C] ──> FR-S3-03 [H]
  FR-S3-02 [H] ──> FR-S3-03 [H]
  FR-S3-03 [H] ──> FR-S3-04 [M]
  FR-S3-05 [M] ──> FR-S5-03 [L]
  FR-S3-08 [L] ~~> FR-S5-05 [L]  (error msgs partial overlap)
  FR-S3-06 [L]  (independent)
  FR-S3-07 [L]  (independent)

Sprint 4 (Parallel with Sprint 3)
  FR-S4-05 [M] ~~> FR-S4-04 [M]  (token validation feeds caching)
  FR-S4-06 [M] ~~> FR-S4-04 [M]  (mutex coordinates with cache)
  FR-S4-07 [M] ──> FR-S4-08 [L]  (MIME parsing before attachment fix)
  FR-S4-01 [H]  (independent)
  FR-S4-02 [H]  (depends on S1-01, already complete by S4)
  FR-S4-03 [H]  (independent)
  FR-S4-09 [M]  (depends on S1-06, already complete by S4)
  FR-S4-10 [L]  (independent)

Sprint 5 (After Sprint 3+4 completion)
  All S5 items depend on earlier sprints as noted above.
  FR-S5-01 [H]  (depends on S2-01, S2-03)
  FR-S5-02 [M]  (depends on S2-03)
  FR-S5-03 [L]  (depends on S3-05)
  FR-S5-04 [L]  (independent)
  FR-S5-05 [L]  (soft depends on S3-08)
  FR-S5-06 [M]  (independent)
```

---

## 7. Target File Impact Matrix

Files touched by multiple requirements (high-coordination areas).

| Target File | Requirements | Total Count | Coordination Needed |
|:------------|:-------------|:----------:|:-------------------:|
| `oauth.ts` | FR-S1-01, FR-S1-07, FR-S1-08, FR-S4-02, FR-S4-04, FR-S4-05, FR-S4-06 | **7** | **Critical** |
| `install.sh` | FR-S1-03, FR-S2-01, FR-S2-02, FR-S2-07, FR-S5-01, FR-S5-02 | **6** | **Critical** |
| `gmail.ts` | FR-S1-10, FR-S4-07, FR-S4-08 | 3 | High |
| `atlassian/install.sh` | FR-S1-04, FR-S1-09, FR-S2-03 | 3 | High |
| `figma/module.json` | FR-S1-05, FR-S2-05, FR-S2-09 | 3 | Medium |
| `Dockerfile` | FR-S1-06, FR-S4-09 | 2 | Medium |
| `drive.ts` | FR-S1-02 | 1 | Low |
| `calendar.ts` | FR-S4-03 | 1 | Low |
| `google/install.sh` | FR-S2-03, FR-S2-08 | 2 | Medium |
| `base/install.sh` | FR-S2-04 | 1 | Low |
| `install.ps1` | FR-S2-10 | 1 | Low |
| `.github/workflows/test-installer.yml` | FR-S3-03, FR-S3-04 | 2 | Medium |
| `google-workspace-mcp/src/tools/*.ts` | FR-S4-01, FR-S5-05 | 2 | Medium |
| `notion/module.json` | FR-S2-09 | 1 | Low |
| `atlassian/module.json` | FR-S2-06 | 1 | Low |
| `index.ts` | FR-S3-07, FR-S3-08 | 2 | Low |
| `installer/ARCHITECTURE.md` | FR-S5-03 | 1 | Low |
| `google-workspace-mcp/package.json` | FR-S5-04 | 1 | Low |
| `.gitignore` | FR-S5-06 | 1 | Low |
| `installer/modules/shared/` | FR-S3-05 | 1 (new dir) | Low |

---

## 8. Gap Analysis: Missing, Implicit, and Cross-Cutting Concerns

### 8.1 Potentially Missing Requirements

| # | Missing Area | Evidence | Suggested ID | Priority |
|:-:|:-------------|:---------|:-------------|:--------:|
| 1 | **npm audit / dependency vulnerability scan** | Appendix A.1 mentions "`npm audit` not applied" as additional finding | FR-S3-09 (proposed) | High |
| 2 | **Additional `any` type locations** | Appendix A.2 notes `any` in `sheets.ts:18,341`, `calendar.ts:288`, `slides.ts:135,156` but FR-S3-07 only targets `index.ts:32` | Expand FR-S3-07 scope | Medium |
| 3 | **Security logging** | Appendix A.1 mentions "security logging not implemented" as additional finding | FR-S3-10 (proposed) | Medium |
| 4 | **Input validation layer** | Appendix A.1 mentions "input validation layer absence" | FR-S1-11 (proposed) | High |
| 5 | **Docker Desktop version check** | Section 8.2 maps OS-06 to FR-S2-04 but the description of FR-S2-04 only covers package managers, not Docker version detection | FR-S2-11 (proposed) | Medium |
| 6 | **OS-05 documentation handling** | Mapped as "documentation response" but no specific FR created | Covered implicitly by FR-S5-03 | Low |
| 7 | **Pencil module install.sh** | Pencil module exists in codebase but no requirements mention it | Review if Pencil needs security/platform fixes | Low |
| 8 | **Structured logging** | QA-05 mapped to Out of Scope, but basic structured logging would benefit debugging | Consider for future sprint | Low |

### 8.2 Implicit Requirements (Undocumented but Necessary)

| # | Implicit Requirement | Why Needed | Affects |
|:-:|:---------------------|:-----------|:--------|
| 1 | **Backwards compatibility testing** | Multiple breaking changes (MCP path, OAuth state, parse_json) need migration path verification | FR-S2-01, FR-S2-03, FR-S1-01 |
| 2 | **Error handling consistency** | Shared error handling patterns needed when rate limiting (FR-S4-01) and token validation (FR-S4-05) are added | FR-S4-01, FR-S4-05, FR-S4-06 |
| 3 | **Temp file cleanup** | FR-S2-02 downloads to temp dir; cleanup must be guaranteed even on script failure | FR-S2-02 |
| 4 | **CI secret management** | CI workflows need Google API credentials mock/stubs for testing | FR-S3-01, FR-S3-03 |
| 5 | **Migration documentation** | Users with existing `.mcp.json` at legacy path need migration guide | FR-S2-03 |
| 6 | **TypeScript strict mode preservation** | Removing `any` types and adding proper types must not regress `strict: true` | FR-S3-07 |
| 7 | **Docker build cache invalidation** | Changing base image (Node 22), adding user, adding .dockerignore affects layer caching | FR-S1-06, FR-S4-09, FR-S4-10 |

### 8.3 Cross-Cutting Concerns

These concerns span multiple requirements and need coordinated design decisions.

| # | Concern | Affected Requirements | Design Decision Needed |
|:-:|:--------|:---------------------|:----------------------|
| 1 | **oauth.ts is the most-modified file (7 requirements)** | FR-S1-01, FR-S1-07, FR-S1-08, FR-S4-02, FR-S4-04, FR-S4-05, FR-S4-06 | Refactor oauth.ts into smaller modules before/during changes? Define clear function boundaries to avoid merge conflicts. |
| 2 | **install.sh is the second most-modified file (6 requirements)** | FR-S1-03, FR-S2-01, FR-S2-02, FR-S2-07, FR-S5-01, FR-S5-02 | Plan changes sequentially; FR-S1-03 and FR-S2-01 merge into single implementation. |
| 3 | **Environment variable proliferation** | FR-S1-04 (.env for Atlassian), FR-S4-02 (GOOGLE_SCOPES), FR-S4-03 (TIMEZONE), FR-S1-05 (.env for Figma) | Need unified .env.example template; document all new env vars together. |
| 4 | **module.json schema evolution** | FR-S2-05, FR-S2-06, FR-S2-09 | Define a formal module.json schema/spec before making changes to avoid further inconsistencies. |
| 5 | **Test infrastructure bootstrapping** | FR-S3-01, FR-S3-02, FR-S3-03, FR-S3-04, FR-S3-06 | Test framework choice (Vitest) and CI setup are tightly coupled; design test architecture holistically. |
| 6 | **Docker security hardening** | FR-S1-06, FR-S4-09, FR-S4-10 | All Dockerfile changes should be made in a single, well-tested commit to avoid intermediate broken states. |
| 7 | **Internationalization (i18n) direction** | FR-S3-08, FR-S5-05 | Decide: simple English-only, or i18n-key pattern for future multi-language support? |
| 8 | **Shell script quality baseline** | FR-S1-03, FR-S1-09, FR-S2-01, FR-S2-02, FR-S3-05 | Consider adding ShellCheck to CI (FR-S3-03) for ongoing shell script quality. |

---

## 9. Sprint Execution Summary with Expected Outcomes

| Sprint | Requirements | Critical/High | Expected Match Rate | Effort Estimate |
|:------:|:----------:|:-------------:|:-------------------:|:---------------:|
| S1 | 10 | 8 (3C + 5H) | 65.5% -> 72% | 26-37h |
| S2 | 10 | 3 (1C + 2H) | 72% -> 80% | 18-25h |
| S3 | 8 | 3 (1C + 2H) | 80% -> 86% | 20-30h |
| S4 | 10 | 3 (3H) | 86% -> 92% | 20-30h |
| S5 | 6 | 1 (1H) | 92% -> 95%+ | 10-15h |
| **Total** | **44** | **18** | **65.5% -> 95%+** | **94-137h** |

---

## 10. Analysis Issue to Requirement Full Traceability

This table confirms every analysis issue is accounted for.

| Analysis Issue | Severity | Requirement(s) | Sprint | Disposition |
|:--------------:|:--------:|:---------------|:------:|:------------|
| SEC-01 | Critical | FR-S1-03 (partial), Out of Scope (GPG) | S1 | Partially addressed |
| SEC-02 | Critical | FR-S1-04 | S1 | Fully addressed |
| SEC-03 | Critical | FR-S1-05 | S1 | Downgraded (Informational) |
| SEC-04 | High | FR-S1-07 | S1 | Fully addressed |
| SEC-05 | High | FR-S1-06 | S1 | Fully addressed |
| SEC-06 | High | FR-S2-10 | S2 | Fully addressed |
| SEC-07 | High | FR-S4-02 | S4 | Fully addressed |
| SEC-08 | High | FR-S1-01 | S1 | Fully addressed |
| SEC-08a | High | FR-S1-03 | S1 | Fully addressed |
| SEC-09 | Medium | FR-S1-09 | S1 | Fully addressed |
| SEC-10 | Medium | FR-S5-06 | S5 | Fully addressed |
| SEC-11 | Medium | Out of Scope | - | Third-party image verification |
| SEC-12 | Medium | FR-S1-09 | S1 | Fully addressed |
| SEC-13 | Medium | FR-S1-04 | S1 | Resolved by env var migration |
| SEC-14 | Medium | FR-S1-08 | S1 | Fully addressed |
| INS-01 | High | FR-S2-01 | S2 | Fully addressed |
| INS-02 | Medium->High | FR-S2-03 | S2 | Fully addressed (upgraded) |
| INS-03 | Medium | FR-S5-02 | S5 | Fully addressed |
| INS-04 | Low | FR-S2-07 | S2 | Fully addressed |
| INS-05 | Medium | FR-S2-04 | S2 | Fully addressed |
| INS-06 | Low | FR-S5-03 | S5 | Fully addressed |
| INS-07 | High | FR-S2-02 | S2 | Fully addressed |
| INS-08 | Medium | FR-S2-05 | S2 | Fully addressed |
| INS-09 | Medium | FR-S2-06 | S2 | Fully addressed |
| INS-10 | Low | FR-S2-08 | S2 | Fully addressed |
| GWS-01 | Medium | FR-S4-05 | S4 | Fully addressed |
| GWS-02 | Medium | FR-S4-01 | S4 | Fully addressed |
| GWS-03 | Low | FR-S3-08, FR-S5-05 | S3/S5 | Fully addressed (split) |
| GWS-04 | Low | FR-S3-07 | S3 | Partially addressed (only index.ts) |
| GWS-05 | Medium | FR-S4-06 | S4 | Fully addressed |
| GWS-06 | Low | FR-S5-04 | S5 | Fully addressed |
| GWS-07 | High | FR-S1-02 | S1 | Fully addressed |
| GWS-08 | Medium | FR-S1-10 | S1 | Fully addressed |
| GWS-09 | Medium | FR-S4-03 | S4 | Fully addressed |
| GWS-10 | Medium | FR-S4-07 | S4 | Fully addressed |
| GWS-11 | Low | FR-S4-08 | S4 | Fully addressed |
| GWS-12 | Low | FR-S4-10 | S4 | Fully addressed |
| OS-01 | High->Critical | FR-S2-01 | S2 | Fully addressed (upgraded) |
| OS-02 | Medium | FR-S2-04 | S2 | Fully addressed |
| OS-05 | Medium->Low | Documentation | S5 | Downgraded; WSL guide exists |
| OS-06 | High | FR-S2-04 (mapped) | S2 | Partially addressed (see gap #5) |
| OS-07 | Medium | FR-S2-09 | S2 | Fully addressed |
| OS-08 | Medium->High | FR-S4-09 | S4 | Fully addressed (upgraded) |
| QA-01 | Critical | FR-S3-01, FR-S3-02 | S3 | Fully addressed |
| QA-02 | High | FR-S3-03 | S3 | Fully addressed |
| QA-03 | Medium | FR-S3-05 | S3 | Fully addressed |
| QA-04 | Medium | FR-S5-02 | S5 | Fully addressed |
| QA-05 | Low | Out of Scope | - | Structured logging |
| QA-06 | Medium | FR-S3-05 | S3 | Fully addressed |
| QA-07 | Medium | FR-S4-04 | S4 | Fully addressed |
| QA-08 | Low | FR-S3-06 | S3 | Fully addressed |
| QA-09 | Low | Out of Scope | - | CHANGELOG generation |

**Coverage Summary**: 48 analysis issues, 43 addressed (89.6%), 5 Out of Scope

---

## 11. Recommendations

### 11.1 Immediate Actions Before Design Phase

1. **Expand FR-S3-07 scope** to cover all `any` type instances (sheets.ts, calendar.ts, slides.ts), not just index.ts.
2. **Create FR-S2-11** (or expand FR-S2-04) to explicitly include Docker Desktop version detection (OS-06).
3. **Consider FR-S1-11** for an input validation layer -- this is a cross-cutting security concern mentioned by the Security Architect but not captured as a requirement.
4. **Consider FR-S3-09** for `npm audit` integration into CI pipeline.

### 11.2 Design Phase Considerations

1. **oauth.ts refactoring plan** -- 7 requirements touch this file; design should propose a module split.
2. **module.json schema specification** -- 3 requirements change module.json files; define the target schema first.
3. **.env.example template** -- multiple requirements introduce environment variables; centralize in design.
4. **Test architecture document** -- Sprint 3 builds the entire test infrastructure; needs its own design section.

### 11.3 Risk Mitigation Priorities

1. **R-01 (MCP path migration)** -- most impactful user-facing change; needs migration script in design.
2. **R-06 (Test mock complexity)** -- highest likelihood risk; evaluate MSW vs googleapis-mock early.
3. **R-03 (Node.js 22 compatibility)** -- time-sensitive due to Node.js 20 EOL 2026-04-30 (77 days from plan date).

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-12 | Initial traceability matrix -- 44 requirements analyzed | Gap Detector Agent |
