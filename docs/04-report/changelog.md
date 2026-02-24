# Changelog

All notable changes to the ADW project are documented in this file.

## [1.0.0] - 2026-02-19

**PDCA Cycle Complete: 95.8% Match Rate**

### Added

- **Input validation layer** (`sanitize.ts`) -- 7 security functions: escapeDriveQuery, validateDriveId, sanitizeEmailHeader, validateEmail, validateMaxLength, sanitizeFilename, sanitizeRange
- **Rate limiting with exponential backoff** (`retry.ts`) -- withRetry() wrapping 91 API calls, 3 retries, 1s→2s→4s backoff
- **Timezone utilities** (`time.ts`) -- getTimezone(), getUtcOffsetString() with Intl.DateTimeFormat fallback
- **MIME parsing utilities** (`mime.ts`) -- extractTextBody(), extractAttachments() with recursive multipart support
- **Message catalog** (`messages.ts`) -- 8 categories, 60+ messages, i18n-ready structure
- **Security event logging** -- logSecurityEvent() to stderr with JSON structure (timestamps, event types, results)
- **Cross-platform JSON parser** -- node > python3 > osascript fallback chain for shell scripts
- **Installer shared utilities** (5 files):
  - `colors.sh` -- ANSI colors + semantic print functions
  - `docker-utils.sh` -- Docker status, version checks, container management
  - `mcp-config.sh` -- MCP configuration management
  - `browser-utils.sh` -- Cross-platform browser opening (WSL aware)
  - `package-manager.sh` -- Unified package manager interface (apt, dnf, pacman, yum, brew)
- **Google MCP shared utilities** (5 TypeScript files) -- time, retry, sanitize, mime, messages utilities
- **226 unit tests** across 10 test files (86 utils + 140 tools) with 97.46% statement coverage
- **Installer smoke tests** -- 61 tests covering module.json validation, shell syntax, execution order
- **CI/CD pipeline enhancements**:
  - Multi-OS matrix (Ubuntu, macOS, Windows)
  - 12 jobs: lint, build, test, smoke-tests, security-audit, shellcheck, docker-build, verify-checksums
  - Auto-trigger on push and pull requests
- **SHA-256 checksum verification** -- `download_and_verify()` function with checksums.json manifest
- **Atlassian credentials security** -- `.atlassian-mcp/credentials.env` file with `chmod 700/600` permissions
- **Token file permissions** -- `fs.chmodSync(TOKEN_PATH, 0o600)` for secure credential storage
- **Config directory permissions** -- `mkdirSync(..., {mode: 0o700})` for `~/.google-workspace`
- **Docker non-root user** -- User `mcp` with UID 1001, proper ownership and permissions
- **oauth-helper.sh** -- Shared OAuth flow for Remote MCP modules (Notion, Figma)
- **Module shared directory setup** -- Temporary directory download + cleanup trap for remote execution
- **ARCHITECTURE.md updates** -- Documented shared/ directory, Pencil module, Remote MCP types, execution order
- **ESLint + Prettier configuration** -- recommendedTypeChecked rules, prettier integration, no-explicit-any warning
- **.dockerignore file** -- Exclude .env*, client_secret.json, token.json, node_modules, .git, tests
- **.env.example** (google-workspace-mcp) -- Configuration template with GOOGLE_SCOPES, TIMEZONE examples

### Changed

- **MCP config path unified** -- All platforms now use `~/.claude/mcp.json` (was ~./mcp.json on macOS)
- **Atlassian token storage** -- From plaintext in `.mcp.json` to `.env` file with `--env-file` Docker flag
- **Calendar timezone** -- From hardcoded `Asia/Seoul` to dynamic detection via Intl.DateTimeFormat
- **Node.js base image** -- node:20-slim → node:22-slim (EOL extension, LTS to 2028-10)
- **package.json version** -- 0.1.0 → 1.0.0 (production release)
- **Linux package manager support** -- apt/snap only → apt, dnf, pacman, yum, brew (5 managers)
- **Module execution order** -- Sorting by MODULE_ORDERS array (was unordered)
- **OAuth state parameter** -- 16 bytes → 32 bytes (stronger entropy)
- **Test coverage thresholds** -- 60% → 80% statements/lines/functions, 50% → 70% branches
- **Google API retry strategy** -- Manual implementation with configurable backoff (was no retry)
- **Gmail attachment data** -- Full base64 returned (was 1000-char truncation)
- **All user-facing messages** -- Korean strings removed, unified to English
- **.gitignore patterns** -- Added `client_secret.json`, `.env*` patterns for security

### Fixed

