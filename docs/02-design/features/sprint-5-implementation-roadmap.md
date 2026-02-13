# Sprint 5 UX Improvements - Implementation Roadmap

> Step-by-step guide for executing all Sprint 5 requirements

---

## Phase 1: Security & Foundation (Day 1 - 30 min)

### Task 1.1: FR-S5-06 - .gitignore Security Patch (P0)
**Priority**: CRITICAL - Prevents credential leaks
**Time**: 15 minutes

```bash
# 1. Open .gitignore
cd /Users/popup-kay/Documents/GitHub/popup/popup-claude
code .gitignore

# 2. Add security patterns (see sprint-5-code-snippets.md)
# Copy lines from FR-S5-06 section

# 3. Test
touch google-workspace-mcp/client_secret.json
git status | grep "client_secret" && echo "FAIL: Not ignored!" || echo "PASS: Ignored correctly"
rm google-workspace-mcp/client_secret.json

# 4. Commit immediately
git add .gitignore
git commit -m "feat(security): Add OAuth credential patterns to .gitignore (FR-S5-06)"
```

**Success Criteria**:
- [ ] All OAuth patterns added
- [ ] Test file not shown in `git status`
- [ ] Committed and pushed

---

### Task 1.2: FR-S5-04 - Version Bump (P0)
**Priority**: HIGH - Signals production readiness
**Time**: 15 minutes

```bash
# 1. Update package.json
cd google-workspace-mcp
code package.json
# Change line 3: "version": "1.0.0"

# 2. Create CHANGELOG.md
code CHANGELOG.md
# Copy content from sprint-5-code-snippets.md FR-S5-04

# 3. Build test
npm run build
# Expected: Success

# 4. Commit
git add package.json CHANGELOG.md
git commit -m "feat(release): Bump google-workspace-mcp to v1.0.0 (FR-S5-04)

- First stable release
- Production-ready for ADW Installer
- 6 Google Workspace services, 60+ tools
- Added CHANGELOG.md"

# 5. Tag release
git tag -a v1.0.0 -m "google-workspace-mcp v1.0.0 - First stable release"
```

**Success Criteria**:
- [ ] package.json shows 1.0.0
- [ ] CHANGELOG.md created
- [ ] Build succeeds
- [ ] Git tag created

---

## Phase 2: Internationalization (Day 2-3 - 3 hours)

### Task 2.1: FR-S5-05 - i18n Replacement (P1)
**Priority**: HIGH - Global accessibility
**Time**: 2-3 hours

**Approach**: File-by-file replacement with verification

```bash
cd google-workspace-mcp/src/tools

# Strategy: Replace one file at a time, build after each

# === File 1: calendar.ts (26 strings) ===
code calendar.ts
# Manual replacement using VS Code Find/Replace:
# Find: 사용 가능한 캘린더 목록을 조회합니다
# Replace: List available calendars
# (Repeat for all 26 calendar.ts strings)

npm run build
# If success, continue. If fail, fix TypeScript errors.

git add calendar.ts
git commit -m "feat(i18n): Internationalize calendar.ts messages (FR-S5-05)"

# === File 2: gmail.ts (42 strings) ===
code gmail.ts
# Repeat process
npm run build
git add gmail.ts
git commit -m "feat(i18n): Internationalize gmail.ts messages (FR-S5-05)"

# === File 3: drive.ts (38 strings) ===
code drive.ts
npm run build
git add drive.ts
git commit -m "feat(i18n): Internationalize drive.ts messages (FR-S5-05)"

# === File 4: docs.ts (18 strings) ===
code docs.ts
npm run build
git add docs.ts
git commit -m "feat(i18n): Internationalize docs.ts messages (FR-S5-05)"

# === File 5: sheets.ts (28 strings) ===
code sheets.ts
npm run build
git add sheets.ts
git commit -m "feat(i18n): Internationalize sheets.ts messages (FR-S5-05)"

# === File 6: slides.ts (24 strings) ===
code slides.ts
npm run build
git add slides.ts
git commit -m "feat(i18n): Internationalize slides.ts messages (FR-S5-05)"

# === Final verification ===
# Check no Korean characters remain
! grep -r "[\uAC00-\uD7AF]" src/tools/*.ts && echo "PASS: All Korean removed" || echo "FAIL: Korean found"

# Test MCP tools
cd ..
npm start &
sleep 5
claude mcp list
# Expected: All tool descriptions in English
kill %1
```

