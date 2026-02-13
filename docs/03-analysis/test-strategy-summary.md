# ADW Improvement Project - Test Strategy Summary

**Quick Reference Guide for QA Team**

---

## Current Test Coverage Status

| Component | Coverage | Tests | Status |
|-----------|----------|-------|--------|
| Google MCP Unit Tests | 0% → Target 60% | 0/78 implemented | 🟡 In Progress |
| Installer Smoke Tests | 0% → Target 100% | 0/73 implemented | 🟡 In Progress |
| CI/CD Integration | Minimal | 1/4 workflows | 🟡 In Progress |

---

## Quick Start: Running Tests

### Unit Tests (Google MCP)

```bash
# Navigate to MCP directory
cd google-workspace-mcp

# Install dependencies (first time only)
npm install

# Run all tests
npm test

# Run tests in watch mode (during development)
npm run test:watch

# Generate coverage report
npm run test:coverage

# Open interactive UI
npm run test:ui
```

### Installer Smoke Tests

```bash
# Make scripts executable (first time only)
chmod +x installer/tests/*.sh

# Run module JSON validation
bash installer/tests/test_module_json.sh

# Run install script syntax check
bash installer/tests/test_install_syntax.sh

# Run module ordering check
bash installer/tests/test_module_ordering.sh

# Run all installer tests
for test in installer/tests/test_*.sh; do
  bash "$test"
done
```

### CI/CD Tests

```bash
# Trigger manual workflow
gh workflow run test.yml -f test_type=all

# Check workflow status
gh run list --workflow=test.yml
```

---

## Test Priority Map

### P0: Critical Security (10 tests) - Must Pass 100%

| ID | Test | Risk | File |
|----|------|------|------|
| TC-G01 | Header injection in gmail_send | CSRF/Phishing | gmail.test.ts |
| TC-G02 | Email address validation | Injection | gmail.test.ts |
| TC-D01 | Query escaping in drive_search | Data leak | drive.test.ts |
| TC-D02 | FolderId escaping in drive_list | Path traversal | drive.test.ts |
| TC-O01 | Token refresh flow | Auth bypass | oauth.test.ts |
| TC-O02 | State parameter validation (CSRF) | CSRF attack | oauth.test.ts |
| TC-O03 | Concurrent auth requests | Race condition | oauth.test.ts |
| TC-S01 | Input sanitization (Sheets) | Formula injection | sheets.test.ts |
| TC-D03 | Permission validation (Docs) | Unauthorized access | docs.test.ts |
| TC-A01 | Attachment size limit | DoS | gmail.test.ts |

**Action:** Block deployment if any P0 test fails.

---

### P1: Core Functionality (46 tests) - Must Pass 90%+

| Category | Tests | Target Coverage |
|----------|-------|-----------------|
| Gmail API calls | 8 | 90% |
| Drive API calls | 7 | 85% |
| Calendar timezone handling | 7 | 85% |
| Docs content manipulation | 5 | 80% |
| Sheets data operations | 7 | 85% |
| OAuth flow | 5 | 90% |
| Tool registration | 4 | 95% |
| Error handling | 3 | 80% |

**Action:** Block release if P1 pass rate < 90%.

---

### P2: Edge Cases (21 tests) - Should Pass 80%+

| Category | Tests |
|----------|-------|
| Gmail edge cases | 3 |
| Drive edge cases | 3 |
| Calendar edge cases | 3 |
| Docs edge cases | 3 |
| Sheets edge cases | 3 |
| OAuth edge cases | 2 |
| Installer edge cases | 4 |

**Action:** Document known issues if P2 pass rate < 80%.

---

## File Structure

```
ADW Improvement Project
├── google-workspace-mcp/
│   ├── src/
│   │   ├── tools/
│   │   │   ├── __tests__/
│   │   │   │   ├── gmail.test.ts       ✅ Created (15 tests)
│   │   │   │   ├── drive.test.ts       🟡 TODO (12 tests)
│   │   │   │   ├── calendar.test.ts    🟡 TODO (10 tests)
│   │   │   │   ├── docs.test.ts        🟡 TODO (8 tests)
│   │   │   │   ├── sheets.test.ts      🟡 TODO (10 tests)
│   │   │   │   └── slides.test.ts      🟡 TODO (5 tests)
│   │   │   ├── gmail.ts
│   │   │   ├── drive.ts
│   │   │   └── ...
│   │   ├── auth/
│   │   │   ├── __tests__/
│   │   │   │   └── oauth.test.ts       🟡 TODO (12 tests)
│   │   │   └── oauth.ts
│   │   └── __tests__/
│   │       └── index.test.ts           🟡 TODO (6 tests)
│   ├── __mocks__/
│   │   ├── googleapis.ts               🟡 TODO
│   │   └── open.ts                     🟡 TODO
│   ├── vitest.config.ts                ✅ Created
│   └── package.json                    ✅ Updated
│
├── installer/
│   └── tests/
│       ├── test_framework.sh           ✅ Created
│       ├── test_module_json.sh         ✅ Created
│       ├── test_install_syntax.sh      ✅ Created
│       └── test_module_ordering.sh     ✅ Created
│
├── .github/
│   └── workflows/
│       ├── test-installer.yml          ⚠️ Exists (needs update)
│       └── test.yml                    🟡 TODO (comprehensive)
│
└── docs/
    └── 03-analysis/
        ├── test-strategy.md            ✅ Created (full spec)
        └── test-strategy-summary.md    ✅ Created (this file)
```

