# Sprint 5 UX Improvements - Visual Summary

> Quick reference guide for Sprint 5 design implementation

---

## FR-S5-01: Post-Installation Verification

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  Verification Flow                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Installation Complete]                                    │
│           ↓                                                 │
│  ┌─────────────────────────────┐                            │
│  │ Run Verification            │                            │
│  │ - Base components           │                            │
│  │ - MCP servers               │                            │
│  │ - Docker containers         │                            │
│  │ - CLI tools                 │                            │
│  └─────────────────────────────┘                            │
│           ↓                                                 │
│  ┌─────────────────────────────┐                            │
│  │ Health Check per Module     │                            │
│  │                             │                            │
│  │ MCP Server:                 │                            │
│  │   claude mcp list           │                            │
│  │   + retry (3 attempts)      │                            │
│  │                             │                            │
│  │ Docker-based:               │                            │
│  │   docker run --rm IMAGE     │                            │
│  │   + MCP registration        │                            │
│  │                             │                            │
│  │ Remote MCP:                 │                            │
│  │   MCP list check only       │                            │
│  │                             │                            │
│  │ CLI Tool:                   │                            │
│  │   command -v {tool}         │                            │
│  └─────────────────────────────┘                            │
│           ↓                                                 │
│  ┌─────────────────────────────┐                            │
│  │ Results Summary             │                            │
│  │ ✓ Verified: 6               │                            │
│  │ ✗ Failed: 0                 │                            │
│  └─────────────────────────────┘                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Output Format

```bash
========================================
  Post-Installation Verification
========================================

Verifying base components...
  [OK] Node.js v20.11.0
  [OK] Claude Code CLI
  [OK] bkit Plugin

Verifying Google Workspace...
  [WAIT] Waiting for MCP server to start (attempt 1/3)...
  [OK] Google Workspace is registered in MCP
  [OK] Google Workspace Docker container is functional

Verifying Notion...
  [OK] Notion is registered

========================================
  Verification Summary
========================================
  Verified: 6
  Failed: 0
```

### Troubleshooting Messages

```bash
# Example failure
  [FAIL] Google Workspace not found in MCP server list
  Troubleshooting:
    1. Check ~/.mcp.json configuration
    2. Run: claude mcp list
    3. Check server logs in ~/.claude/mcp/logs/
```

---

## FR-S5-02: Rollback Mechanism

### Backup & Restore Flow

```
┌──────────────────────────────────────────────────────────────┐
│                     Rollback Architecture                     │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  BEFORE Installation:                                        │
│  ┌──────────────────────────────────────────┐               │
│  │ 1. Create backup directory               │               │
│  │    ~/.claude/installer_backups/          │               │
│  │                                          │               │
│  │ 2. Backup MCP config                     │               │
│  │    ~/.mcp.json                           │               │
│  │      → mcp.json.backup.20260212_143052   │               │
│  │                                          │               │
│  │ 3. Store backup path                     │               │
│  │    .last_backup                          │               │
│  └──────────────────────────────────────────┘               │
│                        ↓                                     │
│  DURING Installation:                                        │
│  ┌──────────────────────────────────────────┐               │
│  │ Module 1: Google Workspace               │               │
│  │   ✓ Success → Track in SUCCESSFUL_MODULES│               │
│  └──────────────────────────────────────────┘               │
│                        ↓                                     │
│  ┌──────────────────────────────────────────┐               │
│  │ Module 2: Notion                         │               │
│  │   ✗ FAILED!                              │               │
│  │                                          │               │
│  │   Rollback Notion? (y/n) → y             │               │
│  │   ┌────────────────────────────┐         │               │
│  │   │ 1. Remove Docker image     │         │               │
│  │   │ 2. Restore ~/.mcp.json     │         │               │
│  │   │ 3. Clean artifacts         │         │               │
│  │   └────────────────────────────┘         │               │
│  └──────────────────────────────────────────┘               │
│                        ↓                                     │
│  AFTER Installation:                                         │
│  ┌──────────────────────────────────────────┐               │
│  │ All Successful?                          │               │
│  │   YES → Cleanup backup files             │               │
│  │   NO  → Keep backup for manual recovery  │               │
│  └──────────────────────────────────────────┘               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### User Interaction Example

```bash
[2/3] Installing Notion...
  Error: OAuth configuration failed

[FAIL] Notion installation failed

Rollback Notion? (y/n)
> y

========================================
  Rollback: Notion
========================================
  Removing Docker image...
  Restoring MCP config from backup...
  [OK] Restored MCP config from backup

Rollback completed for Notion
```

---

## FR-S5-03: ARCHITECTURE.md Updates

### Content Additions

```markdown
# ADDED: Folder Structure (Pencil + shared/)
modules/
├── pencil/              # NEW
│   ├── module.json
│   ├── install.ps1
│   └── install.sh
│
├── shared/              # NEW
│   ├── verify.sh
│   ├── rollback.sh
│   └── docker-utils.sh