**Success Criteria**:
- [ ] All 6 tool files updated
- [ ] No Korean characters in codebase
- [ ] TypeScript compiles
- [ ] MCP tools show English descriptions

**Time-Saving Tip**: Use VS Code's multi-cursor editing
- Open sprint-5-ux-improvements.design.md Appendix A
- Copy search/replace pairs
- Use VS Code Find/Replace with regex

---

## Phase 3: Installer Enhancements (Day 4-5 - 7 hours)

### Task 3.1: FR-S5-01 - Post-Installation Verification (P1)
**Priority**: HIGH - User confidence
**Time**: 3-4 hours

```bash
cd installer
code install.sh

# Step 1: Add verification functions (after line 417)
# Copy entire verification block from sprint-5-code-snippets.md
# Functions to add:
# - verify_mcp_server()
# - verify_docker_mcp()
# - verify_remote_mcp()
# - verify_cli_tool()
# - verify_module_installation()
# - run_verification()

# Step 2: Add MODULE_TYPES array (around line 74)
# Add after MODULE_DISPLAY_NAMES declaration:
declare -a MODULE_TYPES

# Update module loading to capture type:
# In local module loading (line ~95):
MODULE_TYPES[$idx]=$(parse_json "$json" "type")

# In remote module loading (line ~115):
MODULE_TYPES[$idx]=$(parse_json "$json" "type")

# Step 3: Integrate verification call (replace lines 384-417)
# See sprint-5-code-snippets.md integration section

# Step 4: Test with each module type
./install.sh --modules google --skip-base
# Expected: Verification runs, shows OK/FAIL per check

./install.sh --modules notion --skip-base
# Expected: Remote MCP verification

# Step 5: Test failure scenarios
# Stop Docker Desktop
./install.sh --modules google --skip-base
# Expected: Docker not running error with troubleshooting

# Step 6: Commit
git add install.sh
git commit -m "feat(installer): Add post-installation verification (FR-S5-01)

- Health checks for MCP servers, Docker containers, CLI tools
- Retry logic for slow-starting services (3 attempts)
- Troubleshooting guidance on failure
- Verification summary with pass/fail counts
- User prompt to retry failed modules"
```

**Success Criteria**:
- [ ] Verification runs after installation
- [ ] All module types tested
- [ ] Retry logic works (3 attempts)
- [ ] Troubleshooting messages helpful
- [ ] Summary shows verified/failed counts

---

### Task 3.2: FR-S5-02 - Rollback Mechanism (P2)
**Priority**: MEDIUM - Safety net
**Time**: 2-3 hours

```bash
cd installer
code install.sh

# Step 1: Add rollback functions (after line 50)
# Copy rollback block from sprint-5-code-snippets.md:
# - BACKUP_TIMESTAMP, BACKUP_DIR, MCP_CONFIG, MCP_BACKUP
# - create_backup()
# - restore_backup()
# - cleanup_backup()
# - rollback_failed_module()

# Step 2: Integrate backup creation (before module loop, line ~220)
create_backup
SUCCESSFUL_MODULES=""

# Step 3: Modify module installation loop (line ~230)
# Add rollback prompt on failure
# See sprint-5-code-snippets.md integration example

# Step 4: Add backup cleanup (after verification, line ~380)
if [ -z "$FAILED_MODULES" ]; then
    cleanup_backup
fi

# Step 5: Test backup creation
./install.sh --modules google
# Check: ls ~/.claude/installer_backups/
# Expected: mcp.json.backup.YYYYMMDD_HHMMSS

# Step 6: Test rollback (simulate failure)
# During installation, stop Docker
# When prompted "Rollback Google? (y/n)", choose y
# Expected: MCP config restored, Docker image removed

# Step 7: Test cleanup
./install.sh --modules notion --skip-base
# Installation succeeds
# Check: ~/.claude/installer_backups/ should be empty

# Step 8: Commit
git add install.sh
git commit -m "feat(installer): Add rollback mechanism (FR-S5-02)

- Backup ~/.mcp.json before installation
- Restore on module failure (user prompted)
- Remove Docker images during rollback
- Cleanup backup after successful installation
- Timestamp-based backup naming"
```

