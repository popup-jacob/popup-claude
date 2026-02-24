# Sprint 5 UX Improvements - Code Snippets

> Ready-to-use code for immediate implementation

---

## FR-S5-01: Verification Functions (install.sh)

### Location
File: `/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/install.sh`
Insert after: Line 417 (after installation complete message)

### Code

```bash
# ============================================
# POST-INSTALLATION VERIFICATION SYSTEM
# ============================================

verify_mcp_server() {
    local module_name="$1"
    local display_name="$2"
    local retry_count=0
    local max_retries=3

    while [ $retry_count -lt $max_retries ]; do
        if claude mcp list 2>/dev/null | grep -q "$module_name"; then
            echo -e "  ${GREEN}[OK] $display_name is registered${NC}"
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo -e "  ${YELLOW}[WAIT] Waiting for MCP server (attempt $retry_count/$max_retries)...${NC}"
            sleep 2
        fi
    done

    echo -e "  ${RED}[FAIL] $display_name not found in MCP server list${NC}"
    echo -e "  ${GRAY}Troubleshooting:${NC}"
    echo -e "    1. Check ~/.mcp.json configuration"
    echo -e "    2. Run: claude mcp list"
    echo -e "    3. Check logs: ~/.claude/mcp/logs/${NC}"
    return 1
}

verify_docker_mcp() {
    local module_name="$1"
    local display_name="$2"
    local image_name=""

    case "$module_name" in
        "google")
            image_name="google-workspace-mcp:latest"
            ;;
        "atlassian")
            image_name="atlassian-mcp:latest"
            ;;
        *)
            echo -e "  ${YELLOW}[WARN] Unknown Docker image for $module_name${NC}"
            return 1
            ;;
    esac

    if ! docker info > /dev/null 2>&1; then
        echo -e "  ${RED}[FAIL] Docker is not running${NC}"
        echo -e "  ${GRAY}Action: Start Docker Desktop and wait 15 seconds${NC}"
        return 1
    fi

    if ! docker images | grep -q "$image_name"; then
        echo -e "  ${RED}[FAIL] Docker image $image_name not found${NC}"
        echo -e "  ${GRAY}Action: Re-install module with --modules $module_name${NC}"
        return 1
    fi

    if docker run --rm "$image_name" node -e "process.exit(0)" > /dev/null 2>&1; then
        echo -e "  ${GREEN}[OK] $display_name Docker container functional${NC}"

        if claude mcp list 2>/dev/null | grep -q "$module_name"; then
            echo -e "  ${GREEN}[OK] $display_name registered in MCP${NC}"
            return 0
        else
            echo -e "  ${YELLOW}[WARN] Docker OK but MCP registration missing${NC}"
            echo -e "  ${GRAY}Action: Run claude mcp add $module_name${NC}"
            return 1
        fi
    else
        echo -e "  ${RED}[FAIL] Docker container execution failed${NC}"
        return 1
    fi
}

verify_remote_mcp() {
    local module_name="$1"
    local display_name="$2"

    if claude mcp list 2>/dev/null | grep -q "$module_name"; then
        echo -e "  ${GREEN}[OK] $display_name is registered${NC}"
        return 0
    else
        echo -e "  ${YELLOW}[WARN] $display_name not found in MCP list${NC}"
        echo -e "  ${GRAY}Action: Complete OAuth setup or run claude mcp add${NC}"
        return 1
    fi
}

verify_cli_tool() {
    local module_name="$1"
    local display_name="$2"
    local command=""

    case "$module_name" in
        "github")
            command="gh"
            ;;
        "pencil")
            command="pencil"
            ;;
        *)
            echo -e "  ${YELLOW}[WARN] Unknown CLI for $module_name${NC}"
            return 1
            ;;
    esac

    if command -v "$command" > /dev/null 2>&1; then
        echo -e "  ${GREEN}[OK] $display_name CLI installed${NC}"
        return 0
    else
        echo -e "  ${RED}[FAIL] $display_name CLI not found in PATH${NC}"
        echo -e "  ${GRAY}Action: Re-login to shell or re-install${NC}"
        return 1
    fi
}

verify_module_installation() {
    local module_name="$1"
    local idx=$(get_module_index "$module_name")
    local display_name="${MODULE_DISPLAY_NAMES[$idx]}"
    local module_type="${MODULE_TYPES[$idx]}"

    echo -e "\n${CYAN}Verifying ${display_name}...${NC}"

    case "$module_type" in
        "mcp-server")
            verify_mcp_server "$module_name" "$display_name"
            ;;
        "docker-mcp")
            verify_docker_mcp "$module_name" "$display_name"
            ;;
        "remote-mcp")
            verify_remote_mcp "$module_name" "$display_name"
            ;;
        "cli")
            verify_cli_tool "$module_name" "$display_name"
            ;;
        *)
            echo -e "  ${YELLOW}[WARN] Unknown module type: $module_type${NC}"
            return 1
            ;;
    esac
}

run_verification() {
    echo ""
    echo "========================================"
    echo -e "${CYAN}  Post-Installation Verification${NC}"
    echo "========================================"
    echo ""

    local failed_modules=""
    local verified_count=0
    local failed_count=0

    # Verify base (if not skipped)
    if [ "$SKIP_BASE" = false ]; then
        echo -e "${CYAN}Verifying base components...${NC}"

        if command -v node > /dev/null 2>&1; then
            echo -e "  ${GREEN}[OK] Node.js $(node --version)${NC}"
            verified_count=$((verified_count + 1))
        else
            echo -e "  ${RED}[FAIL] Node.js not found${NC}"
            failed_modules="$failed_modules node"
            failed_count=$((failed_count + 1))
        fi

        if command -v claude > /dev/null 2>&1; then
            echo -e "  ${GREEN}[OK] Claude Code CLI${NC}"
            verified_count=$((verified_count + 1))
        else
            echo -e "  ${RED}[FAIL] Claude Code CLI not found${NC}"
            failed_modules="$failed_modules claude"
            failed_count=$((failed_count + 1))
        fi

        if claude plugin list 2>/dev/null | grep -q "bkit"; then
            echo -e "  ${GREEN}[OK] bkit Plugin${NC}"
            verified_count=$((verified_count + 1))
        else
            echo -e "  ${YELLOW}[WARN] bkit Plugin not installed${NC}"
            failed_count=$((failed_count + 1))
        fi
        echo ""
    fi

    # Verify selected modules
    for mod in $SELECTED_MODULES; do
        if verify_module_installation "$mod"; then
            verified_count=$((verified_count + 1))
        else
            failed_modules="$failed_modules $mod"
            failed_count=$((failed_count + 1))
        fi
    done

    # Summary
    echo ""
    echo "========================================"
    echo -e "${CYAN}  Verification Summary${NC}"
    echo "========================================"
    echo -e "  ${GREEN}Verified: $verified_count${NC}"
    echo -e "  ${RED}Failed: $failed_count${NC}"

    if [ $failed_count -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Failed modules:${NC}$failed_modules"
        echo ""
        echo -e "${YELLOW}Retry failed modules? (y/n)${NC}"
        read -p "> " retry_choice < /dev/tty

        if [ "$retry_choice" = "y" ] || [ "$retry_choice" = "Y" ]; then
            return 1
        fi
    fi

    return 0
}
```