# ADDED: Module Types (CLI + Metadata)
### 3. CLI Tool Modules
- Pencil Protocol Builder
- No Docker required
- Native CLI installation

### Module Type Metadata
{
  "name": "google",
  "displayName": "Google Workspace",
  "type": "docker-mcp",           # NEW field
  "dependencies": ["docker"],      # NEW field
  "description": "..."
}

# ADDED: Execution Order Section
## Module Execution Order

1. Base (always first)
   - Node.js, Git, Claude CLI, bkit

2. Docker-dependent (if needed)
   - Install Docker Desktop
   - Build/pull images

3. Independent modules
   - Remote MCP, CLI tools (parallel-safe)

Example: google,notion,pencil
Execution: base → docker → google → notion → pencil
```

---

## FR-S5-04: Version Bump

### Change Summary

```diff
File: google-workspace-mcp/package.json

{
  "name": "google-workspace-mcp",
- "version": "0.1.0",
+ "version": "1.0.0",
  "description": "MCP Server for Google Workspace"
}
```

### Semantic Versioning Rules

```
┌─────────────────────────────────────────────┐
│  MAJOR.MINOR.PATCH (1.0.0)                  │
├─────────────────────────────────────────────┤
│                                             │
│  1.x.x  Breaking API changes                │
│         - Remove tool                       │
│         - Change schema                     │
│                                             │
│  x.1.x  New features (backward compatible)  │
│         - Add YouTube service               │
│         - New calendar tools                │
│                                             │
│  x.x.1  Bug fixes, patches                  │
│         - Fix OAuth flow                    │
│         - Performance improvement           │
│                                             │
└─────────────────────────────────────────────┘
```

### CHANGELOG.md (New File)

```markdown
# Changelog

## [1.0.0] - 2026-02-12

### Added
- Full support for 6 Google Workspace services
- MCP SDK integration
- OAuth 2.0 authentication
- 60+ tools

### Changed
- Version bump from 0.1.0 to 1.0.0 (first stable release)
```

---

## FR-S5-05: Message Internationalization

### Korean → English Replacement

```typescript
// BEFORE (Korean)
export const calendarTools = {
  calendar_list_calendars: {
    description: "사용 가능한 캘린더 목록을 조회합니다",
    schema: {
      calendarId: z.string().describe("캘린더 ID (기본: primary)")
    },
    handler: async () => {
      return {
        success: true,
        message: `일정 "${title}"이 생성되었습니다.`
      };
    }
  }
};

// AFTER (English)
export const calendarTools = {
  calendar_list_calendars: {
    description: "List available calendars",
    schema: {
      calendarId: z.string().describe("Calendar ID (default: primary)")
    },
    handler: async () => {
      return {
        success: true,
        message: `Event "${title}" created successfully.`
      };
    }
  }
};
```

### Replacement Statistics

```
┌─────────────────────────────────────────────┐
│  File          Korean Strings   Category    │
├─────────────────────────────────────────────┤
│  calendar.ts        82         desc/param   │
│  docs.ts            45         desc/param   │
│  drive.ts           58         desc/param   │
│  gmail.ts           62         desc/param   │
│  sheets.ts          48         desc/param   │
│  slides.ts          40         desc/param   │
├─────────────────────────────────────────────┤
│  TOTAL             295         All types    │
└─────────────────────────────────────────────┘
```

### Categories

- **description**: Tool description (82 instances)
- **param**: Parameter `.describe()` (156 instances)
- **success**: Success messages (45 instances)
- **error**: Error messages (12 instances)

---

## FR-S5-06: .gitignore Enhancements

### Security Additions

```gitignore
# CRITICAL - OAuth Credentials (Never commit!)
google-workspace-mcp/client_secret.json
google-workspace-mcp/token.json
google-workspace-mcp/.google-workspace/

# Generic patterns (all modules)
**/client_secret.json
**/token.json
**/credentials.json

# Installer backups (may contain credentials)
installer/.backups/
.claude/installer_backups/
*.mcp.json.backup*

# Module-specific
atlassian-mcp/.atlassian/
notion-mcp/.notion/
figma-mcp/.figma/

# Private keys
*.pem
*.key
*.p12
*.pfx
```

### Risk Assessment

```
┌───────────────────────────────────────────────────────────┐
│  Pattern              Risk      Impact if Leaked          │
├───────────────────────────────────────────────────────────┤
│  client_secret.json   CRITICAL  Full Google API access    │
│  token.json           HIGH      Temporary data access     │
│  .google-workspace/   MEDIUM    Cached credentials        │
│  *.key, *.pem         CRITICAL  Private key compromise    │
└───────────────────────────────────────────────────────────┘
```

### Validation Test

```bash
# Create test files
touch google-workspace-mcp/client_secret.json
touch .claude/installer_backups/mcp.json.backup.test

# Verify ignored
git status
# Should NOT show these files ✓