**Success Criteria**:
- [ ] Backup created before installation
- [ ] Rollback prompt appears on failure
- [ ] MCP config restored correctly
- [ ] Docker artifacts removed
- [ ] Backup cleaned up on success

---

### Task 3.3: FR-S5-03 - ARCHITECTURE.md Sync (P2)
**Priority**: MEDIUM - Documentation accuracy
**Time**: 1 hour

```bash
cd installer
code ARCHITECTURE.md

# Step 1: Update Folder Structure (after line 111)
# Add Pencil module and shared/ directory
# Copy from sprint-5-code-snippets.md

# Step 2: Add Module Types section (after line 194)
# Document CLI tool type
# Add module.json metadata schema
# Copy from sprint-5-code-snippets.md

# Step 3: Add Execution Order section (new section)
# Document dependency resolution
# Show installation sequence
# Provide example execution
# Copy from sprint-5-code-snippets.md

# Step 4: Add Shared Utilities section (new section)
# Document verify.sh, rollback.sh, docker-utils.sh
# List functions per file
# Copy from sprint-5-code-snippets.md

# Step 5: Preview Markdown
# VS Code: Cmd+Shift+V or Install Markdown Preview extension

# Step 6: Validate all links
# Check that all referenced files exist

# Step 7: Commit
git add ARCHITECTURE.md
git commit -m "docs(installer): Sync ARCHITECTURE.md with current state (FR-S5-03)

- Add Pencil module documentation
- Document shared/ utilities directory
- Add module type metadata schema
- Document execution order and dependency resolution
- Add shared utility function reference"
```

**Success Criteria**:
- [ ] Pencil module documented
- [ ] shared/ directory explained
- [ ] Execution order section added
- [ ] Module metadata schema defined
- [ ] Markdown renders correctly
- [ ] All links valid

---

## Phase 4: Testing & Validation (Day 6 - 2 hours)

### Task 4.1: Integration Testing

```bash
# Test 1: Full installation with verification
cd installer
./install.sh --modules google,notion

# Expected flow:
# 1. Backup created
# 2. Base installation
# 3. Google installation
# 4. Notion installation
# 5. Verification runs (all pass)
# 6. Backup cleaned up
# 7. Summary shown

# Test 2: Failed installation with rollback
# Stop Docker Desktop
./install.sh --modules google

# Expected flow:
# 1. Backup created
# 2. Google installation fails
# 3. Prompted for rollback
# 4. Choose 'y'
# 5. MCP config restored
# 6. Docker image removed

# Test 3: Partial success
./install.sh --modules google,notion,pencil
# Stop Docker after Google installs
# Expected:
# - Google: Success
# - Notion: Success
# - Pencil: Fail (if Docker issue affects it)
# - Prompted to rollback Pencil only

# Test 4: Verification-only mode (if implemented)
./install.sh --verify-only

# Test 5: i18n verification
cd ../google-workspace-mcp
npm start &
sleep 5
claude mcp list
# Check all descriptions are English
kill %1

# Test 6: .gitignore validation
cd ..
touch google-workspace-mcp/client_secret.json
touch google-workspace-mcp/token.json
mkdir -p .claude/installer_backups
touch .claude/installer_backups/test.backup
git status
# Expected: None of these files shown
rm google-workspace-mcp/client_secret.json
rm google-workspace-mcp/token.json
rm -rf .claude/installer_backups
```