### Integration (replace lines 384-417)

```bash
# Call verification before completion message
if ! run_verification; then
    echo -e "${YELLOW}Some verifications failed. Check messages above.${NC}"
fi

echo ""
echo "========================================"
echo -e "${GREEN}  Installation Complete!${NC}"
echo "========================================"
echo ""
read -p "Press Enter to close" < /dev/tty
```

---

## FR-S5-02: Rollback Mechanism (install.sh)

### Location
File: `/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/install.sh`
Insert after: Line 50 (after color definitions)

### Code

```bash
# ============================================
# ROLLBACK MECHANISM
# ============================================

BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.claude/installer_backups"
MCP_CONFIG="$HOME/.mcp.json"
MCP_BACKUP="$BACKUP_DIR/mcp.json.backup.$BACKUP_TIMESTAMP"

create_backup() {
    mkdir -p "$BACKUP_DIR"

    if [ -f "$MCP_CONFIG" ]; then
        cp "$MCP_CONFIG" "$MCP_BACKUP"
        echo -e "${GRAY}[Backup] Created: $MCP_BACKUP${NC}"
    else
        echo "{}" > "$MCP_BACKUP"
        echo -e "${GRAY}[Backup] No existing MCP config, created empty backup${NC}"
    fi

    echo "$MCP_BACKUP" > "$BACKUP_DIR/.last_backup"
}

restore_backup() {
    local backup_file="$1"

    if [ -z "$backup_file" ]; then
        if [ -f "$BACKUP_DIR/.last_backup" ]; then
            backup_file=$(cat "$BACKUP_DIR/.last_backup")
        else
            echo -e "${RED}No backup found${NC}"
            return 1
        fi
    fi

    if [ -f "$backup_file" ]; then
        cp "$backup_file" "$MCP_CONFIG"
        echo -e "${GREEN}[Restore] MCP config restored from backup${NC}"
        return 0
    else
        echo -e "${RED}Backup file missing: $backup_file${NC}"
        return 1
    fi
}

cleanup_backup() {
    if [ -f "$MCP_BACKUP" ]; then
        rm "$MCP_BACKUP"
        echo -e "${GRAY}[Cleanup] Removed backup${NC}"
    fi

    if [ -f "$BACKUP_DIR/.last_backup" ]; then
        rm "$BACKUP_DIR/.last_backup"
    fi
}

rollback_failed_module() {
    local module_name="$1"
    local display_name="$2"

    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  Rollback: $display_name${NC}"
    echo -e "${YELLOW}========================================${NC}"

    # Remove Docker artifacts
    case "$module_name" in
        "google")
            if docker images | grep -q "google-workspace-mcp"; then
                echo -e "${GRAY}Removing Docker image...${NC}"
                docker rmi google-workspace-mcp:latest 2>/dev/null || true
            fi
            ;;
        "atlassian")
            if docker images | grep -q "atlassian-mcp"; then
                echo -e "${GRAY}Removing Docker image...${NC}"
                docker rmi atlassian-mcp:latest 2>/dev/null || true
            fi
            ;;
    esac

    # Restore MCP config
    restore_backup

    echo -e "${GREEN}Rollback complete for $display_name${NC}"
}
```

