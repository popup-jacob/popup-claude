# ADW Improvement Project - Test Quick Start Guide

**5-Minute Setup Guide for Developers**

---

## Installation (One-Time Setup)

```bash
# 1. Install Google MCP test dependencies
cd google-workspace-mcp
npm install

# 2. Make installer test scripts executable
chmod +x installer/tests/*.sh

# 3. Install jq (for installer tests)
# macOS:
brew install jq

# Linux:
sudo apt-get install jq

# Windows (Git Bash):
choco install jq
```

---

## Running Tests

### Unit Tests (Google MCP)

```bash
# Quick test run
cd google-workspace-mcp
npm test

# Watch mode (auto re-run on file changes)
npm run test:watch

# Coverage report
npm run test:coverage
open coverage/index.html  # View in browser

# Interactive UI
npm run test:ui
```

### Installer Tests

```bash
# Run all installer tests
cd installer/tests
bash test_module_json.sh
bash test_install_syntax.sh
bash test_module_ordering.sh

# Or run all at once
for test in installer/tests/test_*.sh; do bash "$test"; done
```

---

## Test File Locations

```
google-workspace-mcp/
  src/tools/__tests__/
    ✅ gmail.test.ts       (15 tests - DONE)
    🟡 drive.test.ts       (12 tests - TODO)
    🟡 calendar.test.ts    (10 tests - TODO)
    🟡 docs.test.ts        (8 tests - TODO)
    🟡 sheets.test.ts      (10 tests - TODO)
    🟡 slides.test.ts      (5 tests - TODO)
  src/auth/__tests__/
    🟡 oauth.test.ts       (12 tests - TODO)
  src/__tests__/
    🟡 index.test.ts       (6 tests - TODO)

installer/tests/
  ✅ test_framework.sh
  ✅ test_module_json.sh
  ✅ test_install_syntax.sh
  ✅ test_module_ordering.sh
```

---

## Writing Your First Test

### Example: Gmail Test

```typescript
// google-workspace-mcp/src/tools/__tests__/gmail.test.ts

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { gmailTools } from '../gmail';

// Mock the API
const mockGmailApi = {
  users: {
    messages: {
      send: vi.fn(),
    },
  },
};

vi.mock('../../auth/oauth', () => ({
  getGoogleServices: vi.fn(async () => ({
    gmail: mockGmailApi,
  })),
}));

describe('gmail_send', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should send email successfully', async () => {
    // Arrange
    mockGmailApi.users.messages.send.mockResolvedValue({
      data: { id: 'msg123' },
    });

    // Act
    const result = await gmailTools.gmail_send.handler({
      to: 'test@example.com',
      subject: 'Test',
      body: 'Test body',
    });

    // Assert
    expect(result.success).toBe(true);
    expect(result.messageId).toBe('msg123');
    expect(mockGmailApi.users.messages.send).toHaveBeenCalledTimes(1);
  });
});
```

---

## Test Priorities

### 🔴 P0: Critical Security (Must Pass 100%)

Test these first! Deployment blocked if any fail.

- [ ] TC-G01: Header injection in gmail_send
- [ ] TC-G02: Email validation
- [ ] TC-D01: Query escaping in drive_search
- [ ] TC-O01: Token refresh flow
- [ ] TC-O02: OAuth CSRF protection

### 🟡 P1: Core Functionality (Must Pass 90%+)

- [ ] TC-G03: MIME parsing
- [ ] TC-G04: Attachment handling
- [ ] TC-C01: Timezone handling
- [ ] TC-D03: Shared drive support

### 🟢 P2: Edge Cases (Should Pass 80%+)

- [ ] Empty search results
- [ ] Large files
- [ ] Network errors

---

## Common Test Patterns

### Pattern 1: Mock API Response

```typescript
mockGmailApi.users.messages.get.mockResolvedValue({
  data: {
    id: 'msg123',
    payload: { headers: [] },
  },
});
```

### Pattern 2: Test Error Handling

```typescript
mockGmailApi.users.messages.send.mockRejectedValue(
  new Error('API Error')
);

await expect(
  gmailTools.gmail_send.handler({ to: 'test@test.com', subject: '', body: '' })
).rejects.toThrow('API Error');
```

### Pattern 3: Validate Function Calls

```typescript
expect(mockGmailApi.users.messages.send).toHaveBeenCalledWith({
  userId: 'me',
  requestBody: expect.objectContaining({
    raw: expect.any(String),
  }),
});
```

---

## CI/CD Integration

### GitHub Actions Workflow

Tests run automatically on:
- Push to `master` or `develop`
- Pull requests
- Manual trigger via `workflow_dispatch`

### Check Test Status

```bash
# View workflow runs
gh run list --workflow=test.yml

# View specific run
gh run view <run-id>

# Re-run failed tests
gh run rerun <run-id> --failed
```

---

## Coverage Requirements

| Component | Threshold | Current |
|-----------|-----------|---------|
| Lines | 60% | 0% |
| Functions | 60% | 0% |
| Branches | 50% | 0% |
| P0 Tests | 100% | 0/10 |
| P1 Tests | 90% | 0/46 |

---

## Debugging Failed Tests

### Run Single Test

```bash
npm test -- gmail.test.ts
```

### Run Specific Test by Name

```bash
npm test -- -t "should prevent CRLF injection"
```

### Interactive Debugging

```bash
# Start UI mode
npm run test:ui

# Or use watch mode
npm run test:watch
```

### View Coverage Report

```bash
npm run test:coverage
open coverage/index.html
```

---

## Known Issues (Security Gaps)

### 🔴 CRITICAL: Header Injection Not Prevented

**File:** `src/tools/gmail.ts` (lines 113-121)

**Issue:** CRLF characters not sanitized in email headers.

**Test:** TC-G01 currently FAILS (expected behavior)

**Fix:** Add input sanitization before this PR can be merged.

### 🟡 MEDIUM: OAuth CSRF Protection Missing

**File:** `src/auth/oauth.ts` (line 114)

**Issue:** No state parameter validation.

**Test:** TC-O02 (TODO)

**Fix:** Implement state parameter generation and validation.

---

## Getting Help

### Documentation

- **Full Test Strategy:** `/docs/03-analysis/test-strategy.md`
- **Summary:** `/docs/03-analysis/test-strategy-summary.md`
- **Vitest Docs:** https://vitest.dev/

### Team Contacts

- **QA Strategist:** Test strategy and design
- **Code Analyzer:** Security scans
- **Gap Detector:** Coverage analysis

---

## Next Steps

1. **Week 1:** Implement P0 security tests (10 tests)
2. **Week 2:** Implement P1 core functionality tests (46 tests)
3. **Week 3:** Implement P2 edge case tests (21 tests)
4. **Week 4:** CI/CD integration and documentation

---

**Last Updated:** 2026-02-12
**Status:** Test infrastructure ready, implementation in progress