---

## Implementation Roadmap (4 Weeks)

### Week 1: Test Infrastructure + P0 Security Tests
- [x] Day 1-2: Setup Vitest, create config, file structure
- [ ] Day 3-4: Implement all 10 P0 security tests
- [ ] Day 5: P0 validation (100% pass rate required)

### Week 2: P1 Core Functionality Tests
- [ ] Day 6-8: Gmail + Drive tests (15 tests)
- [ ] Day 9-10: Calendar + OAuth tests (12 tests)
- [ ] Day 11: P1 validation (90%+ pass rate required)

### Week 3: P2 Edge Cases + Installer Tests
- [ ] Day 12-13: Edge case tests (21 tests)
- [x] Day 14-15: Installer smoke tests (4 test suites)
- [ ] Day 16: Installer validation (all OS)

### Week 4: CI Integration + Documentation
- [ ] Day 17-18: Create comprehensive CI workflow
- [ ] Day 19: CI validation (all matrix cells)
- [ ] Day 20-21: Documentation + handoff

---

## Quality Gates

### Deployment Gate (Blocks Production Deployment)
- ✅ P0 Pass Rate: 100% (10/10 tests)
- ✅ No critical security vulnerabilities
- ⚠️ npm audit: severity <= moderate

### Release Gate (Blocks Release Candidate)
- ✅ P1 Pass Rate: 90%+ (42/46 tests)
- ✅ Total Coverage: 60%+
- ✅ All installer smoke tests pass

### GA Gate (General Availability)
- ✅ P2 Pass Rate: 80%+ (17/21 tests)
- ✅ CI passes on all OS targets
- ✅ Test documentation complete

---

## Known Security Gaps (Discovered During Test Design)

### 🔴 CRITICAL: Header Injection Not Prevented

**File:** `google-workspace-mcp/src/tools/gmail.ts`

**Issue:** Lines 113-121 construct email headers by string concatenation without sanitizing CRLF characters.

```typescript
// VULNERABLE CODE
const messageParts = [
  `To: ${to}`,                    // ⚠️ No CRLF sanitization
  cc ? `Cc: ${cc}` : "",          // ⚠️ No CRLF sanitization
  bcc ? `Bcc: ${bcc}` : "",       // ⚠️ No CRLF sanitization
  `Subject: =?UTF-8?B?${Buffer.from(subject).toString("base64")}?=`,
  ...
].filter(Boolean).join("\n");
```

**Attack Vector:**
```typescript
await gmail_send.handler({
  to: 'victim@example.com',
  subject: 'Invoice\r\nBcc: attacker@evil.com',
  body: 'Malicious email'
});
```

**Impact:** Attacker can inject additional recipients, modify headers, or perform phishing attacks.

**Recommended Fix:**
```typescript
function sanitizeEmailField(value: string): string {
  // Remove CRLF characters
  return value.replace(/[\r\n]/g, '');
}

function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email) && !email.includes('\r') && !email.includes('\n');
}

// Before constructing messageParts:
if (!validateEmail(to)) throw new Error('Invalid email address: to');
if (cc && !validateEmail(cc)) throw new Error('Invalid email address: cc');
if (bcc && !validateEmail(bcc)) throw new Error('Invalid email address: bcc');

const messageParts = [
  `To: ${sanitizeEmailField(to)}`,
  cc ? `Cc: ${sanitizeEmailField(cc)}` : "",
  bcc ? `Bcc: ${sanitizeEmailField(bcc)}` : "",
  `Subject: =?UTF-8?B?${Buffer.from(sanitizeEmailField(subject)).toString("base64")}?=`,
  ...
];
```

**Test Coverage:** TC-G01, TC-G02

---

### 🟡 MEDIUM: OAuth State Parameter Not Validated

**File:** `google-workspace-mcp/src/auth/oauth.ts`

**Issue:** Lines 114-118 generate auth URL without state parameter for CSRF protection.