### Integration (before module installation loop)

```bash
# Line ~220: Before module installation
# Create backup
create_backup
SUCCESSFUL_MODULES=""

# Inside module loop (line ~230)
for mod in $SELECTED_MODULES; do
    idx=$(get_module_index "$mod")
    display_name="${MODULE_DISPLAY_NAMES[$idx]}"

    echo ""
    echo "[$((current))/$total] Installing $display_name..."

    if install_module_$mod; then
        SUCCESSFUL_MODULES="$SUCCESSFUL_MODULES $mod"
        echo -e "${GREEN}[OK] $display_name installed${NC}"
    else
        echo -e "${RED}[FAIL] $display_name installation failed${NC}"
        echo ""
        echo -e "${YELLOW}Rollback $display_name? (y/n)${NC}"
        read -p "> " rollback_choice < /dev/tty

        if [ "$rollback_choice" = "y" ] || [ "$rollback_choice" = "Y" ]; then
            rollback_failed_module "$mod" "$display_name"
        fi
    fi

    current=$((current + 1))
done

# After all installations (line ~380)
# Cleanup backup if successful
if [ -z "$FAILED_MODULES" ]; then
    cleanup_backup
fi
```

---

## FR-S5-03: ARCHITECTURE.md Updates

### Location
File: `/Users/popup-kay/Documents/GitHub/popup/popup-claude/installer/ARCHITECTURE.md`

### Addition 1: Folder Structure (after line 111)

```markdown
│   ├── pencil/              # Pencil Protocol Builder (CLI)
│   │   ├── module.json
│   │   ├── install.ps1
│   │   └── install.sh
│   │
├── shared/                  # Shared utilities
│   ├── verify.sh            # Post-installation verification
│   ├── rollback.sh          # Rollback utilities
│   └── docker-utils.sh      # Docker helper functions
```

### Addition 2: Module Types (after line 194)

```markdown
### 3. CLI Tool Modules
- Pencil Protocol Builder
- GitHub CLI
- Docker not required
- Native binary installation
- Adds to system PATH

---

## Module Type Metadata

Each `module.json` defines:

```json
{
  "name": "google",
  "displayName": "Google Workspace",
  "type": "docker-mcp",
  "dependencies": ["docker"],
  "description": "Gmail, Drive, Docs, Sheets, Slides, Calendar"
}
```

**Module Types:**
- `mcp-server`: Local Node.js MCP server
- `docker-mcp`: Dockerized MCP server
- `remote-mcp`: Cloud-hosted MCP (OAuth required)
- `cli`: CLI tool installation
```

