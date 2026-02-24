# ADW Comprehensive Improvement — Design Document

> **Summary**: 65.5% Match Rate 분석 기반, 5개 Sprint / 48개 요구사항(44 기본 + 4 신규)의 보안·품질·호환성 전면 개선 상세 설계
>
> **Feature**: adw-improvement
> **Version**: 1.2
> **Date**: 2026-02-13
> **Author**: CTO Team (8 전문 에이전트 병렬 설계)
> **Plan Reference**: `docs/01-plan/features/adw-improvement.plan.md` (v2.2)
> **Security Spec**: `docs/02-design/security-spec.md` (v1.2, FR-S1-11 + Security Logging 포함)
> **Analysis References**:
> - `docs/03-analysis/adw-comprehensive.analysis.md` (종합 분석, Match Rate 65.5%)
> - `docs/03-analysis/security-verification-report.md` (12건 보안 이슈 수동 검증)
> - `docs/03-analysis/shared-utilities-design.md` (10개 공유 유틸리티 상세 설계)
> - `docs/03-analysis/adw-requirements-traceability-matrix.md` (44 FR, 89.6% 커버리지)
> **Gap Analysis**:
> - `docs/03-analysis/gap-security-verification.md` (보안 갭 6P + 4D)
> - `docs/03-analysis/gap-shared-utilities.md` (공유 유틸 갭 15P + 20D)
> - `docs/03-analysis/gap-requirements-traceability.md` (추적 갭 19건)
> **Status**: Draft (v1.2 -- 7개 분석문서 전수 교차 검증 반영)

---

## 1. Overview

### 1.1 Design Goals

본 설계서는 ADW 종합 분석 보고서(Match Rate 65.5%)에서 도출된 48개 이슈(Security 3 Critical / 8 High, Quality 9건, OS 10건)를 해결하기 위한 44개 요구사항에 대한 **구체적 구현 설계**를 제공한다.

**설계 원칙**:
1. **보안 우선** — OWASP Top 10 매핑, 모든 입력 검증
2. **하위 호환** — 기존 macOS 사용자 환경 유지, 점진적 마이그레이션
3. **테스트 가능** — 모든 변경사항에 대한 검증 방법 명시
4. **최소 변경** — 필요한 변경만 수행, 과도한 추상화 지양

### 1.2 CTO Team Agent Composition

| Agent | Role | Sprint Coverage | Output |
|-------|------|----------------|--------|
| Security Architect | 보안 설계 | Sprint 1 (10 FRs) | `docs/02-design/security-spec.md` |
| Enterprise Expert | 인스톨러 설계 | Sprint 2 (10 FRs) | Inline (this doc) |
| Code Analyzer | TypeScript 리팩토링 | Sprint 3-4 (12 FRs) | Inline (this doc) |
| Infra Architect | CI/CD, Docker | Sprint 3-4 (8 files) | Inline (this doc) |
| Frontend Architect | 공유 유틸리티 | Sprint 3 (FR-S3-05) | `docs/03-analysis/shared-utilities-design.md` |
| QA Strategist | 테스트 전략 | Sprint 3 (FR-S3-01~04) | `docs/03-analysis/test-strategy.md` |
| Product Manager | UX 개선 | Sprint 5 (6 FRs) | `docs/02-design/features/sprint-5-ux-improvements.design.md` |
| Gap Detector | 요구사항 추적 | All Sprints | `docs/03-analysis/adw-requirements-traceability-matrix.md` |

### 1.3 Requirements Traceability Summary

- **Total Requirements**: 48 (12 + 11 + 10 + 10 + 6) -- v2.2 계획서 기준
- **Analysis Issues Addressed**: 45 of 48 (93.8%)
- **Out of Scope Issues**: 3건 (SEC-11 서드파티 이미지, QA-05 구조적 로깅, QA-09 CHANGELOG)
- **Cross-cutting Files**: `oauth.ts` (7 requirements), `install.sh` (6 requirements)
- **Gap Analysis Coverage**: 보안 갭 10건, 공유 유틸리티 갭 35건, 요구사항 추적 갭 19건 전수 반영

---

## 2. Architecture

### 2.1 System Architecture (Before → After)

```
BEFORE (65.5%):                           AFTER (95%+):
┌─────────────────────┐                   ┌──────────────────────────┐
│ installer/           │                   │ installer/                │
│  install.sh          │                   │  install.sh              │
│  (macOS only,        │                   │  (cross-platform,        │
│   osascript JSON)    │                   │   node/python3 JSON)     │
│  modules/            │                   │  modules/                │
│   base/              │                   │   base/ (apt+dnf+pacman) │
│   google/            │                   │   google/ (timeout+path) │
│   atlassian/         │                   │   atlassian/ (.env)      │
│   notion/            │                   │   shared/                │
│   figma/             │                   │    colors.sh             │
│   pencil/            │                   │    docker-utils.sh       │
│                      │                   │    mcp-config.sh         │
│                      │                   │    browser-utils.sh      │
│                      │                   │    package-manager.sh    │
│  (no tests)          │                   │  tests/                  │
│                      │                   │   test_module_json.sh    │
│                      │                   │   test_install_syntax.sh │
└─────────────────────┘                   └──────────────────────────┘

┌─────────────────────┐                   ┌──────────────────────────┐
│ google-workspace-mcp │                   │ google-workspace-mcp     │
│  src/                │                   │  src/                    │
│   auth/oauth.ts      │                   │   auth/oauth.ts          │
│   (no state, no      │                   │   (CSRF state, cached    │
│    cache, root user) │                   │    services, non-root)   │
│   tools/             │                   │   utils/                 │
│    gmail.ts (inject)  │                   │    retry.ts              │
│    drive.ts (inject)  │                   │    sanitize.ts           │
│    calendar.ts       │                   │    time.ts               │
│    (Seoul hardcode)  │                   │    mime.ts               │
│   index.ts (any)     │                   │    messages.ts           │
│                      │                   │   tools/                 │
│                      │                   │    (sanitized, typed,    │
│  (no tests, no CI)   │                   │     retry-wrapped)       │
│  Dockerfile          │                   │  Dockerfile (node:22,    │
│  (node:20, root)     │                   │   non-root, .dockerignore│
└─────────────────────┘                   └──────────────────────────┘

                                          ┌──────────────────────────┐
                                          │ .github/workflows/       │
                                          │  ci.yml (auto PR/push)   │
                                          │  lint→build→test+docker  │
                                          └──────────────────────────┘
```

### 2.2 Key Architectural Decisions

| Decision | Selected | Rationale |
|----------|----------|-----------|
| JSON Parser | `node -e` primary, `python3` fallback, `osascript` fallback | Node.js는 base 설치 의존성이므로 항상 가용 |
| Test Framework | Vitest 3.x | TypeScript ESM 네이티브, 빠른 실행 |
| CI Pipeline | GitHub Actions multi-job | lint → build → test + docker + smoke (병렬) |
| Token Storage | `.env` + 환경변수 참조 | 크로스 플랫폼, Docker 친화적 |
| Rate Limiting | 커스텀 지수 백오프 (`withRetry()`) | 외부 의존성 최소화, 429/503 특화 |
| Timezone | `Intl.DateTimeFormat()` 기본값 + `TIMEZONE` 환경변수 오버라이드 | 자동 감지 + 명시적 설정 |
| Service Caching | `oauth.ts` 내부 모듈 레벨 싱글톤 with TTL | 71개 도구마다 서비스 재생성 → 1회 생성. 별도 `google-client.ts` 분리 보류 |
| Time Utilities | `src/utils/time.ts`로 통합 (`timezone.ts` 흡수) | `parseTime()`, `getTimezone()`, `getUtcOffsetString()` 등 시간 관련 함수 단일 모듈화 |
| Shell 편의함수 | `print_success()` / `print_error()` (shared-utilities-design 기준) | 기존 `print_ok()`/`print_fail()` 대신 의미가 명확한 naming 채택 |
| MCP 설정 함수 | `mcp_add_docker_server()` + `mcp_add_stdio_server()` 타입별 분리 | 단일 `mcp_add_server()` 대비 매개변수 명확성 향상 |

---

## 3. Sprint 1 — Critical Security Design

> **Reference**: `docs/02-design/security-spec.md` (전체 코드 포함)
> **OWASP Mapping**: A01 (Broken Access Control), A03 (Injection), A07 (Auth Failures)

### 3.1 FR-S1-01: OAuth State Parameter (CSRF Prevention)

**File**: `google-workspace-mcp/src/auth/oauth.ts` (lines 113-118)

**Design**:
```typescript
import crypto from "crypto";

// In getTokenFromBrowser():
const state = crypto.randomBytes(16).toString("hex");

const authUrl = oauth2Client.generateAuthUrl({
  access_type: "offline",
  scope: SCOPES,
  prompt: "consent",
  state: state,  // CSRF protection
});

// In callback handler:
const receivedState = new URL(callbackUrl).searchParams.get("state");
if (receivedState !== state) {
  throw new Error("OAuth state mismatch - possible CSRF attack");
}
```

**Invariant**: Every OAuth authorization request MUST include a `state` parameter, and every callback MUST validate it matches.

### 3.2 FR-S1-02: Drive API Query Escaping

**File**: `google-workspace-mcp/src/tools/drive.ts` (lines 18, 59)

**Design** — New shared sanitizer in `src/utils/sanitize.ts`:
```typescript
export function escapeDriveQuery(input: string): string {
  return input.replace(/\\/g, "\\\\").replace(/'/g, "\\'");
}
```