**Recommended Fix:**
```typescript
// Generate random state
const state = crypto.randomBytes(16).toString('hex');

const authUrl = oauth2Client.generateAuthUrl({
  access_type: "offline",
  scope: SCOPES,
  prompt: "consent",
  state: state,  // Add CSRF protection
});

// Store state in memory or temp file
stateStore.set(state, Date.now());

// In callback handler, validate state
const receivedState = url.searchParams.get("state");
if (!receivedState || !stateStore.has(receivedState)) {
  throw new Error("Invalid state parameter - possible CSRF attack");
}
stateStore.delete(receivedState);
```

**Test Coverage:** TC-O02

---

### 🟡 MEDIUM: Drive Query Injection

**File:** `google-workspace-mcp/src/tools/drive.ts`

**Issue:** Lines 18-20 construct Drive API query without escaping single quotes.

```typescript
// VULNERABLE CODE
let q = `name contains '${query}' and trashed = false`;
```

**Attack Vector:**
```typescript
await drive_search.handler({
  query: "test' or trashed = true or name contains '",
  maxResults: 10
});
// Resulting query: name contains 'test' or trashed = true or name contains '' and trashed = false
```

**Recommended Fix:**
```typescript
function escapeQueryString(str: string): string {
  return str.replace(/'/g, "\\'");
}

let q = `name contains '${escapeQueryString(query)}' and trashed = false`;
```

**Test Coverage:** TC-D01, TC-D02

---

## Example Test Execution Output

### Successful Test Run
```
$ npm test

 ✓ src/tools/__tests__/gmail.test.ts (15 tests) 245ms
   ✓ Gmail Tools - Security Tests (P0) (3 tests)
     ✓ should prevent CRLF injection in subject field
     ✓ should prevent header injection via To field
     ✓ should prevent header injection via Cc field
   ✓ Gmail Tools - Core Functionality (P1) (10 tests)
     ✓ should parse multipart/alternative with text/plain
     ✓ should handle single-part message without parts array
     ✓ should truncate body to 5000 characters
     ...

 Test Files  1 passed (1)
      Tests  15 passed (15)
   Start at  10:30:00
   Duration  1.2s

 % Coverage report from v8
 -------------------|---------|----------|---------|---------|
 File               | % Stmts | % Branch | % Funcs | % Lines |
 -------------------|---------|----------|---------|---------|
 All files          |   68.5  |   55.2   |   72.1  |   68.5  |
  gmail.ts          |   72.3  |   60.5   |   75.0  |   72.3  |
  oauth.ts          |   65.8  |   50.0   |   70.0  |   65.8  |
 -------------------|---------|----------|---------|---------|
```

### Failed Test Run (Security Issue)
```
$ npm test

 ✗ src/tools/__tests__/gmail.test.ts (15 tests) 245ms
   ✗ Gmail Tools - Security Tests (P0) (3 tests)
     ✗ should prevent CRLF injection in subject field
       Expected: not to contain "Bcc: attacker@evil.com"
       Received: "To: victim@example.com\r\nSubject: Invoice\r\nBcc: attacker@evil.com\r\n\r\nMalicious email"

 Test Files  1 failed (1)
      Tests  1 failed | 14 passed (15)

❌ P0 Security Test Failed - Deployment Blocked
```

---

## Test Maintenance Guidelines

### Adding New Tests

1. Identify priority level (P0/P1/P2/P3)
2. Create test in appropriate `__tests__` directory
3. Follow naming convention: `describe('ToolName - Category')`
4. Add mocks to `__mocks__/googleapis.ts` if needed
5. Update this summary document

### Debugging Failed Tests

```bash
# Run single test file
npm test -- gmail.test.ts

# Run specific test by name
npm test -- -t "should prevent CRLF injection"

# Run with verbose output
npm test -- --reporter=verbose

# Run in UI mode for debugging
npm run test:ui
```

### CI Troubleshooting

```bash
# Check workflow syntax
gh workflow view test.yml

# View latest run
gh run view

# Re-run failed jobs
gh run rerun <run-id> --failed
```

---

## Team Contacts

| Role | Responsibility | Contact |
|------|---------------|---------|
| QA Strategist | Test strategy, coordination | This agent |
| Code Analyzer | Code quality, security scans | code-analyzer agent |
| Gap Detector | Design vs implementation gaps | gap-detector agent |
| PDCA Iterator | Auto-fix iterations | pdca-iterator agent |

---

## Related Documents

- **Full Test Strategy:** `/docs/03-analysis/test-strategy.md`
- **Plan Document:** `/docs/01-plan/features/adw-improvement.plan.md`
- **Design Document:** `/docs/02-design/features/adw-improvement.design.md` (TODO)
- **Security Report:** `/docs/03-analysis/security-verification-report.md`

---

**Last Updated:** 2026-02-12
**Next Review:** Week 2 (after P1 tests completed)