### Addition 3: Execution Order (new section after Module Types)

```markdown
---

## Module Execution Order

### Dependency Resolution

```
┌────────────────────────────────────┐
│  1. Parse module.json (all)        │
│  2. Build dependency graph         │
│  3. Topological sort               │
│  4. Execute in order               │
└────────────────────────────────────┘
```

### Installation Sequence

1. **Base** (always first)
   - Node.js, Git
   - Claude Code CLI
   - bkit plugin

2. **Docker-dependent**
   - Install/start Docker Desktop
   - Pull/build images
   - Configure MCP

3. **Independent modules**
   - Remote MCP (Notion, Figma)
   - CLI tools (Pencil, GitHub)

### Example

User selects: `google,notion,pencil`

Execution order:
```
base → docker → google → notion → pencil
```

**Reason**: `google` depends on Docker. `notion` and `pencil` are independent (parallel-safe).

---

## Shared Utilities

| File | Purpose | Used By |
|------|---------|---------|
| `verify.sh` | Post-installation verification | All modules |
| `rollback.sh` | Backup/restore MCP config | Main installer |
| `docker-utils.sh` | Docker health checks | Docker modules |

### verify.sh Functions

- `verify_mcp_server()` - MCP registration check
- `verify_docker_mcp()` - Docker container test
- `verify_remote_mcp()` - OAuth/API validation
- `verify_cli_tool()` - CLI availability check

### rollback.sh Functions

- `create_backup()` - Backup ~/.mcp.json
- `restore_backup()` - Restore from backup
- `rollback_module()` - Remove module artifacts
```

---

## FR-S5-04: Version Bump

### File 1: package.json

```diff
File: /Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp/package.json

{
  "name": "google-workspace-mcp",
- "version": "0.1.0",
+ "version": "1.0.0",
  "description": "MCP Server for Google Workspace (Gmail, Drive, Docs, Sheets, Slides, Calendar)",
```

### File 2: CHANGELOG.md (new file)

```markdown
File: /Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp/CHANGELOG.md

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-12

### Added
- Full support for 6 Google Workspace services:
  - Gmail (search, send, drafts, labels)
  - Drive (files, folders, permissions, sharing)
  - Docs (create, read, edit, comments)
  - Sheets (create, read, write, format)
  - Slides (create, add slides, text, images)
  - Calendar (events, schedules, free/busy)
- MCP SDK 1.0.0 integration
- OAuth 2.0 authentication flow
- Docker containerization support
- 60+ tools across all services

### Changed
- Version bump from 0.1.0 to 1.0.0 (first stable release)
- Production-ready for ADW Installer integration

### Fixed
- N/A (first major release)

## [0.1.0] - 2025-12-15

### Added
- Initial development version
- Basic Gmail and Drive support
- OAuth setup
```

---

## FR-S5-05: i18n Replacements

### calendar.ts (Example - Full 26 replacements)