**Application**:
```typescript
// BEFORE: let q = `name contains '${query}' and trashed = false`;
// AFTER:
let q = `name contains '${escapeDriveQuery(query)}' and trashed = false`;
```

### 3.3 FR-S1-03: osascript Template Injection Prevention

**File**: `installer/install.sh` (lines 29-39)

**Design**: Replace backtick template literal with stdin pipe:
```bash
parse_json() {
    local json="$1"
    local key="$2"
    # Primary: node -e (always available after base install)
    if command -v node > /dev/null 2>&1; then
        echo "$json" | node -e "
            let d='';process.stdin.on('data',c=>d+=c);
            process.stdin.on('end',()=>{
                try{const o=JSON.parse(d);const v='$key'.split('.').reduce((a,k)=>a&&a[k],o);
                process.stdout.write(v===undefined?'':String(v))}
                catch{process.stdout.write('')}
            })"
        return
    fi
    # Fallback: python3
    if command -v python3 > /dev/null 2>&1; then
        echo "$json" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin);v=d
    for k in '$key'.split('.'):v=v.get(k,'') if isinstance(v,dict) else ''
    print(v if v else '',end='')
except:print('',end='')"
        return
    fi
    # Last fallback: osascript (macOS only, stdin-based)
    if command -v osascript > /dev/null 2>&1; then
        echo "$json" | osascript -l JavaScript -e "
            var input=$.NSFileHandle.fileHandleWithStandardInput;
            var data=input.readDataToEndOfFile;
            var str=$.NSString.alloc.initWithDataEncoding(data,$.NSUTF8StringEncoding).js;
            var obj=JSON.parse(str);var keys='$key'.split('.');
            var val=obj;for(var k of keys)val=val?val[k]:undefined;
            val===undefined?'':String(val);" 2>/dev/null || echo ""
        return
    fi
    echo ""
}
```

### 3.4 FR-S1-04: Atlassian API Token Secure Storage

**File**: `installer/modules/atlassian/install.sh` (lines 147-172)

**Design**: Store credentials in `.env` file instead of inline in `.mcp.json`:
```bash
# Create .env file with restricted permissions
ENV_FILE="$HOME/.atlassian-mcp/.env"
mkdir -p "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" << EOF
CONFLUENCE_URL=$confluenceUrl
CONFLUENCE_USERNAME=$email
CONFLUENCE_API_TOKEN=$apiToken
JIRA_URL=$jiraUrl
JIRA_USERNAME=$email
JIRA_API_TOKEN=$apiToken
EOF
chmod 600 "$ENV_FILE"

# MCP config references .env via --env-file
config.mcpServers['atlassian'] = {
    command: 'docker',
    args: ['run', '-i', '--rm', '--env-file', envFile, 'ghcr.io/sooperset/mcp-atlassian:latest']
};
```

### 3.5 FR-S1-05 ~ FR-S1-10: Summary

| FR | Change | Key Code |
|----|--------|----------|
| FR-S1-05 | Figma: Informational only (template placeholder, not actual secret) | No code change needed |
| FR-S1-06 | Docker non-root: `adduser --system --uid 1001 app` + `USER app` | See Section 8 (Dockerfile) |
| FR-S1-07 | Token file permissions: `fs.chmodSync(TOKEN_PATH, 0o600)` after save | `oauth.ts:108` |
| FR-S1-08 | Config dir permissions: `mkdirSync(dir, { recursive: true, mode: 0o700 })` | `oauth.ts:53` |
| FR-S1-09 | Atlassian variable escaping: Use `--env-file` instead of shell interpolation | See FR-S1-04 above |
| FR-S1-10 | Email header injection: `sanitizeEmailHeader()` strips `\r\n` | `gmail.ts` send handler |

**Full implementation details**: `docs/02-design/security-spec.md`

---

## 4. Sprint 2 — Platform & Stability Design

### 4.1 FR-S2-01: Cross-Platform JSON Parser

See Section 3.3 above. The same `parse_json()` function serves both FR-S1-03 (security) and FR-S2-01 (compatibility).

**Test verification**:
```bash
# Linux test (no osascript):
echo '{"name":"test","order":3}' | parse_json /dev/stdin "name"
# Expected: "test"
```

### 4.2 FR-S2-02: Remote Shared Script Download

**File**: `installer/install.sh` (module loading section)

**Design**: Before executing each module in remote mode, download shared scripts:
```bash
run_module() {
    local mod="$1"
    # In remote mode, download shared scripts to temp dir
    if [ "$USE_LOCAL" != true ]; then
        SHARED_TMP=$(mktemp -d)
        # 임시 파일 정리 보장 (정상/비정상 종료 모두 대응)
        trap 'rm -rf "$SHARED_TMP"' EXIT INT TERM
        for shared_script in colors.sh docker-utils.sh mcp-config.sh \
                             browser-utils.sh package-manager.sh oauth-helper.sh; do
            curl -sSL "$BASE_URL/modules/shared/$shared_script" \
                -o "$SHARED_TMP/$shared_script" || true
        done
        export SHARED_DIR="$SHARED_TMP"
    else
        export SHARED_DIR="$SCRIPT_DIR/modules/shared"
    fi
    # Execute module
    # ...
}
```

> **결정**: `trap 'rm -rf "$SHARED_TMP"' EXIT INT TERM` 패턴으로 비정상 종료 시에도 임시 파일 정리를 보장한다. (요구사항 추적 갭 분석 항목 3 반영)

Module scripts reference via `$SHARED_DIR`:
```bash
# 로컬 실행
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../shared/colors.sh"

# 원격 실행 (FR-S2-02 연계)
source "${SHARED_DIR:-$SCRIPT_DIR/../shared}/colors.sh"
```

### 4.3 FR-S2-03: MCP Config Path Unification

**Files affected**: `install.sh:406`, `google/install.sh:328`, `atlassian/install.sh:145`

**Design**: Migrate from `~/.mcp.json` to `~/.claude/mcp.json` with backward compatibility:
```bash
MCP_CONFIG_PATH="$HOME/.claude/mcp.json"
MCP_LEGACY_PATH="$HOME/.mcp.json"

# Migration: merge legacy into new path
if [ -f "$MCP_LEGACY_PATH" ] && [ ! -f "$MCP_CONFIG_PATH" ]; then
    mkdir -p "$(dirname "$MCP_CONFIG_PATH")"
    cp "$MCP_LEGACY_PATH" "$MCP_CONFIG_PATH"
elif [ -f "$MCP_LEGACY_PATH" ] && [ -f "$MCP_CONFIG_PATH" ]; then
    # Merge: new file takes precedence
    node -e "
const fs=require('fs');
const legacy=JSON.parse(fs.readFileSync('$MCP_LEGACY_PATH','utf8'));
const current=JSON.parse(fs.readFileSync('$MCP_CONFIG_PATH','utf8'));
const merged={...legacy,...current,mcpServers:{...legacy.mcpServers,...current.mcpServers}};
fs.writeFileSync('$MCP_CONFIG_PATH',JSON.stringify(merged,null,2));
"
fi
```

### 4.4 FR-S2-04: Linux Package Manager Expansion

**File**: `installer/modules/base/install.sh`

**Design**: Detect and use the appropriate package manager:
```bash
detect_pkg_manager() {
    if command -v apt-get > /dev/null 2>&1; then echo "apt"
    elif command -v dnf > /dev/null 2>&1; then echo "dnf"
    elif command -v pacman > /dev/null 2>&1; then echo "pacman"
    else echo "unknown"; fi
}

pkg_install() {
    local package="$1"
    case "$PKG_MANAGER" in
        apt) sudo apt-get install -y "$package" ;;
        dnf) sudo dnf install -y "$package" ;;
        pacman) sudo pacman -S --noconfirm "$package" ;;
        *) echo "Please install $package manually" ;;
    esac
}
```

### 4.5 FR-S2-05 ~ FR-S2-09: Summary

| FR | Change | Impact |
|----|--------|--------|
| FR-S2-05 | Figma `module.json`: `type: "remote-mcp"`, `node: false`, `python3: true` | Metadata accuracy |
| FR-S2-06 | Atlassian `module.json`: Add `modes` array for Docker/Rovo dual mode | Informational metadata |
| FR-S2-07 | Module execution sorting by `MODULE_ORDERS` before loop | Dependency order guarantee |
| FR-S2-08 | Docker wait timeout (300s polling loop) in `google/install.sh` | Prevents infinite hang |
| FR-S2-09 | `python3: true` in Notion/Figma `module.json` | Dependency documentation |

### 4.6 FR-S2-10: Windows 관리자 권한 조건부 요청

> **갭 분석 반영**: `gap-security-verification.md` D-03 -- SEC-06의 상세 수정 코드가 설계서에 미반영

**File**: `installer/install.ps1` (lines 130-153)
**OWASP Mapping**: A04 -- Insecure Design
**Severity**: High

**Design**: 모듈별 관리자 권한 필요성을 판단하는 `Test-AdminRequired` 함수 도입:

```powershell
function Test-AdminRequired {
    param([string]$ModuleName)
    # base 모듈: Node.js/npm 글로벌 설치 시 관리자 필요
    # google, atlassian: Docker 설치 시에만 필요
    # figma, notion, github, pencil: 관리자 불필요
    $adminModules = @("base")
    $conditionalModules = @("google", "atlassian") # Docker 미설치 시에만

    if ($ModuleName -in $adminModules) { return $true }
    if ($ModuleName -in $conditionalModules) {
        return -not (Get-Command docker -ErrorAction SilentlyContinue)
    }
    return $false
}

# 메인 실행 흐름에서:
$needsAdmin = $SelectedModules | Where-Object { Test-AdminRequired $_ }
if ($needsAdmin) {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Administrator privileges needed for: $($needsAdmin -join ', ')"
        # UAC 상승 요청
        Start-Process powershell -Verb RunAs -ArgumentList $PSCommandPath
        exit
    }
}
```

### 4.7 FR-S2-11: Docker Desktop 버전 호환성 체크

> **갭 분석 반영**: `gap-requirements-traceability.md` Section 2 #5 -- OS-06 대응 FR 신설

**Files**: `google/install.sh`, `atlassian/install.sh`, `installer/modules/shared/docker-utils.sh`

**Design**: `docker_check()` 함수에 Docker Desktop 버전 + OS 호환성 교차 검증 추가:

```bash
# docker-utils.sh에 추가
docker_check_compatibility() {
    local docker_version
    docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "")

    if [[ "$OSTYPE" == "darwin"* ]]; then
        local os_version
        os_version=$(sw_vers -productVersion 2>/dev/null || echo "")
        local major_version="${os_version%%.*}"

        # Docker Desktop 4.42+ requires macOS Sonoma (14.x) or later
        if [[ -n "$docker_version" ]] && [[ "$docker_version" > "4.42" ]]; then
            if [[ "$major_version" -lt 14 ]]; then
                echo -e "  ${YELLOW}Warning: Docker Desktop $docker_version may not support macOS $os_version${NC}"
                echo -e "  ${YELLOW}Consider using Docker Desktop 4.41 or earlier for macOS Ventura${NC}"
                return 1
            fi
        fi
    fi
    return 0
}
```

**Full before/after code**: Enterprise Expert agent output (see traceability matrix)

---

## 5. Sprint 3 — Quality & Testing Design

### 5.1 FR-S3-01: Google MCP Unit Tests (Vitest)

**Framework Configuration** — `google-workspace-mcp/vitest.config.ts`:
```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["src/**/__tests__/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "html", "lcov"],
      include: ["src/**/*.ts"],
      exclude: ["src/**/__tests__/**", "src/**/*.d.ts"],
      thresholds: {
        lines: 60,
        functions: 60,
        branches: 50,
        statements: 60,
      },
    },
    testTimeout: 10000,
  },
});
```

**Test Strategy** — Priority-ranked 78 test cases:

| Priority | Tests | Category | Gate |
|----------|------:|----------|------|
| P0 (Critical) | 10 | Security: header injection, query escaping, CSRF | Block deployment |
| P1 (Core) | 46 | API calls, MIME parsing, timezone, OAuth flow | Block release |
| P2 (Edge) | 21 | Empty results, large files, network errors | Document known issues |
| P3 (Polish) | 1 | Tool registration count | Informational |

**Mock Strategy**: Mock at `getGoogleServices()` boundary:
```typescript
vi.mock("../../auth/oauth.js", () => ({
  getGoogleServices: vi.fn(),
}));
```

**Full test strategy**: `docs/03-analysis/test-strategy.md`

### 5.2 FR-S3-02: Installer Smoke Tests

**Framework**: Bash test scripts in `installer/tests/`

| Test Suite | Tests | Purpose |
|------------|------:|---------|
| `test_module_json.sh` | 49 | JSON syntax, required fields, type validation |
| `test_install_syntax.sh` | 9 | Bash/PowerShell syntax check |
| `test_module_ordering.sh` | 3 | Installation sequence validation |
| **Total** | **73** | |

### 5.3 FR-S3-03: CI Auto-Trigger Pipeline

**File**: `.github/workflows/ci.yml`

```yaml
name: CI
on:
  push:
    branches: [master, develop]
  pull_request:
    branches: [master]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22 }
      - run: cd google-workspace-mcp && npm ci
      - run: cd google-workspace-mcp && npm run lint
      - run: cd google-workspace-mcp && npm run format:check

  build:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22 }
      - run: cd google-workspace-mcp && npm ci && npm run build

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22 }
      - run: cd google-workspace-mcp && npm ci && npm run test:coverage

  smoke-tests:
    needs: build
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - run: bash installer/tests/test_module_json.sh
      - run: bash installer/tests/test_install_syntax.sh

  security-audit:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22 }
      - run: cd google-workspace-mcp && npm ci && npm audit --audit-level=high

  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ShellCheck
        run: sudo apt-get install -y shellcheck
      - name: Run ShellCheck on installer scripts
        run: |
          find installer/ -name "*.sh" -exec shellcheck -S warning {} +

  docker-build:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd google-workspace-mcp && docker build -t test .
      - run: |
          docker run --rm test node -e "console.log('OK')"
          docker run --rm test id -u | grep -q 1001
```