**Success Criteria**:
- [ ] Full installation works end-to-end
- [ ] Rollback works on failure
- [ ] Partial success handled correctly
- [ ] Verification catches all issues
- [ ] i18n applied (English messages)
- [ ] .gitignore blocks credential files

---

### Task 4.2: Documentation Review

```bash
# 1. Verify all design docs exist
ls -la docs/02-design/features/sprint-5*
# Expected:
# - sprint-5-ux-improvements.design.md
# - sprint-5-ux-improvements-summary.md
# - sprint-5-code-snippets.md
# - sprint-5-implementation-roadmap.md (this file)

# 2. Check ARCHITECTURE.md
cd installer
cat ARCHITECTURE.md | grep -i "pencil\|shared\|execution order"
# Expected: All mentioned

# 3. Check CHANGELOG
cd ../google-workspace-mcp
cat CHANGELOG.md | grep "1.0.0"
# Expected: Entry exists

# 4. Check package version
grep '"version"' package.json
# Expected: "1.0.0"
```

---

## Phase 5: Deployment (Day 7 - 1 hour)

### Task 5.1: Pre-Deployment Checklist

```bash
# 1. Build verification
cd google-workspace-mcp
npm run build
# Expected: Success, no warnings

# 2. TypeScript check
npm run type-check  # or tsc --noEmit
# Expected: No errors

# 3. Code quality (if ESLint configured)
npm run lint
# Expected: No errors

# 4. Installer smoke test
cd ../installer
./install.sh --modules google --skip-base
# Expected: Full cycle works

# 5. Git status
cd ..
git status
# Expected: No uncommitted changes

# 6. All commits present
git log --oneline | head -10
# Expected: See all FR-S5-* commits
```

---

### Task 5.2: Git Operations

```bash
# 1. Final commit (if any loose ends)
git add .
git commit -m "chore: Final Sprint 5 polish"

# 2. Push to remote
git push origin master
git push origin v1.0.0  # Push tag

# 3. Create GitHub Release (optional)
gh release create v1.0.0 \
  --title "google-workspace-mcp v1.0.0" \
  --notes "First stable release. See CHANGELOG.md for details."

# 4. Update project documentation (if needed)
# - Update main README.md
# - Update landing page version references
```

---

### Task 5.3: Announcement & Handoff

```markdown
# Sprint 5 Completion Report

## Completed Requirements

- ✅ FR-S5-01: Post-installation verification
  - Health checks for all module types
  - Retry logic (3 attempts)
  - Troubleshooting guidance

- ✅ FR-S5-02: Rollback mechanism
  - Backup ~/.mcp.json before installation
  - User-prompted rollback on failure
  - Cleanup after success

- ✅ FR-S5-03: ARCHITECTURE.md sync
  - Pencil module documented
  - shared/ utilities documented
  - Execution order explained

- ✅ FR-S5-04: Version bump to 1.0.0
  - package.json updated
  - CHANGELOG.md created
  - Git tag v1.0.0 created

- ✅ FR-S5-05: Message internationalization
  - 295 Korean strings → English
  - All 6 tool files updated
  - Build verified

- ✅ FR-S5-06: .gitignore enhancements
  - OAuth credential patterns
  - Backup file patterns
  - Private key patterns

## Metrics

- **Total Time**: ~12 hours (estimated)
- **Files Modified**: 10
  - installer/install.sh (+230 lines)
  - installer/ARCHITECTURE.md (+100 lines)
  - google-workspace-mcp/package.json (1 line)
  - google-workspace-mcp/CHANGELOG.md (new file, 50 lines)
  - google-workspace-mcp/src/tools/*.ts (6 files, 295 changes)
  - .gitignore (+30 lines)

- **Lines of Code**: +710
- **Test Coverage**: Manual testing (all module types)
- **Documentation**: 4 design documents created

## Next Steps

1. Monitor production installation metrics
2. Gather user feedback on verification messages
3. Consider automated testing for installer
4. Plan Sprint 6: Advanced features (monitoring, analytics)

## Known Issues

None

## Deployment

- Deployed to: master branch
- Tag: v1.0.0
- Release: github.com/popup-jacob/popup-claude/releases/v1.0.0
```