```diff
File: /Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp/src/tools/calendar.ts

export const calendarTools = {
  calendar_list_calendars: {
-   description: "사용 가능한 캘린더 목록을 조회합니다",
+   description: "List available calendars",
    schema: {},
    handler: async () => {
      // ...
    },
  },

  calendar_list_events: {
-   description: "캘린더 일정 목록을 조회합니다",
+   description: "List calendar events",
    schema: {
-     calendarId: z.string().optional().default("primary").describe("캘린더 ID (기본: primary)"),
+     calendarId: z.string().optional().default("primary").describe("Calendar ID (default: primary)"),
-     timeMin: z.string().optional().describe("시작 시간 (ISO 형식)"),
+     timeMin: z.string().optional().describe("Start time (ISO format)"),
-     timeMax: z.string().optional().describe("종료 시간 (ISO 형식)"),
+     timeMax: z.string().optional().describe("End time (ISO format)"),
-     maxResults: z.number().optional().default(10).describe("최대 결과 수"),
+     maxResults: z.number().optional().default(10).describe("Maximum results"),
-     query: z.string().optional().describe("검색어"),
+     query: z.string().optional().describe("Search query"),
    },
    // ...
  },

  calendar_create_event: {
-   description: "새 캘린더 일정을 생성합니다",
+   description: "Create a new calendar event",
    schema: {
-     title: z.string().describe("일정 제목"),
+     title: z.string().describe("Event title"),
-     startTime: z.string().describe("시작 시간 (ISO 형식 또는 'YYYY-MM-DD HH:mm')"),
+     startTime: z.string().describe("Start time (ISO format or 'YYYY-MM-DD HH:mm')"),
-     endTime: z.string().describe("종료 시간 (ISO 형식 또는 'YYYY-MM-DD HH:mm')"),
+     endTime: z.string().describe("End time (ISO format or 'YYYY-MM-DD HH:mm')"),
-     description: z.string().optional().describe("일정 설명"),
+     description: z.string().optional().describe("Event description"),
-     location: z.string().optional().describe("장소"),
+     location: z.string().optional().describe("Location"),
-     attendees: z.array(z.string()).optional().describe("참석자 이메일 목록"),
+     attendees: z.array(z.string()).optional().describe("Attendee email list"),
-     sendNotifications: z.boolean().optional().default(true).describe("참석자에게 알림 발송 여부"),
+     sendNotifications: z.boolean().optional().default(true).describe("Send notifications to attendees"),
    },
    handler: async ({ ... }) => {
      // ...
      return {
        success: true,
-       message: `일정 "${title}"이 생성되었습니다.`,
+       message: `Event "${title}" created successfully.`,
-       attendeesNotified: attendees && sendNotifications ? `${attendees.join(", ")}에게 초대가 발송되었습니다.` : null,
+       attendeesNotified: attendees && sendNotifications ? `Invitations sent to ${attendees.join(", ")}.` : null,
      };
    },
  },

  // Continue for all remaining tools...
};
```

### Quick Search-Replace Script

```bash
# Create bash script for bulk replacement
cat > /tmp/i18n-replace.sh << 'EOF'
#!/bin/bash
FILES="google-workspace-mcp/src/tools/*.ts"

# Calendar replacements
sed -i '' 's/사용 가능한 캘린더 목록을 조회합니다/List available calendars/g' $FILES
sed -i '' 's/캘린더 일정 목록을 조회합니다/List calendar events/g' $FILES
sed -i '' 's/캘린더 ID (기본: primary)/Calendar ID (default: primary)/g' $FILES
# ... (add all 295 replacements)

echo "i18n replacement complete"
EOF

chmod +x /tmp/i18n-replace.sh
/tmp/i18n-replace.sh
```

---

## FR-S5-06: .gitignore Update

```diff
File: /Users/popup-kay/Documents/GitHub/popup/popup-claude/.gitignore

# Claude Code
.claude/
REVIEW_CHECKLIST.md

# bkit plugin (auto-generated tracking files)
.bkit-memory.json
.pdca-status.json
.pdca-snapshots/

# Dependencies
node_modules/

# Build outputs
dist/
build/
.next/
out/

# Environment
.env
.env.local
.env.*.local

+# ==================================================
+# CRITICAL - OAuth Credentials (NEVER COMMIT!)
+# ==================================================
+
+# Google Workspace MCP
+google-workspace-mcp/client_secret.json
+google-workspace-mcp/client_secret_*.json
+google-workspace-mcp/credentials.json
+google-workspace-mcp/token.json
+google-workspace-mcp/tokens/*.json
+google-workspace-mcp/.google-workspace/
+
+# Generic OAuth patterns (all modules)
+**/client_secret.json
+**/token.json
+**/credentials.json
+
+# Installer Backups (may contain credentials)
+installer/.backups/
+.claude/installer_backups/
+*.mcp.json.backup*
+
+# Module-specific credential directories
+atlassian-mcp/.atlassian/
+notion-mcp/.notion/
+figma-mcp/.figma/
+github-mcp/.github/
+
+# Private Keys
+*.pem
+*.key
+*.p12
+*.pfx
+*.crt
+*.cer

# Logs
*.log
npm-debug.log*

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.swp
*.swo

# Test
coverage/

# Temporary
*.tmp
*.temp
landing-page/
```

---

## Testing Commands

### FR-S5-01: Verification

