# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-19

### Added
- Full support for 6 Google Workspace services: Gmail, Drive, Docs, Sheets, Slides, Calendar
- Input validation layer (`sanitize.ts`) -- 7 security functions
- Rate limiting with exponential backoff (`retry.ts`) -- 91 API calls wrapped
- Timezone utilities (`time.ts`) -- dynamic detection with Intl.DateTimeFormat fallback
- MIME parsing utilities (`mime.ts`) -- recursive multipart support
- Message catalog (`messages.ts`) -- 60+ i18n-ready messages
- Security event logging to stderr with JSON structure
- 226 unit tests across 10 test files (97.46% coverage)
- ESLint recommendedTypeChecked + Prettier configuration
- Docker non-root user (`mcp:mcp`, UID 1001)
- OAuth CSRF protection with 32-byte state parameter
- Token file permissions hardened to 0o600
- .dockerignore for secure builds

### Changed
- Version bump from 0.1.0 to 1.0.0 (first stable release)
- Node.js base image: node:20-slim to node:22-slim
- Calendar timezone: hardcoded `Asia/Seoul` to dynamic detection
- OAuth state parameter: 16 bytes to 32 bytes
- All user-facing messages unified to English (295 Korean strings removed)
- Service instance caching with 50-min TTL (414x creation to 6x)

### Fixed
- SEC-03: OAuth CSRF vulnerability -- state parameter validation
- SEC-04: token.json world-readable -- chmod 0o600
- SEC-05: Docker root execution -- non-root user
- SEC-07: Overprivileged OAuth scopes -- dynamic GOOGLE_SCOPES env var
- SEC-08: osascript template injection -- stdin pipe pattern
- GWS-01: Missing token refresh validation
- GWS-02: No rate limiting -- exponential backoff retry
- GWS-05: Concurrent auth race condition -- auth mutex
- GWS-07: Drive query injection -- escapeDriveQuery + validateDriveId
- GWS-08: Email header injection -- CRLF sanitization
- GWS-09: Hardcoded timezone -- dynamic detection
- GWS-10: Missing nested MIME parsing -- recursive extraction
- All `any` types eliminated (0 instances)

### Breaking Changes
- MCP config path: `~/.mcp.json` to `~/.claude/mcp.json` (auto-migration included)

## [0.1.0] - 2025-12-15

### Added
- Initial development version
- Basic Gmail and Drive support
- OAuth setup