---

## Daily Schedule

### Day 1 (30 min)
- [ ] 09:00-09:15: FR-S5-06 .gitignore
- [ ] 09:15-09:30: FR-S5-04 Version bump

### Day 2 (3 hours)
- [ ] 09:00-10:00: FR-S5-05 calendar.ts + gmail.ts
- [ ] 10:00-11:00: FR-S5-05 drive.ts + docs.ts
- [ ] 11:00-12:00: FR-S5-05 sheets.ts + slides.ts + verification

### Day 3 (3 hours)
- [ ] 09:00-11:00: FR-S5-01 Verification functions
- [ ] 11:00-12:00: FR-S5-01 Integration + testing

### Day 4 (3 hours)
- [ ] 09:00-11:00: FR-S5-02 Rollback mechanism
- [ ] 11:00-12:00: FR-S5-02 Testing

### Day 5 (1 hour)
- [ ] 09:00-10:00: FR-S5-03 ARCHITECTURE.md update

### Day 6 (2 hours)
- [ ] 09:00-10:30: Integration testing (all FRs)
- [ ] 10:30-11:00: Documentation review

### Day 7 (1 hour)
- [ ] 09:00-09:30: Pre-deployment checks
- [ ] 09:30-10:00: Git operations + announcement

**Total: 6 days, 13.5 hours**

---

## Troubleshooting

### Issue: TypeScript errors after i18n replacement
**Solution**: Check for unclosed template strings, missing quotes
```bash
# Find syntax errors
npm run build 2>&1 | grep -A 3 "error TS"
```

### Issue: Verification not finding MCP server
**Solution**: Check ~/.mcp.json format
```bash
cat ~/.mcp.json | jq .
# Expected: Valid JSON with mcpServers key
```

### Issue: Rollback not restoring config
**Solution**: Check backup file exists
```bash
ls -la ~/.claude/installer_backups/
cat ~/.claude/installer_backups/.last_backup
```

### Issue: .gitignore not working
**Solution**: Git cache issue
```bash
git rm --cached google-workspace-mcp/client_secret.json
git commit -m "Remove cached credential file"
```

---

## Rollback Plan (If Sprint 5 Fails)

### Rollback Steps

```bash
# 1. Revert all commits
git log --oneline | grep "FR-S5"
# Copy commit hashes

git revert <commit-hash> --no-commit
# Repeat for each FR-S5 commit

git commit -m "Rollback Sprint 5 changes"

# 2. Restore package version
cd google-workspace-mcp
# Edit package.json: "version": "0.1.0"
git add package.json
git commit -m "Restore version to 0.1.0"

# 3. Delete tag
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

# 4. Push rollback
git push origin master
```

### Rollback Decision Criteria

Rollback if:
- [ ] Critical security issue found
- [ ] Installer completely broken (>50% failure rate)
- [ ] TypeScript build fails
- [ ] MCP tools non-functional

Do NOT rollback if:
- [ ] Minor UI/message issues (can be patched)
- [ ] Documentation typos (can be fixed in place)
- [ ] Single module verification fails (can be debugged)

---

## Contact & Support

**Product Manager**: bkit PM Agent
**Technical Lead**: popup-jacob
**Repository**: https://github.com/popup-jacob/popup-claude

**Sprint 5 Design Docs**:
- Design: `/docs/02-design/features/sprint-5-ux-improvements.design.md`
- Summary: `/docs/02-design/features/sprint-5-ux-improvements-summary.md`
- Code Snippets: `/docs/02-design/features/sprint-5-code-snippets.md`
- This Roadmap: `/docs/02-design/features/sprint-5-implementation-roadmap.md`