# Cleanup
rm google-workspace-mcp/client_secret.json
rm -rf .claude/installer_backups
```

---

## Implementation Priority

```
┌──────────────────────────────────────────────────────────┐
│  Priority   FR       Task                   Time         │
├──────────────────────────────────────────────────────────┤
│  P0         S5-06    .gitignore (security)   15 min      │
│  P0         S5-04    Version bump            10 min      │
│  P1         S5-05    i18n (295 strings)      2-3 hrs     │
│  P1         S5-01    Verification            3-4 hrs     │
│  P2         S5-02    Rollback                2-3 hrs     │
│  P2         S5-03    ARCHITECTURE.md         1 hr        │
├──────────────────────────────────────────────────────────┤
│  TOTAL                                       9-12 hrs    │
└──────────────────────────────────────────────────────────┘
```

### Recommended Order

1. **Security First**: FR-S5-06 (.gitignore)
2. **Quick Win**: FR-S5-04 (version bump)
3. **High Impact**: FR-S5-05 (i18n for global users)
4. **UX Polish**: FR-S5-01 (verification feedback)
5. **Safety Net**: FR-S5-02 (rollback on failures)
6. **Documentation**: FR-S5-03 (ARCHITECTURE.md sync)

---

## Testing Matrix

```
┌────────────────────────────────────────────────────────────┐
│  FR      Test Type           Test Case                     │
├────────────────────────────────────────────────────────────┤
│  S5-01   Unit                verify_mcp_server()           │
│          Integration         Full verification flow        │
│          E2E                 Install + verify all modules  │
├────────────────────────────────────────────────────────────┤
│  S5-02   Unit                create_backup()               │
│          Integration         Rollback after failure        │
│          E2E                 Multi-module partial success  │
├────────────────────────────────────────────────────────────┤
│  S5-03   Manual              Markdown rendering            │
│          Manual              Link validation               │
├────────────────────────────────────────────────────────────┤
│  S5-04   Build                npm run build                │
│          Package             npm pack                      │
├────────────────────────────────────────────────────────────┤
│  S5-05   Build                TypeScript compile           │
│          Integration         claude mcp list               │
│          E2E                 Trigger error, check message  │
├────────────────────────────────────────────────────────────┤
│  S5-06   Manual              Create test files             │
│          Manual              git status (verify ignored)   │
└────────────────────────────────────────────────────────────┘
```

---

## File Locations Reference

```
popup-claude/
├── installer/
│   ├── install.sh                           # Modify: FR-S5-01, S5-02
│   │   Lines 417+: Add verification functions
│   │   Lines 384: Call run_verification()
│   │   Lines 50+: Add rollback functions
│   │
│   └── ARCHITECTURE.md                      # Modify: FR-S5-03
│       Lines 111+: Add Pencil + shared/
│       Lines 194+: Add module metadata
│       New section: Execution order
│
├── google-workspace-mcp/
│   ├── package.json                         # Modify: FR-S5-04
│   │   Line 3: 0.1.0 → 1.0.0
│   │
│   ├── CHANGELOG.md                         # Create: FR-S5-04
│   │
│   └── src/tools/
│       ├── calendar.ts                      # Modify: FR-S5-05
│       ├── docs.ts                          # Modify: FR-S5-05
│       ├── drive.ts                         # Modify: FR-S5-05
│       ├── gmail.ts                         # Modify: FR-S5-05
│       ├── sheets.ts                        # Modify: FR-S5-05
│       └── slides.ts                        # Modify: FR-S5-05
│
└── .gitignore                               # Modify: FR-S5-06
    Lines 20+: Add OAuth patterns
```

---

## Success Criteria

### FR-S5-01 ✓
- [ ] All module types have verification functions
- [ ] Retry logic works for slow services (3 attempts)
- [ ] Troubleshooting messages are helpful
- [ ] Summary shows verified/failed counts
- [ ] User can retry failed modules

### FR-S5-02 ✓
- [ ] Backup created before installation
- [ ] Rollback restores ~/.mcp.json correctly
- [ ] Docker images removed on rollback
- [ ] Backup cleaned up after success
- [ ] User prompted for rollback on failure

### FR-S5-03 ✓
- [ ] Pencil module documented
- [ ] shared/ directory explained
- [ ] Module type metadata defined
- [ ] Execution order section added
- [ ] All Markdown renders correctly

### FR-S5-04 ✓
- [ ] package.json shows 1.0.0
- [ ] CHANGELOG.md created
- [ ] Build passes with new version
- [ ] Docker image tagged 1.0.0

### FR-S5-05 ✓
- [ ] All 295 Korean strings replaced
- [ ] TypeScript compiles without errors
- [ ] MCP tool descriptions are English
- [ ] Success/error messages are English
- [ ] No Korean characters in codebase

### FR-S5-06 ✓
- [ ] client_secret.json ignored
- [ ] token.json ignored
- [ ] Backup files ignored
- [ ] Wildcard patterns work (**/)
- [ ] git status shows no credential files