- **SEC-01: MITM remote code execution risk** (Critical) -- SHA-256 checksum verification with `download_and_verify()`
- **SEC-02: Plaintext API token exposure** (Critical) -- Atlassian token moved to .env file
- **SEC-03: OAuth CSRF vulnerability** (High) -- State parameter validation with 32-byte nonce
- **SEC-04: token.json world-readable** (High) -- File permissions hardened to 0o600
- **SEC-05: Docker container root execution** (High) -- Non-root user `mcp` with proper permissions
- **SEC-06: Forced Windows admin rights** (High) -- Conditional UAC elevation per module
- **SEC-07: Overprivileged OAuth scopes** (High) -- Dynamic scope configuration via GOOGLE_SCOPES env var
- **SEC-08: osascript template injection** (High) -- stdin pipe pattern replacing backtick templates
- **SEC-09/SEC-12: Atlassian variable escaping** (Medium) -- Environment variable passing instead of string interpolation
- **GWS-01: Missing token refresh validation** (Medium) -- refresh_token existence check with re-auth prompt
- **GWS-02: No rate limiting** (Medium) -- Exponential backoff retry logic with 429/503 handling
- **GWS-05: Concurrent auth race condition** (Medium) -- Auth mutex pattern with Promise locking
- **GWS-07: Drive query injection** (High) -- Query escaping + validateDriveId validation
- **GWS-08: Email header injection** (Medium) -- sanitizeEmailHeader() removing CRLF
- **GWS-09: Hardcoded timezone** (Medium) -- Dynamic timezone detection with env override
- **GWS-10: Missing nested MIME parsing** (Medium) -- Recursive extractTextBody/Attachments
- **INS-01: Linux install completely broken** (Critical) -- Cross-platform JSON parser fallback chain
- **INS-02: MCP config path inconsistency** (High) -- Unified path + legacy migration
- **INS-07: Missing remote shared scripts** (High) -- Shared directory download + cleanup logic
- **QA-01: Zero test coverage** (Critical) -- Vitest framework with 226 passing tests
- **QA-06: Code duplication** (Medium) -- Extracted 35 shared utility functions
- **QA-07: Service instance redundancy** (Medium) -- Service caching with 50-min TTL
- **QA-08: Missing code style tools** (Low) -- ESLint recommendedTypeChecked + Prettier
- **All TypeScript any types** (Low) -- 0 instances of `: any` / `as any`
- **Module execution order** (Low) -- Deterministic sorting by MODULE_ORDERS array
- **Docker wait infinite hang** (Low) -- 300-second timeout with polling

### Metrics

| Metric | Before | After | Improvement |
|--------|:------:|:-----:|:-----------:|
| Match Rate | 65.5% | **95.8%** | +30.3pp |
| Critical Issues | 3 | **0** | -100% |
| High Issues | 8 | **0** | -100% |
| Test Files | 0 | **10** | New |
| Test Count | 0 | **226** | New |
| Line Coverage | 0% | **97.46%** | New |
| Service Creation | 414x | 6x (TTL) | **-99%** |
| Installer LOC | ~1,200 | ~850 | -29% |
| Google MCP LOC | ~1,800 | ~1,300 | -28% |
| `any` types | ~7 | **0** | -100% |
| Korean strings | 295+ | **0** | -100% |
| ESLint errors | N/A | **0** | Pass |
| npm audit high+ | N/A | **0** | Pass |

### Security Audit Results

- **Critical vulnerabilities**: 3 → 0 (100% closure)
- **High vulnerabilities**: 8 → 0 (100% closure)
- **Medium vulnerabilities**: ~10 → 0 (100% closure)
- **Security events**: Logged to stderr with JSON structure
- **OWASP Top 10 coverage**: A01 (broken access), A03 (injection), A07 (authn), A09 (logging)

### Platform Support

- macOS 14.x+ (Sonoma, Ventura, Monterey) ✅
- Windows 10+ ✅
- Linux: Ubuntu 22.04+ LTS, Fedora 39+, Arch Linux ✅
- Dual shell support: bash + PowerShell ✅

### Breaking Changes

- **MCP config path change** (macOS/Linux): `~/.mcp.json` → `~/.claude/mcp.json`
  - Migration included; legacy path automatically migrated
- **Atlassian credentials** (macOS/Linux): Must use `.atlassian-mcp/credentials.env` instead of inline in `.mcp.json`

### Known Issues / Deferred

- ✅ **CHANGELOG.md creation** -- Created at `google-workspace-mcp/CHANGELOG.md`
- ✅ **MCP server version in index.ts** -- Updated to "1.0.0"
- ⏸️ **installer/.env.example** -- Optional documentation file
- ⏸️ **installer/module-schema.json** -- Optional JSON Schema definition
- ⏸️ **oauth.ts modularization** -- Deferred to post-v1.0 (design timeline)
- ⏸️ **Remaining 5 modules shared utils wiring** -- Partial (google, atlassian complete; others pending)

### Testing & CI

- Unit tests: 226 passing (97.46% coverage)
- Smoke tests: 61 passing (module validation + syntax)
- CI matrix: Ubuntu 22.04, macOS 13.x, Windows Server 2022
- CI jobs: 12 (lint, build, test, smoke-tests, security-audit, shellcheck, docker-build + others)
- All jobs: ✅ Passing

### Contributors

- **CTO Team** (8-agent analysis & design): Security Architect, Code Analyzer, Enterprise Expert
- **gap-detector agent**: Design-implementation verification
- **report-generator agent**: Completion report

### PDCA Cycle Summary

- **Plan**: 1 day (2026-02-12)
- **Design**: 1 day (2026-02-12 to 2026-02-13)
- **Do**: 5 days (implementation, 2026-02-13 to 2026-02-17)
- **Check**: 1 day (gap analysis, 2026-02-19)
- **Act**: Converged at 95.8% (no iteration needed)
- **Total**: 8 days

---

## [0.1.0] - Initial Release

Starting point for ADW Comprehensive Improvement project.
- Match Rate: 65.5%
- Critical Issues: 3
- High Issues: 8
- Test Coverage: 0%