> **v1.2 추가**: `security-audit` job(FR-S3-09 npm audit CI 통합), `shellcheck` job(횡단 관심사 #8 반영)

### 5.4 FR-S3-05: Shared Utilities (상세 설계)

> **갭 분석 반영**: 공유 유틸리티 갭 분석(gap-shared-utilities.md) D-1~D-20 항목 반영
> **원본 상세 설계**: `docs/03-analysis/shared-utilities-design.md`

#### 5.4.1 인스톨러 공유 유틸리티 상세

**디렉토리**: `installer/modules/shared/`

> **결정**: 함수명은 `shared-utilities-design.md` 기준으로 통일한다. `print_ok()`/`print_fail()` 대신 `print_success()`/`print_error()`, `open_browser()` 대신 `browser_open()`, `mcp_add_server()` 대신 `mcp_add_docker_server()`/`mcp_add_stdio_server()` 채택.

| File | Functions | Eliminates | Source Reference |
|------|-----------|------------|-----------------|
| `colors.sh` | `RED`, `GREEN`, `YELLOW`, `CYAN`, `GRAY`, `BLUE`, `MAGENTA`, `WHITE`, `NC`, `COLOR_SUCCESS`, `COLOR_ERROR`, `COLOR_WARNING`, `COLOR_INFO`, `COLOR_DEBUG`, `print_success()`, `print_error()`, `print_warning()`, `print_info()`, `print_debug()` | 7개 모듈 42줄 중복 색상 정의 | shared-utilities-design Section 1.3.1 |
| `docker-utils.sh` | `docker_is_installed()`, `docker_is_running()`, `docker_get_status()`, `docker_check()`, `docker_wait_for_start()`, `docker_install()`, `docker_pull_image()`, `docker_cleanup_container()`, `docker_show_install_guide()` | 4x duplicate Docker checks + 설치/정리 로직 | shared-utilities-design Section 1.3.2 |
| `mcp-config.sh` | `mcp_get_config_path()`, `mcp_check_node()`, `mcp_add_docker_server()`, `mcp_add_stdio_server()`, `mcp_remove_server()`, `mcp_server_exists()` | 4x duplicate Node.js `-e` JSON 조작 블록 | shared-utilities-design Section 1.3.3 |
| `browser-utils.sh` | `browser_open()`, `browser_open_with_prompt()`, `browser_open_or_show()`, `browser_wait_for_completion()` | 4개 모듈 크로스 플랫폼 브라우저 열기 중복 (WSL 감지 포함) | shared-utilities-design Section 1.3.4 |
| `package-manager.sh` | `pkg_detect_manager()`, `pkg_install()`, `pkg_install_cask()`, `pkg_is_installed()`, `pkg_ensure_installed()` | brew/apt/dnf/yum/pacman 패키지 관리자 추상화 (FR-S2-04 연계) | shared-utilities-design Section 1.3.5 |

**주요 함수 설계 — docker-utils.sh**:
```bash
# Docker Desktop 설치 (플랫폼별 분기)
docker_install() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - Homebrew with progress spinner
        brew install --cask docker > /dev/null 2>&1 &
        BREW_PID=$!
        # spinner 표시 ...
        wait $BREW_PID
    else
        # Linux - official install script
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
    fi
    DOCKER_NEEDS_RESTART=true
}

# Docker 이미지 Pull with progress
docker_pull_image() {
    local image_name="$1"
    echo -e "  ${YELLOW}Pulling Docker image: $image_name${NC}"
    docker pull "$image_name" 2>/dev/null
}

# 컨테이너 정리 (이미지 기준)
docker_cleanup_container() {
    local image_name="$1"
    local container_id
    container_id=$(docker ps -q --filter "ancestor=$image_name" 2>/dev/null)
    if [ -n "$container_id" ]; then
        docker stop "$container_id" > /dev/null 2>&1
        docker rm "$container_id" > /dev/null 2>&1
    fi
}
```

**주요 함수 설계 — package-manager.sh**:
```bash
# 패키지 관리자 탐지 (brew/apt/dnf/yum/pacman)
pkg_detect_manager() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        command -v brew > /dev/null 2>&1 && echo "brew" || echo "none"
    elif command -v apt > /dev/null 2>&1; then echo "apt"
    elif command -v dnf > /dev/null 2>&1; then echo "dnf"
    elif command -v yum > /dev/null 2>&1; then echo "yum"
    elif command -v pacman > /dev/null 2>&1; then echo "pacman"
    else echo "none"; fi
}

# 패키지 설치 (관리자별 자동 분기)
pkg_install() {
    local package_name="$1"
    local manager=$(pkg_detect_manager)
    case "$manager" in
        brew) brew install "$package_name" ;;
        apt) sudo apt update && sudo apt install -y "$package_name" ;;
        dnf) sudo dnf install -y "$package_name" ;;
        yum) sudo yum install -y "$package_name" ;;
        pacman) sudo pacman -S --noconfirm "$package_name" ;;
        none) echo -e "${RED}No package manager detected${NC}"; return 1 ;;
    esac
}

# 미설치 시 자동 설치
pkg_ensure_installed() {
    local package_name="$1"
    local description="${2:-$package_name}"
    if command -v "$package_name" > /dev/null 2>&1; then
        echo -e "  ${GREEN}$description is already installed${NC}"
    else
        echo -e "  ${YELLOW}Installing $description...${NC}"
        pkg_install "$package_name"
    fi
}
```

**주요 함수 설계 — browser-utils.sh**:
```bash
# 크로스 플랫폼 브라우저 열기
browser_open() {
    local url="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$url" 2>/dev/null
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        start "$url" 2>/dev/null
    elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open "$url" 2>/dev/null
    else
        echo -e "  ${YELLOW}Could not auto-open browser. Please open manually:${NC}"
        echo "  $url"
        return 1
    fi
}

# 프롬프트 후 열기
browser_open_with_prompt() {
    local description="$1" url="$2"
    read -p "Open $description in browser? (y/n): " response < /dev/tty
    [ "$response" = "y" ] || [ "$response" = "Y" ] && browser_open "$url"
}
```

**Source 패턴**:
```bash
# 로컬 실행
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../shared/colors.sh"
source "$SCRIPT_DIR/../shared/docker-utils.sh"
source "$SCRIPT_DIR/../shared/mcp-config.sh"
source "$SCRIPT_DIR/../shared/browser-utils.sh"

# 원격 실행 (FR-S2-02 연계)
source "${SHARED_DIR:-$SCRIPT_DIR/../shared}/colors.sh"
```

**수정 대상 모듈** (7개):
| Module | 주요 변경 |
|--------|----------|
| `base/install.sh` | colors.sh + package-manager.sh source |
| `google/install.sh` | colors.sh + docker-utils.sh + mcp-config.sh + browser-utils.sh source |
| `atlassian/install.sh` | colors.sh + docker-utils.sh + mcp-config.sh + browser-utils.sh source |
| `figma/install.sh` | colors.sh + browser-utils.sh source |
| `notion/install.sh` | colors.sh + browser-utils.sh source |
| `github/install.sh` | colors.sh source |
| `pencil/install.sh` | colors.sh source |

**인스톨러 수용 기준**:
1. 7개 인스톨러 모듈이 모두 `shared/colors.sh`를 source
2. 인라인 색상 정의(`RED=`, `GREEN=` 등) 0건
3. Docker 관련 모듈(google, atlassian)이 `docker_check()` 사용
4. MCP 설정 모듈(google, atlassian)이 `mcp_add_docker_server()` / `mcp_add_stdio_server()` 사용
5. 브라우저 열기 모듈(atlassian, google, figma, notion)이 `browser_open()` 사용

#### 5.4.2 Google MCP 공유 유틸리티 상세

> **결정 — time.ts vs timezone.ts 통합**: `src/utils/time.ts`로 통일한다. `parseTime()`, `getCurrentTime()`, `addDays()`, `formatDate()` + 기존 `timezone.ts`의 `getTimezone()`, `getUtcOffsetString()`을 모두 `time.ts`에 통합한다.

> **결정 — google-client.ts 아키텍처**: `oauth.ts` 내부 캐싱 방식을 채택한다 (설계서 현재 방식 유지). 단, 테스트 편의를 위해 `clearServiceCache()` 함수를 export로 추가한다.

> **결정 — sanitize.ts 함수 범위**: 최종 7개 함수로 확정한다 — `escapeDriveQuery()`, `validateDriveId()`, `sanitizeEmailHeader()`, `validateEmail()`, `validateMaxLength()`, `sanitizeFilename()`, `sanitizeRange()`.

| File | Exports | Used By | Sprint |
|------|---------|---------|--------|
| `time.ts` | `parseTime()`, `getCurrentTime()`, `addDays()`, `formatDate()`, `getTimezone()`, `getUtcOffsetString()` | calendar.ts, 기타 시간 관련 도구 | S3-05, S4-03 통합 |
| `retry.ts` | `withRetry()`, `RetryOptions` | All 6 tool files (~80 API calls) | S4-01 |
| `sanitize.ts` | `escapeDriveQuery()`, `validateDriveId()`, `sanitizeEmailHeader()`, `validateEmail()`, `validateMaxLength()`, `sanitizeFilename()`, `sanitizeRange()` | drive.ts, gmail.ts, sheets.ts, 기타 | S1-02, S1-10 |
| `mime.ts` | `extractTextBody()`, `extractAttachments()` | gmail.ts | S4-07 |
| `messages.ts` | 8개 카테고리 메시지 + `msg()` 헬퍼 | All tool files | S3-05, S5-05 동시 구현 |

**sanitize.ts 확장 함수 설계** (기존 5개 → 7개):
```typescript
// 기존 유지
export function escapeDriveQuery(input: string): string { ... }
export function validateDriveId(id: string): boolean { ... }
export function sanitizeEmailHeader(header: string): string { ... }
export function validateEmail(email: string): boolean { ... }
export function validateMaxLength(input: string, max: number): string { ... }

// 신규 추가 (갭 분석 D-10 반영)
export function sanitizeFilename(filename: string): string {
  return filename
    .replace(/[<>:"/\\|?*\x00-\x1F]/g, "_")
    .replace(/\.+/g, ".")
    .replace(/^\./, "")
    .trim()
    .substring(0, 255);
}

export function sanitizeRange(range: string): string | null {
  // Google Sheets A1 notation 검증
  const rangeRegex = /^([^!]+!)?[A-Z]+\d+:[A-Z]+\d+$|^([^!]+!)?[A-Z]+\d+$/i;
  return rangeRegex.test(range) ? range.trim() : null;
}
```

**messages.ts 상세 설계** (8개 카테고리):
```typescript
export const messages = {
  common: {
    success: "Success",
    failed: "Failed",
    created: "Created successfully",
    updated: "Updated successfully",
    deleted: "Deleted successfully",
    notFound: "Not found",
  },
  calendar: {
    eventCreated: (title: string) => `Event "${title}" created successfully.`,
    eventUpdated: "Event updated successfully.",
    eventDeleted: "Event deleted successfully.",
    // ... 7개 메시지
  },
  gmail: {
    emailSent: (to: string) => `Email sent to ${to}.`,
    draftSaved: "Draft saved successfully.",
    // ... 11개 메시지
  },
  drive: { /* 10개 메시지 */ },
  docs: { /* 7개 메시지 */ },
  sheets: { /* 9개 메시지 */ },
  slides: { /* 7개 메시지 */ },
  errors: {
    authFailed: "Authentication failed. Please check credentials.",
    rateLimitExceeded: "Rate limit exceeded. Please try again later.",
    apiError: (message: string) => `API Error: ${message}`,
    networkError: "Network error. Please check your connection.",
    invalidRange: "Invalid range format.",
    invalidEmail: "Invalid email address.",
    invalidDate: "Invalid date format.",
    permissionDenied: "Permission denied.",
  },
};

// 파라미터 메시지 헬퍼 함수
export function msg(
  template: string | ((...args: any[]) => string),
  ...args: any[]
): string {
  return typeof template === "function" ? template(...args) : template;
}
```

> **결정 — messages.ts 구현 시점**: Sprint 5 FR-S5-05(295개 한국어 문자열 영문화)와 동시 구현한다. Sprint 3에서는 `messages.ts` 파일 구조만 생성하고, Sprint 5에서 실제 한국어->영문 마이그레이션을 수행한다.
>
> **결정 — i18n 방향** (갭 분석 반영: 횡단 관심사 #7): 현재 단계에서는 **English-only**를 기본으로 한다. 단, `messages.ts`의 키 기반 구조를 선제 적용하여 향후 i18n 프레임워크(예: `i18next`) 도입이 필요할 때 최소 변경으로 전환할 수 있도록 한다. i18n 프레임워크 도입 자체는 현재 Out of Scope이다.

**time.ts 통합 설계** (timezone.ts 흡수):
```typescript
// src/utils/time.ts — timezone.ts의 기능을 통합

export function getTimezone(): string {
  return process.env.TIMEZONE || Intl.DateTimeFormat().resolvedOptions().timeZone;
}

export function getUtcOffsetString(): string {
  const tz = getTimezone();
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: tz, timeZoneName: "longOffset",
  });
  const parts = formatter.formatToParts(new Date());
  const offset = parts.find(p => p.type === "timeZoneName")?.value || "+00:00";
  const match = offset.match(/GMT([+-]\d{2}:\d{2})/);
  return match ? match[1] : "+00:00";
}

export function parseTime(timeStr: string, timezone?: string): string {
  if (timeStr.includes("T")) return timeStr;
  const [date, time] = timeStr.split(" ");
  const offset = getUtcOffsetString();
  return `${date}T${time}:00${offset}`;
}

export function getCurrentTime(): string {
  return new Date().toISOString();
}

export function addDays(date: string | Date, days: number): string {
  const baseDate = typeof date === "string" ? new Date(date) : date;
  return new Date(baseDate.getTime() + days * 86400000).toISOString();
}

export function formatDate(isoString: string, locale: string = "en-US"): string {
  return new Date(isoString).toLocaleString(locale, {
    year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit",
  });
}
```

**Service Cache 테스트 유틸리티** (oauth.ts에 추가):
```typescript
// oauth.ts 하단에 테스트용 export 추가
export function clearServiceCache(): void {
  serviceCache = null;
}
```

**Google MCP 수용 기준**:
1. `calendar.ts` 내 중복 `parseTime()` 함수 0건
2. 69개 핸들러가 캐싱된 `getGoogleServices()` 사용
3. 모든 Google API 호출에 `withRetry()` 적용
4. 사용자 입력이 API에 전달되기 전 sanitize 함수 통과
5. 하드코딩된 한국어 메시지 0건 (Sprint 5 완료 시)

**Full design**: `docs/03-analysis/shared-utilities-design.md`

### 5.5 FR-S3-06: ESLint + Prettier

**ESLint** — `google-workspace-mcp/eslint.config.js`:
```javascript
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import prettierConfig from "eslint-config-prettier";

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  prettierConfig,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
    },
  }
);
```

### 5.6 FR-S3-07: `any` Type Removal + strict 모드 보존

> **갭 분석 반영**: `gap-requirements-traceability.md` 암묵적 요구사항 #6 -- `any` 제거 시 strict:true 회귀 방지

**검증 방법**: CI 파이프라인에서 `tsc --strict --noEmit` 단계를 빌드 전에 실행하여 strict 호환성을 보장한다.

| Location | Before | After |
|----------|--------|-------|
| `index.ts:32` | `async (params: any)` | `async (params: Record<string, unknown>)` |
| `sheets.ts:18` | `const requestBody: any` | `const requestBody: sheets_v4.Schema$Spreadsheet` |
| `sheets.ts:341` | `const cellFormat: any` | `const cellFormat: sheets_v4.Schema$CellFormat` |
| `slides.ts:135` | `const requests: any[]` | `const requests: slides_v1.Schema$Request[]` |
| `slides.ts:156` | `const textRequests: any[]` | `const textRequests: slides_v1.Schema$Request[]` |
| `calendar.ts:288` | `const updatedEvent: any` | `const updatedEvent: CalendarEventUpdate` |
| `docs.ts:236` | `as any` | `as NamedStyleType` (union type) |

### 5.7 FR-S3-08: Error Message English Unification

```typescript
// BEFORE
console.error("오류:", error);
console.error("서버 시작 실패:", error);

// AFTER
console.error("Error:", error);
console.error("Server startup failed:", error);
```

---

## 6. Sprint 4 — Google MCP Hardening Design

### 6.1 FR-S4-01: Rate Limiting with Exponential Backoff

**New file**: `google-workspace-mcp/src/utils/retry.ts`

```typescript
export interface RetryOptions {
  maxAttempts?: number;    // Default: 3
  initialDelay?: number;   // Default: 1000ms
  backoffFactor?: number;  // Default: 2
  maxDelay?: number;       // Default: 10000ms
  retryableErrors?: number[]; // Default: [429, 500, 502, 503, 504]
}

// 네트워크 에러도 재시도 대상으로 포함 (갭 분석 D-9 반영)
function isRetryableError(error: unknown, retryableStatuses: number[]): boolean {
  // HTTP 상태 코드 기반 재시도
  const status = (error as any)?.response?.status;
  if (status && retryableStatuses.includes(status)) return true;

  // 네트워크 에러 기반 재시도 (ECONNRESET, ETIMEDOUT 등)
  const code = (error as any)?.code;
  const networkErrors = ["ECONNRESET", "ETIMEDOUT", "ECONNREFUSED", "EPIPE", "EAI_AGAIN"];
  if (code && networkErrors.includes(code)) return true;

  return false;
}

export async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const maxAttempts = options.maxAttempts ?? 3;
  const initialDelay = options.initialDelay ?? 1000;
  const backoffFactor = options.backoffFactor ?? 2;
  const retryableStatuses = options.retryableErrors ?? [429, 500, 502, 503, 504];
  let delay = initialDelay;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error: unknown) {
      if (!isRetryableError(error, retryableStatuses) || attempt === maxAttempts) throw error;

      const status = (error as any)?.response?.status || (error as any)?.code || "unknown";
      console.warn(`[Retry] Attempt ${attempt}/${maxAttempts} failed (${status}). Retrying in ${delay}ms...`);
      await new Promise(r => setTimeout(r, delay));
      delay = Math.min(delay * backoffFactor, options.maxDelay ?? 10000);
    }
  }
  throw new Error("Unreachable");
}
```

**Application**: Wrap every Google API call:
```typescript
const response = await withRetry(() =>
  gmail.users.messages.list({ userId: "me", q: query, maxResults })
);
```

### 6.2 FR-S4-02: Dynamic OAuth Scope

**File**: `google-workspace-mcp/src/auth/oauth.ts`

```typescript
const SCOPE_MAP: Record<string, string[]> = {
  gmail: ["https://www.googleapis.com/auth/gmail.modify"],
  calendar: ["https://www.googleapis.com/auth/calendar"],
  drive: ["https://www.googleapis.com/auth/drive"],
  docs: ["https://www.googleapis.com/auth/documents"],
  sheets: ["https://www.googleapis.com/auth/spreadsheets"],
  slides: ["https://www.googleapis.com/auth/presentations"],
};

function resolveScopes(): string[] {
  const envScopes = process.env.GOOGLE_SCOPES;
  if (!envScopes) return Object.values(SCOPE_MAP).flat();
  return envScopes.split(",")
    .map(s => s.trim().toLowerCase())
    .flatMap(s => SCOPE_MAP[s] || [s]);
}

const SCOPES = resolveScopes();
```

### 6.3 FR-S4-03: Dynamic Timezone

> **결정**: `timezone.ts`를 별도 파일로 생성하지 않고 `src/utils/time.ts`에 통합한다 (Section 5.4.2 참조). `getTimezone()`, `getUtcOffsetString()` 함수는 `parseTime()` 등과 함께 `time.ts`에 위치한다.

**File**: `google-workspace-mcp/src/utils/time.ts` (Section 5.4.2의 통합 설계 참조)

**Application in calendar.ts**:
```typescript
import { getTimezone, parseTime } from "../utils/time.js";

// BEFORE: timeZone: "Asia/Seoul"
// AFTER:
const timezone = getTimezone();
event.start = { dateTime: parseTime(startTime), timeZone: timezone };
```

### 6.4 FR-S4-04: Service Instance Caching

**File**: `google-workspace-mcp/src/auth/oauth.ts`

```typescript
interface GoogleServices {
  gmail: gmail_v1.Gmail;
  calendar: calendar_v3.Calendar;
  drive: drive_v3.Drive;
  docs: docs_v1.Docs;
  sheets: sheets_v4.Sheets;
  slides: slides_v1.Slides;
}

interface ServiceCache {
  services: GoogleServices;
  createdAt: number;
}

const CACHE_TTL_MS = 50 * 60 * 1000; // 50 minutes
let serviceCache: ServiceCache | null = null;

export async function getGoogleServices(): Promise<GoogleServices> {
  if (serviceCache && Date.now() - serviceCache.createdAt < CACHE_TTL_MS) {
    return serviceCache.services;
  }
  const auth = await getAuthenticatedClient();
  const services: GoogleServices = {
    gmail: google.gmail({ version: "v1", auth }),
    calendar: google.calendar({ version: "v3", auth }),
    drive: google.drive({ version: "v3", auth }),
    docs: google.docs({ version: "v1", auth }),
    sheets: google.sheets({ version: "v4", auth }),
    slides: google.slides({ version: "v1", auth }),
  };
  serviceCache = { services, createdAt: Date.now() };
  return services;
}

// 테스트 유틸리티: 서비스 캐시 초기화 (단위 테스트에서 사용)
export function clearServiceCache(): void {
  serviceCache = null;
}
```

### 6.5 에러 메시지 포맷 표준

> **갭 분석 반영**: `gap-requirements-traceability.md` 암묵적 요구사항 #2 -- Rate limiting + Token validation 에러 처리 패턴 통일

모든 사용자 대면 에러 메시지는 다음 포맷을 따른다:

```typescript
// 에러 메시지 표준 포맷
interface UserFacingError {
  code: string;        // 예: "AUTH_FAILED", "RATE_LIMITED", "INVALID_INPUT"
  message: string;     // 사용자 친화적 메시지 (messages.ts 참조)
  detail?: string;     // 기술적 상세 (개발자용, 민감 정보 제외)
  retry?: boolean;     // 재시도 가능 여부
}

// 적용 예시 (retry.ts 실패 후):
{
  code: "RATE_LIMITED",
  message: messages.errors.rateLimitExceeded,
  detail: "429 after 3 attempts (1s->2s->4s backoff)",
  retry: true
}

// 적용 예시 (인증 실패):
{
  code: "AUTH_FAILED",
  message: messages.errors.authFailed,
  detail: "refresh_token expired or revoked",
  retry: false
}
```

**규칙**:
1. `detail` 필드에 API 키, 토큰, 사용자 입력 등 민감 정보 포함 금지
2. `message` 필드는 반드시 `messages.ts`의 중앙화된 메시지 사용
3. MCP stdout은 JSON-RPC 전용이므로, 에러 로깅은 stderr로 출력

### 6.6 FR-S4-05 ~ FR-S4-10: Summary

| FR | Design | Key Code Change |
|----|--------|-----------------|
| FR-S4-05 | Token refresh validation: Check `refresh_token` exists, add 5-min expiry buffer | `oauth.ts: loadToken()` |
| FR-S4-06 | Auth mutex: Promise-based lock prevents concurrent auth requests | `let authInProgress: Promise \| null` |
| FR-S4-07 | Recursive MIME parsing: New `extractTextBody()` + `extractAttachments()` in `mime.ts` | `gmail.ts` import from `mime.ts` |
| FR-S4-08 | Attachment: Optional `maxSize` param, remove hardcoded `.slice(0, 1000)` | `gmail.ts` attachment handler |
| FR-S4-09 | Node.js 22: `node:22-slim` in Dockerfile, `@types/node: ^22.0.0` | Dockerfile + package.json |
| FR-S4-10 | `.dockerignore`: Exclude credentials, node_modules, .git, tests | New file |

### 6.7 oauth.ts 리팩토링 로드맵

> **결정**: 7개 FR(S1-01, S1-07, S1-08, S4-02, S4-04, S4-05, S4-06)이 동일 파일(`oauth.ts`)을 수정하므로, Sprint 1 완료 후 Sprint 4 착수 전에 모듈 분리를 수행한다. (요구사항 추적 갭 분석 횡단 관심사 #1 반영)

**현재 구조**: `oauth.ts` (단일 파일, ~240줄)
- `generateAuthUrl()` + callback handler
- `loadToken()` + `saveToken()`
- `getGoogleServices()` + service cache
- config directory management

**제안 분리 구조**:
```
src/auth/
  config.ts          -- CONFIG_DIR, ensureConfigDir(), SCOPES
                        (FR-S1-08, FR-S4-02 담당)
  token-manager.ts   -- loadToken(), saveToken(), validateRefreshToken()
                        (FR-S1-07, FR-S4-05 담당)
  auth-flow.ts       -- generateAuthUrl(), callback, state validation, mutex
                        (FR-S1-01, FR-S4-06 담당)
  service-cache.ts   -- getGoogleServices(), singleton cache with TTL,
                        clearServiceCache()
                        (FR-S4-04 담당)
  index.ts           -- re-export public API (하위 호환 보장)
```

**적용 시점**: Sprint 1 완료 후, Sprint 4 착수 전
**리스크 완화**: `index.ts`에서 모든 public API를 re-export하여 import 경로 변경 최소화

---

## 7. Sprint 5 — UX & Documentation Design

> **Full specification**: `docs/02-design/features/sprint-5-ux-improvements.design.md`

### 7.1 FR-S5-01: Post-Installation Verification

```bash
verify_module_installation() {
    local mod="$1"
    local type="${MODULE_TYPES[$idx]}"
    case "$type" in
        "mcp"|"docker-mcp")
            verify_mcp_server "$mod" 3  # 3 retry attempts
            ;;
        "remote-mcp")
            verify_remote_mcp "$mod"
            ;;
        "extension"|"cli")
            verify_cli_tool "$mod"
            ;;
    esac
}
```

### 7.2 FR-S5-02: Rollback Mechanism

- Backup `~/.claude/mcp.json` before installation
- On module failure: prompt user for rollback
- Rollback: restore config, remove Docker images
- On all success: cleanup backup files

### 7.3 FR-S5-03 ~ FR-S5-06: Summary

| FR | Change |
|----|--------|
| FR-S5-03 | `ARCHITECTURE.md`: Add Pencil module, shared/ directory, execution order section |
| FR-S5-04 | `package.json`: `0.1.0` → `1.0.0`, create `CHANGELOG.md` |
| FR-S5-05 | 295 Korean strings → English across 6 tool files |
| FR-S5-06 | `.gitignore`: Add `**/client_secret.json`, `**/token.json`, `.env*`, `*.pem`, `*.key` |

---

## 8. Docker & Infrastructure Design

### 8.1 Production Dockerfile

```dockerfile
FROM node:22-slim AS builder
WORKDIR /app
COPY package*.json tsconfig.json ./
RUN npm ci --ignore-scripts
COPY src ./src
RUN npm run build

FROM node:22-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force
COPY --from=builder /app/dist ./dist

# Non-root user (FR-S1-06)
RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 --ingroup app --home /app --no-create-home app
RUN mkdir -p /app/.google-workspace && chown -R app:app /app
VOLUME ["/app/.google-workspace"]
ENV GOOGLE_CONFIG_DIR=/app/.google-workspace NODE_ENV=production
USER app
CMD ["node", "dist/index.js"]
```

**Docker 빌드 캐시 최적화** (갭 분석 반영: 암묵적 요구사항 #7):

레이어 순서는 변경 빈도가 낮은 것부터 높은 순으로 배치한다:
1. `node:22-slim` 베이스 이미지 (거의 변경 안 함)
2. `package*.json` 복사 + `npm ci` (의존성 변경 시만 캐시 무효화)
3. `src/` 복사 + `tsc` 빌드 (코드 변경 시 캐시 무효화)
4. Non-root 사용자 설정 (Dockerfile 수정 시만)

`USER app` 지시문은 `COPY --from=builder` 이후에 배치하여 빌드 캐시 효율을 극대화한다.

### 8.2 Updated package.json

```json
{
  "name": "google-workspace-mcp",
  "version": "1.0.0",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest run",
    "test:coverage": "vitest run --coverage",
    "lint": "eslint src/",
    "format": "prettier --write \"src/**/*.ts\"",
    "format:check": "prettier --check \"src/**/*.ts\""
  },
  "devDependencies": {
    "@eslint/js": "^9.0.0",
    "@types/node": "^22.0.0",
    "@vitest/coverage-v8": "^3.0.0",
    "eslint": "^9.0.0",
    "eslint-config-prettier": "^10.0.0",
    "prettier": "^3.0.0",
    "typescript-eslint": "^8.0.0",
    "vitest": "^3.0.0"
  }
}
```

---

## 9. Security Design Summary

### 9.1 OWASP Mapping

| OWASP | ADW Issue | FR | Mitigation |
|-------|-----------|-----|------------|
| A01 Broken Access Control | Docker root user | FR-S1-06 | Non-root USER in Dockerfile |
| A03 Injection | Drive query injection | FR-S1-02 | `escapeDriveQuery()` |
| A03 Injection | Email header injection | FR-S1-10 | `sanitizeEmailHeader()` |
| A03 Injection | osascript template injection | FR-S1-03 | stdin pipe input |
| A03 Injection | Atlassian variable injection | FR-S1-09 | `--env-file` pattern |
| A04 Insecure Design | No rate limiting | FR-S4-01 | `withRetry()` exponential backoff |
| A05 Security Misconfiguration | Token file 644 permissions | FR-S1-07 | `chmod 0o600` |
| A07 Auth Failures | OAuth CSRF | FR-S1-01 | `state` parameter |
| A07 Auth Failures | Over-scoped OAuth | FR-S4-02 | Dynamic scope selection |
| A08 Data Integrity | Credentials in config | FR-S1-04 | `.env` file separation |
| A08 Data Integrity | curl\|bash no integrity check | FR-S1-11 | SHA-256 checksum + `download_and_verify()` |
| A09 Security Logging | No security event logging | FR-S3-10 | `logSecurityEvent()` to stderr |

### 9.2 Input Validation Layer

> **갭 분석 반영**: 보안 검증 갭 분석(D-02)에서 Drive/Gmail만 커버하던 입력 검증을 Calendar, Docs, Sheets, Slides로 확장

New `src/utils/sanitize.ts` provides centralized input sanitization (7개 함수):

| Function | Purpose | Used In |
|----------|---------|---------|
| `escapeDriveQuery()` | Escape `'` in Drive API queries | `drive.ts` |
| `validateDriveId()` | Validate file/folder ID format | `drive.ts` |
| `sanitizeEmailHeader()` | Strip `\r\n` from email headers | `gmail.ts` |
| `validateEmail()` | RFC 5322 email format check | `gmail.ts` |
| `validateMaxLength()` | Input length limit | All tools |
| `sanitizeFilename()` | 파일명 특수문자 제거/치환 | `drive.ts`, `docs.ts` |
| `sanitizeRange()` | Google Sheets A1 notation 검증 | `sheets.ts` |

**도구별 입력 검증 적용 범위** (확장):

| Tool File | 검증 대상 파라미터 | 적용 함수 |
|-----------|-------------------|-----------|
| `drive.ts` | query, fileId, folderId, name | `escapeDriveQuery()`, `validateDriveId()`, `sanitizeFilename()` |
| `gmail.ts` | to, subject, body headers | `sanitizeEmailHeader()`, `validateEmail()` |
| `calendar.ts` | startTime, endTime, title | `validateMaxLength()`, `time.ts` 파싱 검증 |
| `docs.ts` | documentId, content, title | `validateDriveId()`, `validateMaxLength()` |
| `sheets.ts` | range, spreadsheetId, values | `sanitizeRange()`, `validateDriveId()` |
| `slides.ts` | presentationId, text, slideIndex | `validateDriveId()`, `validateMaxLength()` |

### 9.3 환경변수 관리 (.env.example)

> **갭 분석 반영**: 요구사항 추적 갭 분석 횡단 관심사 #3 — 신규 환경변수 4개 이상 추가되나 `.env.example` 템플릿 미설계

**New file**: `google-workspace-mcp/.env.example`

```bash
# Google Workspace MCP Configuration
# Copy to .env and fill in values

# OAuth Scopes (comma-separated: gmail,calendar,drive,docs,sheets,slides)
# Default: all scopes enabled
# GOOGLE_SCOPES=gmail,calendar,drive

# Timezone (IANA format, e.g., America/New_York)
# Default: system timezone via Intl API
# TIMEZONE=Asia/Seoul

# Config directory (Docker volume mount point)
# Default: ~/.google-workspace-mcp
# GOOGLE_CONFIG_DIR=/app/.google-workspace
```

**New file**: `installer/.env.example`

```bash
# Atlassian Configuration (FR-S1-04)
# CONFLUENCE_URL=https://your-domain.atlassian.net/wiki
# CONFLUENCE_USERNAME=your@email.com
# CONFLUENCE_API_TOKEN=your-token
# JIRA_URL=https://your-domain.atlassian.net
# JIRA_USERNAME=your@email.com
# JIRA_API_TOKEN=your-token
```

### 9.4 module.json 스키마 정의

> **갭 분석 반영**: 요구사항 추적 갭 분석 횡단 관심사 #4 — 3개 FR이 module.json을 수정하지만 정식 스키마 정의 없음

**New file**: `installer/module-schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["name", "order", "type"],
  "properties": {
    "name": { "type": "string", "description": "모듈 표시명" },
    "order": { "type": "integer", "minimum": 1, "description": "설치 순서" },
    "type": {
      "type": "string",
      "enum": ["mcp", "docker-mcp", "remote-mcp", "extension", "cli"],
      "description": "모듈 유형"
    },
    "node": { "type": "boolean", "default": true, "description": "Node.js 의존성 여부" },
    "python3": { "type": "boolean", "default": false, "description": "Python3 의존성 여부" },
    "docker": { "type": "boolean", "default": false, "description": "Docker 의존성 여부" },
    "modes": {
      "type": "array",
      "items": { "type": "string" },
      "description": "지원 모드 목록 (예: ['docker', 'rovo'])"
    },
    "description": { "type": "string" }
  }
}
```

**CI 검증**: `installer/tests/test_module_json.sh`에서 이 스키마 기반 필수 필드 검증 수행

### 9.5 ShellCheck CI 통합

> **갭 분석 반영**: 요구사항 추적 갭 분석 횡단 관심사 #8 — Shell 스크립트 5개 FR에 걸쳐 변경되나 CI에 ShellCheck 미포함

CI 워크플로우(Section 5.3)에 추가할 job:

```yaml
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ShellCheck
        run: sudo apt-get install -y shellcheck
      - name: Run ShellCheck on installer scripts
        run: |
          find installer/ -name "*.sh" -exec shellcheck -S warning {} +
```

### 9.6 마이그레이션 사용자 가이드

> **갭 분석 반영**: 요구사항 추적 갭 분석 암묵적 요구사항 #5 — MCP 경로 변경(FR-S2-03) 사용자 문서 누락

FR-S5-03 (ARCHITECTURE.md) 범위에 다음 마이그레이션 가이드 섹션을 포함한다:

**MCP 설정 경로 마이그레이션 안내**:
1. **자동 마이그레이션**: 인스톨러 재실행 시 `~/.mcp.json` → `~/.claude/mcp.json` 자동 머지
2. **수동 마이그레이션**: `cp ~/.mcp.json ~/.claude/mcp.json` 후 기존 파일 백업
3. **롤백 방법**: `cp ~/.claude/mcp.json.backup ~/.mcp.json` 으로 원래 경로 복원
4. **검증**: `cat ~/.claude/mcp.json | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).mcpServers))"`

---

## 10. Test Plan

### 10.1 Test Coverage Targets

| Component | Metric | Target |
|-----------|--------|--------|
| Google MCP Unit Tests | Line coverage | 60%+ |
| Google MCP Unit Tests | P0 Security tests | 100% pass |
| Installer Smoke Tests | Module JSON validation | 100% pass |
| CI Pipeline | PR auto-trigger | Active |
| Docker Build | Non-root verification | Pass |

### 10.2 Test Case Summary

| Category | P0 | P1 | P2 | Total |
|----------|---:|---:|---:|------:|
| Gmail | 3 | 10 | 2 | 15 |
| Drive | 2 | 7 | 3 | 12 |
| Calendar | 0 | 7 | 3 | 10 |
| OAuth | 5 | 5 | 2 | 12 |
| Docs | 0 | 5 | 3 | 8 |
| Sheets | 0 | 7 | 3 | 10 |
| Slides | 0 | 3 | 2 | 5 |
| Index | 0 | 4 | 2 | 6 |
| **Total** | **10** | **46** | **21** | **78** |

**Full test strategy**: `docs/03-analysis/test-strategy.md`

### 10.3 정량적 기대 효과

> **갭 분석 반영**: 공유 유틸리티 갭 분석 D-18, 요구사항 추적 갭 분석 Low #13

| Metric | Before | After | 개선율 |
|--------|--------|-------|--------|
| 인스톨러 LOC | ~1,200줄 | ~850줄 | **-29%** |
| Google MCP LOC | ~1,800줄 | ~1,300줄 | **-28%** |
| 서비스 인스턴스 (실행 당) | 414개 (69핸들러 x 6서비스) | 6개 (프로세스 당) | **-99%** |
| 중복 `parseTime()` | 2개 복사본 | 1개 (`time.ts`) | **-50%** |
| 하드코딩 한국어 메시지 | ~150개 | 0개 (중앙 관리) | **-100%** |
| 인라인 색상 정의 | 42줄 (7모듈) | 0줄 (shared) | **-100%** |
| Match Rate 목표 | 65.5% | 95%+ | **+29.5pp** |

### 10.4 위험 분석

> **갭 분석 반영**: 공유 유틸리티 갭 분석 D-19, 요구사항 추적 갭 분석 Low #14

| Risk | Probability | Impact | Mitigation |
|------|:-----------:|:------:|------------|
| 공유 유틸리티 리팩토링 시 기존 인스톨러 모듈 동작 깨짐 | Medium | High | 모듈별 순차 리팩토링 + 각 모듈 리팩토링 후 smoke 테스트 실행 |
| 성능 회귀 (서비스 캐싱 도입) | Low | Medium | 리팩토링 전후 벤치마크 비교, TTL 50분 기반 자동 갱신 |
| Shell 호환성 이슈 (bash 버전 차이) | Low | Medium | macOS, Linux, WSL 환경에서 테스트 + ShellCheck CI |
| TypeScript 컴파일 에러 (any 제거) | Low | Low | 점진적 strict 전환, 빌드 실패 시 CI 차단 |
| oauth.ts 모듈 분리 시 import 경로 변경 | Medium | Medium | `index.ts` re-export로 하위 호환, 점진적 마이그레이션 |

---

## 11. Implementation Guide

### 11.1 Sprint Execution Order

```
Sprint 1 (Critical Security) — 즉시, 22-33시간
  Phase 1: FR-S1-03 (parse_json 보안) — blocks Sprint 2
  Phase 2: FR-S1-01, FR-S1-02, FR-S1-10 (injection prevention)
  Phase 3: FR-S1-04, FR-S1-07, FR-S1-08 (credential security)
  Phase 4: FR-S1-06, FR-S1-09 (Docker, Atlassian)

Sprint 2 (Platform & Stability) — 1주 내
  Phase 1: FR-S2-01 (cross-platform JSON) — depends on FR-S1-03
  Phase 2: FR-S2-05, FR-S2-06, FR-S2-09 (metadata fixes)
  Phase 3: FR-S2-07, FR-S2-04, FR-S2-08 (sorting, Linux, timeout)
  Phase 4: FR-S2-03, FR-S2-02, FR-S2-10 (MCP path, remote, Windows)

Sprint 3 (Quality & Testing) — 2주 내
  Phase 1: FR-S3-06 (ESLint/Prettier setup)
  Phase 2: FR-S3-01 (Vitest + P0 security tests)
  Phase 3: FR-S3-02, FR-S3-03, FR-S3-04 (smoke tests, CI)
  Phase 4: FR-S3-05, FR-S3-07, FR-S3-08 (shared utils, types, messages)

Sprint 4 (Google MCP Hardening) — 3주 내
  Phase 1: FR-S4-01 (retry), FR-S4-03 (timezone)
  Phase 2: FR-S4-04 (caching), FR-S4-06 (mutex)
  Phase 3: FR-S4-02 (scopes), FR-S4-05 (refresh validation)
  Phase 4: FR-S4-07, FR-S4-08 (MIME, attachment)
  Phase 5: FR-S4-09, FR-S4-10 (Node 22, dockerignore)

Sprint 5 (UX & Documentation) — 1개월 내
  Phase 1: FR-S5-06, FR-S5-04 (security + version, 30min)
  Phase 2: FR-S5-05 (i18n, 3hrs)
  Phase 3: FR-S5-01, FR-S5-02 (verification, rollback, 6hrs)
  Phase 4: FR-S5-03 (ARCHITECTURE.md, 1hr)
```

### 11.2 Critical Path Dependencies

```
FR-S1-03 (osascript security)
    └── FR-S2-01 (cross-platform JSON) — same function
         └── FR-S2-02 (remote shared download)
         └── FR-S2-07 (module ordering)

FR-S1-01 (OAuth state)
    └── FR-S4-05 (token refresh)
         └── FR-S4-06 (auth mutex)
              └── FR-S4-04 (service caching)

FR-S3-06 (ESLint)
    └── FR-S3-01 (unit tests)
         └── FR-S3-03 (CI pipeline)
              └── FR-S3-04 (CI expansion)
```

### 11.3 Files Changed Summary

| File | Sprint FRs | Change Type |
|------|-----------|-------------|
| `installer/install.sh` | S1-03, S2-01, S2-02, S2-03, S2-07, S5-01, S5-02 | Major rewrite |
| `google-workspace-mcp/src/auth/oauth.ts` | S1-01, S1-07, S1-08, S4-02, S4-04, S4-05, S4-06 | Major rewrite |
| `google-workspace-mcp/src/tools/drive.ts` | S1-02, S4-01 | Input sanitization + retry |
| `google-workspace-mcp/src/tools/gmail.ts` | S1-10, S4-01, S4-07, S4-08 | Security + MIME + retry |
| `google-workspace-mcp/src/tools/calendar.ts` | S3-07, S4-01, S4-03 | Types + retry + timezone |
| `google-workspace-mcp/src/index.ts` | S3-07, S3-08 | Type fix + i18n |
| `google-workspace-mcp/Dockerfile` | S1-06, S4-09 | Non-root + Node 22 |
| `installer/modules/atlassian/install.sh` | S1-04, S1-09, S2-03 | Credential security + path |
| `installer/modules/base/install.sh` | S2-04 | Package manager expansion |
| `installer/modules/google/install.sh` | S2-03, S2-08 | MCP path + timeout |

**New Files**:
| File | Sprint | Purpose |
|------|--------|---------|
| `src/utils/retry.ts` | S4-01 | Exponential backoff |
| `src/utils/sanitize.ts` | S1-02, S1-10 | Input sanitization (7개 함수) |
| `src/utils/time.ts` | S3-05, S4-03 | Time parsing + dynamic timezone (timezone.ts 통합) |
| `src/utils/mime.ts` | S4-07 | Recursive MIME parsing |
| `src/utils/messages.ts` | S3-05, S5-05 | Centralized i18n-ready messages (8개 카테고리) |
| `.github/workflows/ci.yml` | S3-03 | CI pipeline |
| `vitest.config.ts` | S3-01 | Test configuration |
| `eslint.config.js` | S3-06 | Linter configuration |
| `.dockerignore` | S4-10 | Build context exclusion |
| `google-workspace-mcp/.env.example` | S4-02, S4-03 | 환경변수 템플릿 |
| `installer/module-schema.json` | S3-02 | module.json JSON Schema 정의 |
| `installer/tests/*.sh` | S3-02 | Smoke tests |
| `installer/modules/shared/colors.sh` | S3-05 | ANSI 색상 상수 + 편의함수 |
| `installer/modules/shared/docker-utils.sh` | S3-05 | Docker 관리 (9개 함수) |
| `installer/modules/shared/mcp-config.sh` | S3-05 | MCP JSON 설정 (6개 함수) |
| `installer/modules/shared/browser-utils.sh` | S3-05 | 크로스 플랫폼 브라우저 (4개 함수) |
| `installer/modules/shared/package-manager.sh` | S3-05 | 패키지 관리자 추상화 (5개 함수: pkg_detect_manager, pkg_install, pkg_install_cask, pkg_is_installed, pkg_ensure_installed) |
| `installer/.env.example` | S1-04 | Atlassian 환경변수 템플릿 |

### 11.4 calendar.ts 마이그레이션 예시 (Before/After)

> **갭 분석 반영**: 공유 유틸리티 갭 분석 D-14 — 통합된 마이그레이션 예시 부재

**Before** (현재 calendar.ts, `calendar_create_event` 핸들러):
```typescript
calendar_create_event: {
  handler: async ({ title, startTime, endTime, ... }) => {
    const { calendar } = await getGoogleServices(); // 매 호출마다 6개 서비스 생성

    const parseTime = (timeStr: string) => {       // 중복 함수
      if (timeStr.includes("T")) return timeStr;
      const [date, time] = timeStr.split(" ");
      return `${date}T${time}:00+09:00`;            // 하드코딩 타임존
    };

    const event = {
      summary: title,
      start: { dateTime: parseTime(startTime), timeZone: "Asia/Seoul" }, // 하드코딩
      end: { dateTime: parseTime(endTime), timeZone: "Asia/Seoul" },
    };

    const response = await calendar.events.insert({   // retry 없음
      calendarId, requestBody: event,
    });

    return {
      success: true,
      message: `일정 "${title}"이 생성되었습니다.`, // 한국어 하드코딩
    };
  },
},
```

**After** (리팩토링 후):
```typescript
import { getGoogleServices } from "../auth/oauth.js";
import { parseTime, getTimezone } from "../utils/time.js";
import { messages, msg } from "../utils/messages.js";
import { withRetry } from "../utils/retry.js";
import { validateMaxLength } from "../utils/sanitize.js";

calendar_create_event: {
  handler: async ({ title, startTime, endTime, ... }) => {
    const { calendar } = await getGoogleServices();   // 캐싱된 싱글톤
    const timezone = getTimezone();                    // 동적 타임존

    const event = {
      summary: validateMaxLength(title, 500),          // 입력 검증
      start: { dateTime: parseTime(startTime), timeZone: timezone },
      end: { dateTime: parseTime(endTime), timeZone: timezone },
      attendees: attendees?.map((email) => ({ email })),
    };

    const response = await withRetry(() =>             // 자동 재시도
      calendar.events.insert({
        calendarId, requestBody: event,
        sendUpdates: sendNotifications ? "all" : "none",
      })
    );

    return {
      success: true,
      eventId: response.data.id,
      link: response.data.htmlLink,
      message: msg(messages.calendar.eventCreated, title), // 중앙화 메시지
    };
  },
},
```

**개선 요약**: 중복 함수 제거, 싱글톤 서비스, 자동 재시도, 동적 타임존, 입력 검증, 중앙화 메시지

---

## 12. Related Documents

| Document | Path | Content |
|----------|------|---------|
| Plan | `docs/01-plan/features/adw-improvement.plan.md` | 44 requirements, 5 sprints |
| Security Spec | `docs/02-design/security-spec.md` | Sprint 1 full code, OWASP mapping |
| Test Strategy | `docs/03-analysis/test-strategy.md` | 78 unit + 73 smoke tests |
| Shared Utils Design | `docs/03-analysis/shared-utilities-design.md` | Installer + MCP shared modules (원본 상세 설계) |
| Sprint 5 UX Design | `docs/02-design/features/sprint-5-ux-improvements.design.md` | Verification, rollback, i18n |
| Traceability Matrix | `docs/03-analysis/adw-requirements-traceability-matrix.md` | 44-requirement dependency graph |
| Gap: Shared Utilities | `docs/03-analysis/gap-shared-utilities.md` | 공유 유틸리티 갭 분석 (20개 갭 항목) |
| Gap: Security Verification | `docs/03-analysis/gap-security-verification.md` | 보안 검증 갭 분석 (12개 보안 이슈) |
| Gap: Requirements Traceability | `docs/03-analysis/gap-requirements-traceability.md` | 요구사항 추적 갭 분석 (19개 갭 항목) |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-12 | Initial design -- 44 requirements across 5 sprints | CTO Team (8 agents) |
| 1.1 | 2026-02-12 | 3개 갭 분석 보고서 반영 -- FR-S3-05 상세 확장 (인스톨러 5개+Google MCP 5개 유틸리티 함수명 통일, docker-utils.sh 9개 함수, package-manager.sh/browser-utils.sh 상세 설계), time.ts/timezone.ts 통합 결정, google-client.ts 아키텍처 결정 (oauth.ts 내부 캐싱 유지 + clearServiceCache()), sanitize.ts 7개 함수 확정, messages.ts 상세 설계 (8개 카테고리 + msg() 헬퍼), oauth.ts 리팩토링 로드맵 추가, FR-S2-02 임시 파일 정리 (trap 패턴), Input Validation Layer 확장 (Calendar/Docs/Sheets/Slides), .env.example 템플릿, module.json 스키마, ShellCheck CI, 마이그레이션 사용자 가이드, 정량적 기대 효과, 위험 분석, New Files 테이블 보완, calendar.ts Before/After 마이그레이션 예시 | Frontend Architect (갭 분석 반영) |
| 1.2 | 2026-02-13 | 7개 분석문서 전수 교차 검증 반영. **신규 섹션**: FR-S2-10 Windows 관리자 권한 조건부 요청 상세 설계(Test-AdminRequired 함수, 갭 D-03 반영), FR-S2-11 Docker Desktop 버전 호환성 체크 설계(docker_check_compatibility 함수), 에러 메시지 포맷 표준(UserFacingError 인터페이스), retry.ts ECONNRESET/ETIMEDOUT 네트워크 에러 대응(isRetryableError 함수, 갭 D-9 반영). **보완**: CI 파이프라인에 security-audit(npm audit) + shellcheck job 추가, TypeScript strict 모드 보존 검증 방법 추가, Docker 빌드 캐시 최적화 가이드, i18n 방향 결정(English-only + 키 기반 선제 적용), New Files 테이블 installer/.env.example 추가, References 7개 분석문서 전체 목록, 요구사항 추적 93.8% 갱신 | CTO Lead (7개 분석문서 전수 교차 검증) |