```bash
# Test verification standalone
cd installer
./install.sh --modules google --skip-base

# Expected output:
# ========================================
#   Post-Installation Verification
# ========================================
# Verifying Google Workspace...
#   [OK] Google Workspace is registered in MCP
#   [OK] Google Workspace Docker container functional
```

### FR-S5-02: Rollback

```bash
# Simulate failed installation
cd installer
./install.sh --modules google

# During installation, stop Docker Desktop
# Expected: Rollback prompt appears

# Test manual rollback
source install.sh
create_backup
# ... make changes ...
restore_backup
```

### FR-S5-04: Version Check

```bash
cd google-workspace-mcp
npm run build
node -p "require('./package.json').version"
# Expected: 1.0.0
```

### FR-S5-05: i18n Check

```bash
cd google-workspace-mcp
# Check for Korean characters
grep -r "[\uAC00-\uD7AF]" src/tools/*.ts
# Expected: No matches (exit code 1)

# Build test
npm run build
# Expected: Success
```

### FR-S5-06: .gitignore Test

```bash
# Create test files
touch google-workspace-mcp/client_secret.json
touch .claude/installer_backups/test.backup

# Verify ignored
git status
# Expected: These files should NOT appear

# Cleanup
rm google-workspace-mcp/client_secret.json
rm -rf .claude/installer_backups
```

---

## Build Validation

```bash
# Full build test
cd /Users/popup-kay/Documents/GitHub/popup/popup-claude

# 1. Version check
grep '"version"' google-workspace-mcp/package.json
# Expected: "1.0.0"

# 2. i18n check
! grep -r "[\uAC00-\uD7AF]" google-workspace-mcp/src/tools/*.ts
# Expected: Exit code 0 (no Korean found)

# 3. TypeScript compile
cd google-workspace-mcp
npm run build
# Expected: No errors

# 4. .gitignore test
cd ..
touch google-workspace-mcp/token.json
! git status | grep "token.json"
# Expected: Exit code 0 (file ignored)
rm google-workspace-mcp/token.json

# 5. Installer dry-run
cd installer
./install.sh --list
# Expected: Shows all modules with metadata
```

---

## Deployment Checklist

- [ ] **FR-S5-06** (Security)
  - [ ] Update .gitignore
  - [ ] Test with real credential files
  - [ ] Verify git status shows no secrets
  - [ ] Commit .gitignore changes

- [ ] **FR-S5-04** (Version)
  - [ ] Update package.json (1.0.0)
  - [ ] Create CHANGELOG.md
  - [ ] Test npm build
  - [ ] Tag release: `git tag v1.0.0`

- [ ] **FR-S5-05** (i18n)
  - [ ] Replace calendar.ts (26 strings)
  - [ ] Replace docs.ts (45 strings)
  - [ ] Replace drive.ts (58 strings)
  - [ ] Replace gmail.ts (62 strings)
  - [ ] Replace sheets.ts (48 strings)
  - [ ] Replace slides.ts (40 strings)
  - [ ] Run TypeScript build
  - [ ] Test MCP tools: `claude mcp list`

- [ ] **FR-S5-01** (Verification)
  - [ ] Add verification functions
  - [ ] Integrate into install.sh
  - [ ] Test with each module type
  - [ ] Verify troubleshooting messages

- [ ] **FR-S5-02** (Rollback)
  - [ ] Add rollback functions
  - [ ] Test backup creation
  - [ ] Test restore after failure
  - [ ] Test cleanup after success

- [ ] **FR-S5-03** (Documentation)
  - [ ] Update ARCHITECTURE.md
  - [ ] Add Pencil section
  - [ ] Add shared/ documentation
  - [ ] Add execution order section
  - [ ] Verify Markdown renders correctly

---

## Quick Reference

| FR | Files Modified | Lines Changed | Test Command |
|----|---------------|---------------|--------------|
| S5-01 | `installer/install.sh` | +150 | `./install.sh --modules google` |
| S5-02 | `installer/install.sh` | +80 | Manual test with Docker stop |
| S5-03 | `installer/ARCHITECTURE.md` | +100 | Markdown preview |
| S5-04 | `package.json`, `CHANGELOG.md` | +50 | `npm run build` |
| S5-05 | `src/tools/*.ts` (6 files) | +295 | `npm run build && claude mcp list` |
| S5-06 | `.gitignore` | +30 | `git status` after creating test files |
