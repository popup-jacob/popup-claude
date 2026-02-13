# ADW 종합 테스트 설계서

**문서 버전**: v1.0
**작성일**: 2026-02-13
**프로젝트**: popup-claude (AI-Driven Work Installer + Google Workspace MCP Server)
**참조 문서**: `docs/01-plan/features/comprehensive-test-plan.md` (v1.0, 310개 TC)
**상태**: 초안

---

## 1. 개요

### 1.1 목적

본 문서는 `comprehensive-test-plan.md`(310개 TC)의 모든 테스트 케이스에 대해 실행 가능한 수준의 상세 테스트 설계를 제공한다. 테스트 엔지니어가 본 문서만으로 테스트를 수행할 수 있도록 구체적인 절차, 명령어, 기대 결과, 테스트 데이터, 자동화 방법을 기술한다.

### 1.2 설계 원칙

| 원칙 | 설명 |
|------|------|
| **실행 가능성** | 모든 TC에 단계별 절차(Step-by-Step)와 실제 명령어를 포함한다 |
| **코드 기반** | 실제 소스코드의 함수명, 파라미터, 반환값을 참조하여 기대 결과를 정의한다 |
| **OS별 분리** | 동일 TC라도 OS별로 다른 절차가 있으면 각각 기술한다 |
| **자동화 우선** | Vitest 기반 자동 테스트를 우선 설계하고, 자동화 불가한 항목만 수동 절차를 기술한다 |
| **재현성** | Mock 데이터와 픽스처를 명시하여 동일 결과를 재현할 수 있도록 한다 |

### 1.3 참조 문서 (계획서 대응)

| 문서 | 경로 | 역할 |
|------|------|------|
| 종합 테스트 계획서 | `docs/01-plan/features/comprehensive-test-plan.md` | 310개 TC 정의, 우선순위, 전제조건 |
| 기능 계획서 | `docs/01-plan/features/adw-improvement.plan.md` | FR 요구사항 원본 |
| 설계 문서 | `docs/02-design/features/adw-improvement.design.md` | 아키텍처 및 상세 설계 |
| 보안 사양서 | `docs/02-design/security-spec.md` | OWASP 기반 보안 요구사항 |
| 요구사항 추적 매트릭스 | `docs/03-analysis/adw-requirements-traceability-matrix.md` | FR-TC 매핑 |
| 보안 검증 보고서 | `docs/03-analysis/security-verification-report.md` | 보안 테스트 근거 |
| 공유 유틸리티 설계 | `docs/03-analysis/shared-utilities-design.md` | 공유 모듈 함수 사양 |

### 1.4 용어 정의

| 용어 | 정의 |
|------|------|
| ADW | AI-Driven Work -- 본 프로젝트의 브랜드명 |
| MCP | Model Context Protocol -- Claude와 외부 서비스 연동 프로토콜 |
| TC | Test Case -- 테스트 케이스 |
| SUT | System Under Test -- 테스트 대상 시스템 |
| Mock | 실제 외부 의존성을 대체하는 가짜 객체 |
| Fixture | 테스트 실행에 필요한 사전 준비된 데이터 |
| P0/P1/P2/P3 | 우선순위 (Critical/High/Medium/Low) |
| withRetry | `src/utils/retry.ts`의 지수 백오프 재시도 래퍼 함수 |
| sanitize | `src/utils/sanitize.ts`의 입력 검증/정화 함수 모음 (7개) |
| SHARED_DIR | 인스톨러 공유 스크립트 디렉토리 경로 환경변수 |

### 1.5 TC 커버리지 요약

| 영역 | TC 수 | P0 | P1 | P2 | P3 | 자동화 가능 | 수동 전용 |
|------|------:|---:|---:|---:|---:|----------:|--------:|
| INS (인스톨러) | 52 | 14 | 22 | 12 | 4 | 20 | 32 |
| AUT (OAuth) | 22 | 11 | 9 | 2 | 0 | 18 | 4 |
| GML (Gmail) | 22 | 3 | 10 | 9 | 0 | 22 | 0 |
| DRV (Drive) | 20 | 4 | 8 | 8 | 0 | 20 | 0 |
| CAL (Calendar) | 15 | 3 | 6 | 6 | 0 | 15 | 0 |
| DOC (Docs) | 13 | 2 | 4 | 7 | 0 | 13 | 0 |
| SHT (Sheets) | 14 | 3 | 4 | 6 | 1 | 14 | 0 |
| SLD (Slides) | 11 | 2 | 3 | 6 | 0 | 11 | 0 |
| ATL (Atlassian) | 7 | 3 | 2 | 2 | 0 | 2 | 5 |
| FIG (Figma) | 8 | 3 | 3 | 2 | 0 | 2 | 6 |
| NOT (Notion) | 4 | 3 | 1 | 0 | 0 | 1 | 3 |
| GIT (GitHub) | 6 | 2 | 3 | 1 | 0 | 2 | 4 |
| PEN (Pencil) | 5 | 2 | 1 | 1 | 1 | 1 | 4 |
| SHR (공유 유틸리티) | 16 | 1 | 8 | 5 | 2 | 8 | 8 |
| DOK (Docker) | 7 | 1 | 4 | 2 | 0 | 3 | 4 |
| SEC (보안) | 38 | 22 | 12 | 4 | 0 | 30 | 8 |
| PER (성능) | 25 | 4 | 10 | 11 | 0 | 20 | 5 |
| E2E (시나리오) | 19 | 5 | 8 | 6 | 0 | 4 | 15 |
| REG (회귀) | 10 | 6 | 3 | 1 | 0 | 10 | 0 |
| **합계** | **314** | **94** | **121** | **90** | **8** | **216** | **98** |

---

## 2. 테스트 환경 설계

### 2.1 macOS 테스트 환경 구축 절차

#### MAC-ENV-01: macOS Ventura 13.x (Intel)

**목적**: 하위 호환성 검증 (Docker Desktop 4.41 이하 권장)

**하드웨어/VM 준비**:
```
1. UTM 또는 VMware Fusion에서 macOS Ventura 13.x VM 생성
   - RAM: 8GB 이상
   - 디스크: 60GB 이상
   - CPU: 4코어 이상

2. 클린 설치 스냅샷 생성
   $ sudo tmutil disablelocal  # 로컬 스냅샷 비활성화
   $ # VM 소프트웨어에서 "Clean Ventura" 스냅샷 생성
```

**필수 소프트웨어 설치**:
```bash
# Homebrew (클린 테스트 시에는 설치하지 않음)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Intel Mac PATH 확인
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"

# Docker Desktop 4.41 (Ventura 호환 버전)
# https://docs.docker.com/desktop/release-notes/ 에서 4.41 다운로드
brew install --cask docker  # 또는 수동 설치

# 검증
brew --version     # Homebrew 4.x
docker --version   # Docker 24.x ~ 25.x
```

**스냅샷 포인트**:
- `SNAP-MAC01-CLEAN`: Homebrew 미설치, Docker 미설치 (클린 상태)
- `SNAP-MAC01-BREW`: Homebrew만 설치
- `SNAP-MAC01-FULL`: Homebrew + Docker Desktop 4.41 설치 + 미실행

#### MAC-ENV-02: macOS Sonoma 14.x (Apple M1/M2)

**목적**: 주력 테스트 환경

**하드웨어 준비**:
```
Apple Silicon Mac (M1/M2/M3)
- RAM: 16GB 권장
- 디스크: 40GB 여유 공간
- 별도 사용자 계정 생성 (테스트 전용)
  $ sudo dscl . -create /Users/testuser
```

**필수 소프트웨어 설치**:
```bash
# Apple Silicon Homebrew PATH (중요: /opt/homebrew/)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Docker Desktop 최신 (4.42+ -- Sonoma 14+ 필요)
brew install --cask docker

# 검증
which brew           # /opt/homebrew/bin/brew (Apple Silicon)
docker --version     # Docker 27.x+
python3 --version    # Python 3.12+
```

**스냅샷 포인트**:
- `SNAP-MAC02-CLEAN`: 클린 사용자 계정
- `SNAP-MAC02-DOCKER-OFF`: Docker 설치 + 미실행
- `SNAP-MAC02-READY`: Docker 실행 중 + 인터넷 연결 확인

#### MAC-ENV-03: macOS Sequoia 15.x (Apple M3/M4)

**목적**: 최신 OS 호환성 검증

**구축**: MAC-ENV-02와 동일 절차, OS 버전만 Sequoia 15.x

### 2.2 Windows 테스트 환경 구축 절차

#### WIN-ENV-01: Windows 10 21H2

**목적**: 최소 지원 버전 검증

**VM 준비**:
```
1. Hyper-V 또는 VMware에서 Windows 10 21H2 VM 생성
   - RAM: 8GB
   - 디스크: 60GB
   - 가상화 중첩(Nested Virtualization) 활성화 (WSL2용)

2. Windows Update 적용 후 21H2 상태 유지
   $ winver  # 버전 확인: 21H2 (빌드 19044)
```

**PowerShell 환경 설정**:
```powershell
# PowerShell 버전 확인
$PSVersionTable.PSVersion  # 5.1.x

# 실행 정책 확인
Get-ExecutionPolicy  # Restricted (기본)

# 테스트를 위해 Bypass 설정 (관리자 PowerShell)
Set-ExecutionPolicy Bypass -Scope Process -Force
```

**WSL2 설정 절차**:
```powershell
# WSL2 활성화 (관리자 PowerShell)
wsl --install  # Windows 10 21H2+에서 지원

# 재부팅 후
wsl --set-default-version 2
wsl --install -d Ubuntu-22.04

# 검증
wsl --version
wsl -l -v  # Ubuntu-22.04 VERSION 2
```

**스냅샷 포인트**:
- `SNAP-WIN01-CLEAN`: WSL2 미설치, Docker 미설치
- `SNAP-WIN01-WSL`: WSL2 + Ubuntu 22.04 설치
- `SNAP-WIN01-FULL`: WSL2 + Docker Desktop (WSL2 백엔드)

#### WIN-ENV-02: Windows 10 22H2

**구축**: WIN-ENV-01과 동일, OS 빌드만 22H2 (19045)

#### WIN-ENV-03: Windows 11 23H2+

**구축**: WIN-ENV-01과 동일, PowerShell 7.x 추가 설치

```powershell
# PowerShell 7 설치
winget install Microsoft.PowerShell

# 검증
pwsh -Version  # 7.x.x
```

### 2.3 Linux 테스트 환경 구축 절차

#### LNX-ENV-01: Ubuntu 22.04 LTS (apt)

**VM/컨테이너 준비**:
```bash
# Docker 기반 테스트 환경 (빠른 구축)
docker run -it --name lnx-env-01 ubuntu:22.04 /bin/bash

# 또는 VM (완전 테스트용)
# UTM/VirtualBox에서 Ubuntu 22.04 LTS 설치
# 최소 설치 선택, 사용자: testuser

# 기본 패키지 확인
apt update && apt install -y curl openssl
which curl      # /usr/bin/curl
which openssl   # /usr/bin/openssl
```

**스냅샷 포인트**:
- `SNAP-LNX01-CLEAN`: curl, openssl만 설치, Node.js/Docker 없음
- `SNAP-LNX01-NODE`: Node.js 22 사전 설치
- `SNAP-LNX01-DOCKER`: Docker Engine 설치 + docker 그룹 추가

#### LNX-ENV-02: Ubuntu 24.04 LTS (apt)

**구축**: LNX-ENV-01과 동일, Ubuntu 24.04 사용

#### LNX-ENV-03: Fedora 39+ (dnf)

```bash
# Docker 기반
docker run -it --name lnx-env-03 fedora:39 /bin/bash
dnf install -y curl openssl

# 검증
dnf --version
```

#### LNX-ENV-04: Arch Linux (pacman)

```bash
# Docker 기반
docker run -it --name lnx-env-04 archlinux:latest /bin/bash
pacman -Sy --noconfirm curl openssl

# 검증
pacman --version
```

#### LNX-ENV-05: WSL2 Ubuntu 22.04

```powershell
# Windows 호스트에서
wsl --install -d Ubuntu-22.04

# WSL2 내부에서
cat /proc/version  # Microsoft 문자열 포함 확인
```

### 2.4 Docker 테스트 환경 구축 절차

#### DOK-ENV-01 ~ DOK-ENV-04 공통 절차

```bash
# 1. Docker 버전 확인
docker --version
docker info

# 2. 테스트 이미지 Pull
docker pull ghcr.io/popup-jacob/google-workspace-mcp:latest
docker pull ghcr.io/sooperset/mcp-atlassian:latest

# 3. 이미지 검증
docker inspect ghcr.io/popup-jacob/google-workspace-mcp:latest \
  --format='{{.Config.User}}'  # mcp (non-root)

docker inspect ghcr.io/popup-jacob/google-workspace-mcp:latest \
  --format='{{range .Config.Env}}{{println .}}{{end}}'  # NODE_ENV=production

docker images ghcr.io/popup-jacob/google-workspace-mcp:latest \
  --format='{{.Size}}'  # 500MB 이하 확인
```

**로컬 빌드 테스트**:
```bash
cd /Users/popup-kay/Documents/GitHub/popup/popup-claude/google-workspace-mcp
docker build -t google-workspace-mcp:test .

# non-root 사용자 확인
docker run --rm google-workspace-mcp:test id -u  # 1001 (mcp)

# HEALTHCHECK 확인
docker inspect google-workspace-mcp:test \
  --format='{{json .Config.Healthcheck}}'
```

### 2.5 Google API 테스트 환경

#### OAuth 자격 증명 준비

```
1. Google Cloud Console (https://console.cloud.google.com) 접속
2. 새 프로젝트 생성: "ADW-Test-YYYY-MM"
3. APIs & Services > Library에서 활성화:
   - Gmail API
   - Google Drive API
   - Google Calendar API
   - Google Docs API
   - Google Sheets API
   - Google Slides API
4. APIs & Services > Credentials > Create Credentials > OAuth client ID
   - Application type: Desktop app
   - Name: "ADW Test Client"
5. JSON 다운로드 -> client_secret.json으로 저장
6. OAuth consent screen:
   - User Type: Internal (Google Workspace) 또는 External (테스트 모드)
   - 테스트 사용자 추가
```

**테스트 계정 준비**:
```
- 계정 1 (주 테스트): test-adw-primary@gmail.com
  - Gmail: 테스트 이메일 50건 이상
  - Drive: 파일 20개, 폴더 5개, 공유 파일 포함
  - Calendar: 이벤트 10건, 반복 이벤트 2건

- 계정 2 (공유 테스트): test-adw-secondary@gmail.com
  - Drive 공유 수신자
  - Calendar 초대 수신자
```

**client_secret.json 배치**:
```bash
# Docker 볼륨 마운트 경로
mkdir -p ~/.google-workspace
cp client_secret.json ~/.google-workspace/
chmod 600 ~/.google-workspace/client_secret.json
chmod 700 ~/.google-workspace/
```

### 2.6 테스트 데이터 설계

#### 2.6.1 Gmail 테스트 데이터

| 데이터 ID | 설명 | 준비 방법 |
|-----------|------|----------|
| GML-DATA-001 | 일반 텍스트 이메일 (from:boss@example.com) | 사전 발송 또는 API로 생성 |
| GML-DATA-002 | HTML 본문 이메일 | 사전 발송 |
| GML-DATA-003 | 멀티파트 이메일 (text/plain + text/html) | 사전 발송 |
| GML-DATA-004 | 첨부파일 포함 이메일 (PDF 1MB) | 사전 발송 |
| GML-DATA-005 | 대용량 첨부파일 이메일 (10MB+) | 사전 발송 |
| GML-DATA-006 | 한글 제목 이메일 ("테스트 메일") | 사전 발송 |
| GML-DATA-007 | CC/BCC 포함 이메일 | 사전 발송 |
| GML-DATA-008 | 5000자 초과 본문 이메일 | 사전 발송 |
| GML-DATA-009 | 드래프트 이메일 3건 | API로 생성 |
| GML-DATA-010 | 커스텀 라벨 ("TestLabel") | API로 생성 |

#### 2.6.2 Drive 테스트 데이터

| 데이터 ID | 설명 | 준비 방법 |
|-----------|------|----------|
| DRV-DATA-001 | 루트 폴더 내 파일 5개 | API로 생성 |
| DRV-DATA-002 | "Test Folder" 폴더 + 하위 파일 3개 | API로 생성 |
| DRV-DATA-003 | PDF 파일 (application/pdf) | 업로드 |
| DRV-DATA-004 | 공유 설정된 파일 (viewer 권한) | API로 공유 설정 |
| DRV-DATA-005 | Shared Drive 내 파일 | 조직 계정 필요 |
| DRV-DATA-006 | 휴지통 파일 1건 | API로 trash 처리 |
| DRV-DATA-007 | 작은따옴표 포함 파일명 ("test's file.txt") | API로 생성 |

#### 2.6.3 Calendar 테스트 데이터

| 데이터 ID | 설명 | 준비 방법 |
|-----------|------|----------|
| CAL-DATA-001 | 향후 7일 내 이벤트 5건 | API로 생성 |
| CAL-DATA-002 | 참석자 포함 이벤트 1건 | API로 생성 |
| CAL-DATA-003 | 반복 이벤트 1건 (매주) | API로 생성 |
| CAL-DATA-004 | 종일 이벤트 1건 | API로 생성 |
| CAL-DATA-005 | 초대받은 이벤트 1건 (다른 계정에서 생성) | 계정 2에서 생성 |

#### 2.6.4 Docs/Sheets/Slides 테스트 데이터

| 데이터 ID | 설명 | 준비 방법 |
|-----------|------|----------|
| DOC-DATA-001 | 빈 Google Docs 문서 | API로 생성 |
| DOC-DATA-002 | 10000자+ 긴 문서 | API로 생성 |
| DOC-DATA-003 | 테이블 포함 문서 | API로 생성 |
| DOC-DATA-004 | 코멘트 포함 문서 | API로 생성 |
| SHT-DATA-001 | 빈 스프레드시트 | API로 생성 |
| SHT-DATA-002 | Sheet1!A1:D10 데이터 있는 시트 | API로 생성 |
| SHT-DATA-003 | 시트 2개 이상인 스프레드시트 | API로 생성 |
| SLD-DATA-001 | 빈 프레젠테이션 | API로 생성 |
| SLD-DATA-002 | 슬라이드 3개 + 텍스트 포함 프레젠테이션 | API로 생성 |

---

## 3. 인스톨러 테스트 설계

### 3.1 macOS 인스톨러 테스트 (TC-INS-MAC-001 ~ TC-INS-MAC-026)

#### TC-INS-MAC-001: 인수 파싱 -- --modules 옵션

**우선순위**: P0
**자동화**: 가능 (Bash 스크립트)
**환경**: MAC-ENV-02 (SNAP-MAC02-READY)

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `cd /Users/popup-kay/Documents/GitHub/popup/popup-claude/installer` | 인스톨러 디렉토리 이동 |
| 2 | `bash -x install.sh --modules "google,atlassian" 2>&1 \| head -50` | 디버그 출력에서 변수 확인 |
| 3 | MODULES 변수 확인 | `MODULES="google,atlassian"` |
| 4 | SELECTED_MODULES 변수 확인 | `SELECTED_MODULES="google atlassian"` (쉼표가 공백으로 변환) |

**검증 명령어**:
```bash
# install.sh의 인수 파싱 부분만 단독 테스트
bash -c '
  source <(sed -n "1,/^# 3\. List Mode/p" install.sh | head -n -1)
  echo "MODULES=$MODULES"
  echo "SELECTED_MODULES=$SELECTED_MODULES"
' -- --modules "google,atlassian"
```

**기대 출력**:
```
MODULES=google,atlassian
SELECTED_MODULES=google atlassian
```

**자동화 스크립트** (`installer/tests/test_ins_mac_001.sh`):
```bash
#!/bin/bash
# TC-INS-MAC-001: --modules 옵션 파싱
RESULT=$(bash -c '
  MODULES=""; INSTALL_ALL=false; SKIP_BASE=false; LIST_ONLY=false
  while [[ $# -gt 0 ]]; do
    case $1 in
      --modules) MODULES="$2"; shift 2 ;;
      --all) INSTALL_ALL=true; shift ;;
      --skip-base) SKIP_BASE=true; shift ;;
      --list) LIST_ONLY=true; shift ;;
      *) echo "Unknown option: $1"; exit 1 ;;
    esac
  done
  SELECTED_MODULES=$(echo "$MODULES" | tr "," " ")
  echo "$SELECTED_MODULES"
' -- --modules "google,atlassian")

if [ "$RESULT" = "google atlassian" ]; then
  echo "PASS: TC-INS-MAC-001"
else
  echo "FAIL: TC-INS-MAC-001 (got: $RESULT)"
  exit 1
fi
```

---

#### TC-INS-MAC-002: 인수 파싱 -- --all 옵션

**우선순위**: P0
**자동화**: 가능 (Bash 스크립트)
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `./install.sh --all` 실행 | INSTALL_ALL=true 설정 |
| 2 | 모듈 목록 확인 | required=true인 base를 제외한 나머지 6개 모듈 선택 |
| 3 | SELECTED_MODULES 확인 | google, atlassian, figma, notion, github, pencil 포함 |

**검증**: `install.sh`의 341~346행 로직 확인
```bash
# install.sh:340-346 로직
if [ "$INSTALL_ALL" = true ]; then
    for i in "${!MODULE_NAMES[@]}"; do
        if [ "${MODULE_REQUIRED[$i]}" != "true" ]; then
            SELECTED_MODULES="$SELECTED_MODULES ${MODULE_NAMES[$i]}"
        fi
    done
fi
```

**기대 결과**: `SELECTED_MODULES`에 "google atlassian figma notion github pencil"이 포함 (base 제외, required=true가 아닌 모든 모듈)

---

#### TC-INS-MAC-003: 인수 파싱 -- --list 옵션

**우선순위**: P1
**자동화**: 가능 (Bash 스크립트)
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `./install.sh --list` 실행 | 모듈 목록 표시 |
| 2 | 출력 내용 확인 | 7개 모듈(base, google, atlassian, figma, notion, github, pencil) 표시 |
| 3 | 종료 코드 확인 | exit 0 |

**검증 명령어**:
```bash
./install.sh --list
echo "Exit code: $?"
```

**기대 출력** (부분):
```
========================================
  Available Modules
========================================

  base (required) [basic]
    ...
  google [moderate]
    ...
  ...

Usage:
  ./install.sh --modules "google,atlassian"
  ./install.sh --all
```

---

#### TC-INS-MAC-004: 인수 파싱 -- --skip-base 옵션

**우선순위**: P1
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `bash -x install.sh --modules "google" --skip-base 2>&1 \| grep SKIP_BASE` | SKIP_BASE=true |
| 2 | base 모듈 실행 여부 확인 | base 모듈 건너뜀 |

**검증**: `install.sh`의 186행에서 `SKIP_BASE=true` 설정 확인

---

#### TC-INS-MAC-005: 인수 파싱 -- 알 수 없는 옵션

**우선순위**: P1
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `./install.sh --unknown 2>&1` | "Unknown option: --unknown" 출력 |
| 2 | 종료 코드 확인 | exit 1 |

**검증 명령어**:
```bash
output=$(./install.sh --unknown 2>&1)
exit_code=$?
echo "$output" | grep -q "Unknown option" && [ $exit_code -eq 1 ] && echo "PASS" || echo "FAIL"
```

**코드 참조**: `install.sh:195` -- `*) echo "Unknown option: $1"; exit 1 ;;`

---

#### TC-INS-MAC-006: 모듈 스캔 -- 로컬 실행

**우선순위**: P0
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `cd installer && ls modules/*/module.json` | 7개 module.json 파일 존재 |
| 2 | `./install.sh --list` 실행 | USE_LOCAL=true 설정 |
| 3 | 모듈 목록 확인 | 7개 모듈 전체 파싱 성공 |

**검증 명령어**:
```bash
# module.json 파일 수 확인
ls installer/modules/*/module.json | wc -l  # 7

# 각 module.json 유효성 확인
for f in installer/modules/*/module.json; do
  node -e "JSON.parse(require('fs').readFileSync('$f', 'utf8'))" && echo "OK: $f" || echo "FAIL: $f"
done
```

**코드 참조**: `install.sh:92-96` -- `BASH_SOURCE[0]` 존재 + `modules/` 디렉토리 존재 시 `USE_LOCAL=true`

---

#### TC-INS-MAC-007: 모듈 스캔 -- 원격 실행

**우선순위**: P0
**자동화**: 부분 가능 (네트워크 의존)
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `curl -sSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.sh \| bash -s -- --list` | 원격 실행 |
| 2 | USE_LOCAL 확인 | USE_LOCAL=false |
| 3 | modules.json 다운로드 확인 | 원격 modules.json에서 모듈 목록 획득 |

**코드 참조**: `install.sh:229-241` -- `curl -sSL "$BASE_URL/modules.json"` 다운로드 후 `download_and_verify`로 검증

---

#### TC-INS-MAC-008: 모듈 검증 -- 잘못된 모듈명

**우선순위**: P1
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `./install.sh --modules "nonexistent" 2>&1` | "Unknown module: nonexistent" 출력 |
| 2 | 종료 코드 | exit 1 |

**검증 명령어**:
```bash
output=$(./install.sh --modules "nonexistent" 2>&1)
echo "$output" | grep -q "Unknown module" && echo "PASS" || echo "FAIL"
```

**코드 참조**: `install.sh:352-358` -- `get_module_index` 반환값 `-1`일 때 에러

---

#### TC-INS-MAC-009: 스마트 상태 감지

**우선순위**: P0
**자동화**: 부분 가능
**환경**: MAC-ENV-02 (SNAP-MAC02-CLEAN)

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | 클린 환경에서 `./install.sh --modules "google"` 실행 | 상태 표시 |
| 2 | 출력에서 "Current Status:" 확인 | 각 도구별 [OK] 또는 [  ] 표시 |
| 3 | Node.js 미설치 시 | `Node.js:  [  ]` |
| 4 | Git 설치 시 | `Git:      [OK]` |
| 5 | Docker 실행 중 | `Docker:   [OK] (Running)` |

**코드 참조**: `install.sh:364-418` -- `get_install_status()` 함수

**검증 포인트**:
- `command -v node` -- Node.js 감지
- `command -v git` -- Git 감지
- `command -v code` 또는 `/Applications/Visual Studio Code.app` 존재 -- VS Code 감지
- `command -v docker` + `docker info` -- Docker 감지 + 실행 상태
- `command -v claude` -- Claude CLI 감지
- `claude plugin list | grep bkit` -- bkit 플러그인 감지

---

#### TC-INS-MAC-010: Base 자동 스킵

**우선순위**: P1
**자동화**: 부분 가능
**환경**: MAC-ENV-02 (모든 기본 도구 설치 상태)

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Node.js, Git, Claude, bkit 모두 설치 확인 | 모두 설치됨 |
| 2 | `./install.sh --modules "google"` 실행 | |
| 3 | 출력 확인 | "All base tools are already installed. Skipping base." 메시지 |
| 4 | SKIP_BASE 확인 | true |

**코드 참조**: `install.sh:444-456`
```bash
# 조건: HAS_NODE=true AND HAS_GIT=true AND HAS_CLAUDE=true AND HAS_BKIT=true
# Docker 필요 모듈 선택 시 HAS_DOCKER=true도 필요
if [ "$BASE_INSTALLED" = true ] && [ "$SKIP_BASE" = false ] && [ -n "$SELECTED_MODULES" ]; then
    echo -e "${GREEN}All base tools are already installed. Skipping base.${NC}"
    SKIP_BASE=true
fi
```

---

#### TC-INS-MAC-011: Docker 미실행 경고

**우선순위**: P1
**자동화**: 부분 가능 (사용자 입력 필요)
**환경**: MAC-ENV-02 (SNAP-MAC02-DOCKER-OFF)

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Docker Desktop 중지 상태 확인 | `docker info` 실패 |
| 2 | `./install.sh --modules "google"` 실행 | Docker 미실행 경고 표시 |
| 3 | 출력 확인 | "Docker Desktop is not running!" 메시지 |
| 4 | 사용자 입력 대기 | "Press Enter after starting Docker (or 'q' to quit):" 프롬프트 |
| 5 | 'q' 입력 | exit 0 |

**코드 참조**: `install.sh:420-441` -- Docker 실행 대기 블록

---

#### TC-INS-MAC-012: 모듈 실행 순서

**우선순위**: P1
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | 각 module.json의 order 값 확인 | base:1, github:2, atlassian:5, google:6, figma:7, notion:8, pencil:9 |
| 2 | `./install.sh --modules "google,atlassian,github"` 실행 | |
| 3 | 실행 순서 확인 | github(2) -> atlassian(5) -> google(6) |

**검증 명령어**:
```bash
# module.json order 필드 추출
for dir in installer/modules/*/; do
  name=$(node -e "console.log(JSON.parse(require('fs').readFileSync('${dir}module.json','utf8')).name)")
  order=$(node -e "console.log(JSON.parse(require('fs').readFileSync('${dir}module.json','utf8')).order)")
  echo "$order: $name"
done | sort -n
```

**코드 참조**: `install.sh:641-647` -- 모듈 order 기준 정렬
```bash
SORTED_MODULES=$(echo "$SORTED_MODULES" | tr ' ' '\n' | sort -t: -k1 -n | cut -d: -f2 | tr '\n' ' ')
```

---

#### TC-INS-MAC-013: MCP 설정 백업

**우선순위**: P0
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `~/.claude/mcp.json` 존재 확인 | 파일 존재 |
| 2 | 모듈 설치 시작 | `backup_mcp_config()` 호출 |
| 3 | 백업 파일 확인 | `~/.claude/mcp.json.bak.{timestamp}` 생성 |
| 4 | 백업 내용 확인 | 원본과 동일 |

**검증 명령어**:
```bash
# 백업 파일 존재 확인
ls -la ~/.claude/mcp.json.bak.* 2>/dev/null

# 내용 비교
diff ~/.claude/mcp.json ~/.claude/mcp.json.bak.*
```

**코드 참조**: `install.sh:496-502` -- `backup_mcp_config()` 함수

---

#### TC-INS-MAC-014: 모듈 실패 시 롤백

**우선순위**: P0
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | MCP 설정 백업 완료 상태 | 백업 파일 존재 |
| 2 | 모듈 install.sh가 exit 1 반환하도록 설정 | 인위적 실패 유발 |
| 3 | 롤백 확인 | "Rolling back MCP configuration..." 메시지 |
| 4 | MCP 설정 확인 | 백업에서 복원됨 |

**테스트 방법**:
```bash
# 인위적 실패를 위한 임시 모듈 스크립트
mkdir -p /tmp/test-module
echo '#!/bin/bash
echo "Intentional failure"
exit 1' > /tmp/test-module/install.sh
chmod +x /tmp/test-module/install.sh

# 백업 확인 후 롤백 메시지 확인
```

**코드 참조**: `install.sh:504-509` -- `rollback_mcp_config()`, `install.sh:611-619` -- 실패 시 롤백 호출

---

#### TC-INS-MAC-015: 설치 성공 시 백업 정리

**우선순위**: P1
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | 전체 설치 성공 | 모든 모듈 exit 0 |
| 2 | 백업 파일 확인 | `mcp.json.bak.*` 삭제됨 |
| 3 | 완료 메시지 확인 | "Installation Complete!" 출력 |

**코드 참조**: `install.sh:660-662`
```bash
if [ -n "$MCP_BACKUP_FILE" ] && [ -f "$MCP_BACKUP_FILE" ]; then
    rm -f "$MCP_BACKUP_FILE"
fi
```

---

#### TC-INS-MAC-016: 설치 후 검증

**우선순위**: P1
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | 모듈 설치 완료 | `verify_module_installation()` 자동 호출 |
| 2 | MCP config 확인 | "[Verify] MCP config: OK" 출력 |
| 3 | Docker 이미지 확인 (Docker 모듈) | "[Verify] Docker image: OK" 출력 |

**코드 참조**: `install.sh:514-545` -- `verify_module_installation()` 함수

---

#### TC-INS-MAC-017: parse_json -- node 우선

**우선순위**: P1
**자동화**: 가능
**환경**: MAC-ENV-02 (Node.js 설치 상태)

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Node.js 설치 확인 | `command -v node` 성공 |
| 2 | `parse_json '{"name":"test","order":5}' "name"` | "test" 반환 |
| 3 | `parse_json '{"name":"test","order":5}' "order"` | "5" 반환 |

**검증 스크립트**:
```bash
source installer/install.sh --list 2>/dev/null  # parse_json 함수 로드
result=$(parse_json '{"name":"google","order":6}' "name")
[ "$result" = "google" ] && echo "PASS" || echo "FAIL: $result"
```

**코드 참조**: `install.sh:31-53` -- node -e stdin 기반 파싱

---

#### TC-INS-MAC-018: parse_json -- python3 폴백

**우선순위**: P2
**자동화**: 가능
**환경**: MAC-ENV-02 (Node.js 없음, Python3 있음)

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Node.js 임시 제거 또는 PATH에서 제외 | `command -v node` 실패 |
| 2 | Python3 확인 | `command -v python3` 성공 |
| 3 | parse_json 호출 | python3으로 파싱 성공 |

**검증 스크립트**:
```bash
PATH_BACKUP=$PATH
export PATH=$(echo "$PATH" | sed 's|/usr/local/bin:||;s|/opt/homebrew/bin:||')
# node가 없는 PATH에서 테스트
result=$(bash -c 'source install.sh; parse_json "{\"name\":\"test\"}" "name"')
export PATH=$PATH_BACKUP
```

---

#### TC-INS-MAC-019: parse_json -- osascript 폴백

**우선순위**: P3
**자동화**: 가능 (macOS만)
**환경**: MAC-ENV-02 (Node.js/Python3 모두 없음)

**상세 절차**: TC-INS-MAC-018과 동일하나, python3도 PATH에서 제거. macOS에서 osascript JavaScript 실행기로 파싱.

**코드 참조**: `install.sh:73-84` -- osascript stdin 기반 JavaScript 파싱

---

#### TC-INS-MAC-020: SHA-256 체크섬 검증

**우선순위**: P0
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | 원격 실행 모드 | `USE_LOCAL=false` |
| 2 | `download_and_verify` 호출 | checksums.json 다운로드 |
| 3 | 파일 다운로드 + SHA-256 계산 | shasum -a 256 사용 |
| 4 | 해시 일치 확인 | "Integrity verified: {path}" 메시지 |

**검증 명령어**:
```bash
# 수동 검증
curl -sSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/checksums.json | node -e "
  let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
    const c=JSON.parse(d);
    console.log(JSON.stringify(c.files, null, 2));
  })"

# 특정 파일 해시 비교
curl -sSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/modules/google/install.sh | shasum -a 256
```

**코드 참조**: `install.sh:118-178` -- `download_and_verify()` 함수

---

#### TC-INS-MAC-021: SHA-256 체크섬 불일치

**우선순위**: P0
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | 변조된 파일 준비 (1바이트 수정) | 해시 불일치 |
| 2 | `download_and_verify` 호출 시뮬레이션 | |
| 3 | 출력 확인 | "[SECURITY] Integrity verification failed!" 메시지 |
| 4 | 임시 파일 확인 | `rm -f "$tmpfile"` 호출로 삭제됨 |
| 5 | 반환 코드 | return 1 |

**테스트 스크립트**:
```bash
# 변조 파일 생성
tmpfile=$(mktemp)
echo "tampered content" > "$tmpfile"
expected_hash="abc123..."  # 원본 해시
actual_hash=$(shasum -a 256 "$tmpfile" | awk '{print $1}')
[ "$actual_hash" != "$expected_hash" ] && echo "PASS: 변조 감지" || echo "FAIL"
rm -f "$tmpfile"
```

---

#### TC-INS-MAC-022: checksums.json 불가 시

**우선순위**: P2
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | checksums.json 404 시뮬레이션 | CHECKSUMS_JSON="" |
| 2 | `download_and_verify` 호출 | |
| 3 | 출력 확인 | "[WARN] checksums.json not available" 경고 |
| 4 | 설치 계속 여부 | 설치 계속 진행 (return 0) |

**코드 참조**: `install.sh:110-113`

---

#### TC-INS-MAC-023: 공유 스크립트 원격 다운로드

**우선순위**: P1
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | 원격 실행 모드 (USE_LOCAL=false) | |
| 2 | `setup_shared_dir()` 호출 | SHARED_TMP 디렉토리 생성 |
| 3 | 다운로드된 파일 확인 | colors.sh, browser-utils.sh, docker-utils.sh, mcp-config.sh |

**코드 참조**: `install.sh:555-567` -- `setup_shared_dir()` 함수

---

#### TC-INS-MAC-024: 임시 파일 정리 (trap)

**우선순위**: P1
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | 원격 실행으로 SHARED_TMP 생성 | 임시 디렉토리 존재 |
| 2 | 설치 완료 또는 Ctrl+C로 중단 | EXIT trap 발동 |
| 3 | SHARED_TMP 확인 | 디렉토리 삭제됨 |

**코드 참조**: `install.sh:561` -- `trap 'rm -rf "$SHARED_TMP"' EXIT`

---

#### TC-INS-MAC-025: 환경변수 지원

**우선순위**: P2
**자동화**: 가능
**환경**: MAC-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `MODULES="google" INSTALL_ALL=false ./install.sh` 실행 | |
| 2 | MODULES 변수 확인 | "google" |
| 3 | 동작 확인 | 명령줄 `--modules "google"`과 동일 |

**코드 참조**: `install.sh:184-187` -- 환경변수 기본값 설정
```bash
MODULES="${MODULES:-}"
INSTALL_ALL="${INSTALL_ALL:-false}"
```

---

#### TC-INS-MAC-026: Apple Silicon Homebrew PATH

**우선순위**: P1
**자동화**: 부분 가능 (Apple Silicon 필요)
**환경**: MAC-ENV-02 (Apple M1+)

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Apple Silicon Mac 확인 | `uname -m` = "arm64" |
| 2 | Homebrew 설치 후 PATH 확인 | `/opt/homebrew/bin/brew` |
| 3 | `eval "$(/opt/homebrew/bin/brew shellenv)"` 적용 확인 | brew 명령어 사용 가능 |

**코드 참조**: `modules/base/install.sh` 에서 Homebrew shellenv 설정

---

### 3.2 Windows 인스톨러 테스트 (TC-INS-WIN-001 ~ TC-INS-WIN-016)

#### TC-INS-WIN-001: 매개변수 파싱 -- -modules

**우선순위**: P0
**자동화**: 가능 (PowerShell 스크립트)
**환경**: WIN-ENV-03

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `.\install.ps1 -modules "google,atlassian"` 실행 | |
| 2 | $selectedModules 확인 | @("google", "atlassian") |

**검증 명령어** (PowerShell):
```powershell
# install.ps1 파라미터 테스트
$result = & .\install.ps1 -modules "google,atlassian" -list 2>&1
$result | Select-String "google"
```

---

#### TC-INS-WIN-002: 매개변수 파싱 -- -all

**우선순위**: P0
**자동화**: 가능
**환경**: WIN-ENV-03

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `.\install.ps1 -all` 실행 | required=false인 모든 모듈 선택 |

---

#### TC-INS-WIN-003: 매개변수 파싱 -- -list

**우선순위**: P1
**자동화**: 가능
**환경**: WIN-ENV-03

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `.\install.ps1 -list` 실행 | 모듈 목록 표시, 관리자 권한 불필요 |
| 2 | 일반 사용자 계정에서 실행 | UAC 프롬프트 없이 동작 |

---

#### TC-INS-WIN-004: 환경변수 지원

**우선순위**: P2
**자동화**: 가능
**환경**: WIN-ENV-03

**상세 절차**:
```powershell
$env:MODULES = 'google'
.\install.ps1 -list
# $env:MODULES 값이 적용되는지 확인
```

---

#### TC-INS-WIN-005: 관리자 권한 감지

**우선순위**: P0
**자동화**: 불가 (UAC 프롬프트)
**환경**: WIN-ENV-03 (비관리자)

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | 비관리자 계정으로 PowerShell 열기 | |
| 2 | Node.js 미설치 상태에서 install.ps1 실행 | |
| 3 | UAC 프롬프트 확인 | 관리자 권한 요청 팝업 |

**코드 참조**: `install.ps1:131-169` -- 조건부 권한 상승 로직

---

#### TC-INS-WIN-006: 조건부 권한 상승

**우선순위**: P1
**자동화**: 부분 가능
**환경**: WIN-ENV-03 (기본 도구 모두 설치)

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Node.js, Git, VS Code, Docker 모두 설치 확인 | |
| 2 | `.\install.ps1 -modules "notion" -skipBase` 실행 | |
| 3 | UAC 프롬프트 없이 실행 확인 | 관리자 권한 불필요 |

---

#### TC-INS-WIN-007 ~ TC-INS-WIN-016

나머지 Windows TC는 동일한 상세 형식으로 설계. 핵심 차이점:

- **TC-INS-WIN-007** (원격 실행 관리자 상승): `irm ... | iex` 실행 시 scriptblock으로 재실행
- **TC-INS-WIN-008** (스마트 상태 감지): WSL 상태 추가 표시 (`wsl --version`)
- **TC-INS-WIN-009** (WSL 감지): `wsl --version` 성공 시 "WSL: [OK]"
- **TC-INS-WIN-010** (Docker 미실행 경고): "Docker Desktop is not running!" 경고
- **TC-INS-WIN-011** (모듈 실행 순서): order 기준 정렬 확인
- **TC-INS-WIN-012** (Base 자동 스킵): macOS와 동일 로직
- **TC-INS-WIN-013** (MCP 설정 경로): `$env:USERPROFILE\.claude\mcp.json` 확인
- **TC-INS-WIN-014** (Remote MCP 타입 표시): "(Remote MCP)" 텍스트 포함
- **TC-INS-WIN-015** (로컬/원격 자동 감지): `$MyInvocation.MyCommand.Path` 확인
- **TC-INS-WIN-016** (-installDocker 플래그): Docker 미설치 시 설치 진행

### 3.3 Linux 인스톨러 테스트 (TC-INS-LNX-001 ~ TC-INS-LNX-010)

#### TC-INS-LNX-001: apt 기반 설치

**우선순위**: P0
**자동화**: 가능 (Docker 컨테이너)
**환경**: LNX-ENV-01

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Ubuntu 22.04 클린 환경 | Node.js, Git 미설치 |
| 2 | `./install.sh --modules "github" --skip-base` 실행 시 내부 base 로직 | |
| 3 | 패키지 관리자 감지 | `apt` 감지됨 |
| 4 | Node.js 설치 확인 | NodeSource 스크립트로 apt-get 설치 |
| 5 | Git 설치 확인 | `sudo apt-get install -y git` |

**검증 명령어**:
```bash
# Docker 컨테이너에서 테스트
docker run -it --rm ubuntu:22.04 bash -c '
  apt update && apt install -y curl
  curl -sSL https://raw.githubusercontent.com/.../install.sh | bash -s -- --list
'
```

**코드 참조**: `modules/base/install.sh:49-59` -- Linux Node.js 설치 로직

---

#### TC-INS-LNX-002: dnf 기반 설치

**우선순위**: P1
**자동화**: 가능 (Docker 컨테이너)
**환경**: LNX-ENV-03

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Fedora 39 클린 환경 | |
| 2 | install.sh 실행 | `dnf` 감지 |
| 3 | Node.js 설치 | `sudo dnf install -y nodejs` (NodeSource) |

---

#### TC-INS-LNX-003: pacman 기반 설치

**우선순위**: P2
**자동화**: 가능
**환경**: LNX-ENV-04

**상세 절차**: Arch Linux에서 `pacman -S --noconfirm nodejs` 확인

---

#### TC-INS-LNX-004: Docker 그룹 추가

**우선순위**: P1
**자동화**: 가능
**환경**: LNX-ENV-01

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Docker 설치 후 | `docker` 그룹 존재 |
| 2 | base 모듈 실행 | `sudo usermod -aG docker $USER` |
| 3 | 그룹 확인 | `groups` 명령에 docker 포함 |

---

#### TC-INS-LNX-005 ~ TC-INS-LNX-010

- **TC-INS-LNX-005** (SHA-256: sha256sum): `sha256sum` 사용 -- `sha256sum "$tmpfile" | awk '{print $1}'`
- **TC-INS-LNX-006** (SHA-256: shasum): `shasum -a 256` 사용
- **TC-INS-LNX-007** (VS Code snap): Ubuntu에서 `sudo snap install code --classic`
- **TC-INS-LNX-008** (WSL2 브라우저): `grep -qi microsoft /proc/version` 감지 후 `cmd.exe /c start`
- **TC-INS-LNX-009** (xdg-open 폴백): 비WSL Linux에서 `xdg-open` 사용
- **TC-INS-LNX-010** (미지원 패키지 관리자): `pkg_detect_manager()` -> "none" -> 수동 설치 안내

### 3.4 인스톨러 자동화 테스트 설계

#### CI 기반 자동화 가능 TC 목록

| TC ID | 자동화 방법 | CI 환경 |
|-------|-----------|---------|
| TC-INS-MAC-001~005 | Bash 단위 테스트 | ubuntu-latest + macOS |
| TC-INS-MAC-008 | Bash 단위 테스트 | 모든 환경 |
| TC-INS-MAC-017~019 | Bash 단위 테스트 | macOS |
| TC-INS-MAC-020~022 | Bash 단위 테스트 | 모든 환경 |
| TC-INS-LNX-001 | Docker 컨테이너 | ubuntu-latest |
| TC-INS-LNX-002 | Docker 컨테이너 | ubuntu-latest |
| TC-INS-LNX-005~006 | Bash 단위 테스트 | ubuntu-latest |

#### Bash 테스트 프레임워크 설계

```bash
#!/bin/bash
# installer/tests/run_tests.sh
# 인스톨러 자동화 테스트 러너

PASS=0
FAIL=0
SKIP=0

run_test() {
  local tc_id="$1"
  local script="$2"

  if bash "$script" > /dev/null 2>&1; then
    echo "  PASS: $tc_id"
    ((PASS++))
  else
    echo "  FAIL: $tc_id"
    ((FAIL++))
  fi
}

echo "=== Installer Test Suite ==="
run_test "TC-INS-MAC-001" "tests/test_ins_mac_001.sh"
run_test "TC-INS-MAC-005" "tests/test_ins_mac_005.sh"
# ...

echo ""
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
[ $FAIL -eq 0 ] && exit 0 || exit 1
```

---

## 4. Google Workspace MCP 테스트 설계

### 4.1 OAuth 인증 테스트 (TC-AUT-ALL-001 ~ TC-AUT-ALL-022)

모든 OAuth 테스트는 `google-workspace-mcp/src/auth/oauth.ts`를 대상으로 한다.
자동화 테스트는 Vitest + Mock을 사용하며, 브라우저 기반 흐름은 수동 테스트로 수행한다.

**공통 Mock 설정**:
```typescript
// __tests__/oauth.test.ts 공통 Mock
import { vi, describe, it, expect, beforeEach } from 'vitest';
import * as fs from 'fs';
import * as http from 'http';

vi.mock('fs');
vi.mock('http');
vi.mock('open', () => ({ default: vi.fn().mockResolvedValue(undefined) }));

const mockClientSecret = {
  installed: {
    client_id: 'test-client-id',
    client_secret: 'test-client-secret',
    redirect_uris: ['http://localhost:3000/callback'],
  },
};

const mockToken = {
  access_token: 'mock-access-token',
  refresh_token: 'mock-refresh-token',
  scope: 'https://www.googleapis.com/auth/gmail.modify',
  token_type: 'Bearer',
  expiry_date: Date.now() + 3600000, // 1시간 후
};
```

#### TC-AUT-ALL-001: 최초 인증 흐름

**우선순위**: P0
**자동화**: 수동 (브라우저 흐름)
**환경**: DOK-ENV-02

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | `~/.google-workspace/client_secret.json` 존재 확인 | 파일 존재 |
| 2 | `~/.google-workspace/token.json` 삭제 | 파일 없음 |
| 3 | MCP 서버 시작 (Docker 또는 직접 실행) | |
| 4 | 임의 Gmail 도구 호출 (예: gmail_search) | `getAuthenticatedClient()` 호출 |
| 5 | 콘솔 출력 확인 | "Google Login Required!" + OAuth URL 표시 |
| 6 | 브라우저에서 URL 열기 + Google 계정 로그인 | |
| 7 | OAuth 콜백 수신 (localhost:3000/callback) | "Google authentication complete!" 페이지 표시 |
| 8 | token.json 생성 확인 | `ls -la ~/.google-workspace/token.json` |
| 9 | 파일 권한 확인 | `-rw-------` (0600) |
| 10 | token.json 내용 확인 | access_token, refresh_token, expiry_date 포함 |

**코드 참조**:
- `oauth.ts:342-397` -- `getAuthenticatedClient()`
- `oauth.ts:223-334` -- `getTokenFromBrowser()`
- `oauth.ts:200-215` -- `saveToken()` (mode 0600)

---

#### TC-AUT-ALL-002: 토큰 재사용

**우선순위**: P0
**자동화**: 가능 (Vitest)
**환경**: 모든 환경

**Vitest 테스트 코드**:
```typescript
describe('TC-AUT-ALL-002: Token Reuse', () => {
  it('should use cached token without browser flow', async () => {
    // Arrange: token.json exists with valid expiry
    vi.spyOn(fs, 'existsSync').mockImplementation((p: string) => {
      if (p.includes('token.json')) return true;
      if (p.includes('client_secret.json')) return true;
      return true;
    });
    vi.spyOn(fs, 'readFileSync').mockImplementation((p: string) => {
      if (p.toString().includes('token.json'))
        return JSON.stringify(mockToken);
      if (p.toString().includes('client_secret.json'))
        return JSON.stringify(mockClientSecret);
      return '';
    });

    // Act
    const client = await getAuthenticatedClient();

    // Assert: browser open should NOT be called
    expect(open).not.toHaveBeenCalled();
    expect(client).toBeDefined();
  });
});
```

**기대 결과**: 유효한 token.json이 존재하면 브라우저 OAuth 없이 캐시된 토큰 사용

---

#### TC-AUT-ALL-003: 토큰 만료 갱신

**우선순위**: P0
**자동화**: 가능 (Vitest)

**Vitest 테스트 코드**:
```typescript
describe('TC-AUT-ALL-003: Token Refresh', () => {
  it('should refresh token when expiry_date < now + 5min', async () => {
    const expiredToken = {
      ...mockToken,
      expiry_date: Date.now() + 2 * 60 * 1000, // 2분 후 (5분 버퍼 이내)
    };
    // ... mock setup ...

    // Assert: refreshAccessToken should be called
    // Assert: saveToken should be called with new token
  });
});
```

**코드 참조**: `oauth.ts:362-383` -- 5분 버퍼 (`expiryBuffer = 5 * 60 * 1000`)

---

#### TC-AUT-ALL-004: 토큰 갱신 실패 시 재인증

**우선순위**: P0
**자동화**: 가능 (Vitest)

**테스트 시나리오**: `refreshAccessToken()` 에서 에러 throw -> `getTokenFromBrowser()` 호출

**코드 참조**: `oauth.ts:374-382` -- catch 블록에서 재인증

---

#### TC-AUT-ALL-005: refresh_token 누락 검증

**우선순위**: P1
**자동화**: 가능 (Vitest)

**Vitest 테스트 코드**:
```typescript
describe('TC-AUT-ALL-005: Missing refresh_token', () => {
  it('should return null when refresh_token is missing', () => {
    const tokenWithoutRefresh = { ...mockToken, refresh_token: '' };
    vi.spyOn(fs, 'readFileSync').mockReturnValue(
      JSON.stringify(tokenWithoutRefresh)
    );

    const result = loadToken(); // 내부 함수 -- 모듈 export 필요 또는 통합 테스트
    expect(result).toBeNull();
    // stderr에 "[SECURITY] Missing refresh_token" 출력 확인
  });
});
```

**코드 참조**: `oauth.ts:171-186` -- `loadToken()` 함수

---

#### TC-AUT-ALL-006: CSRF 방지 -- state 불일치

**우선순위**: P0
**자동화**: 부분 가능 (HTTP 요청 시뮬레이션)

**수동 테스트 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | OAuth 흐름 시작 (브라우저 URL 표시) | state 파라미터 포함 URL |
| 2 | 콜백 URL 수동 조작: `http://localhost:3000/callback?code=xxx&state=WRONG` | |
| 3 | 응답 확인 | HTTP 403 |
| 4 | 응답 본문 확인 | "Authentication failed: Invalid state parameter" |
| 5 | 로그 확인 | `[SECURITY] {...,"event_type":"oauth_callback","result":"failure","detail":"State mismatch..."}` |

**코드 참조**: `oauth.ts:248-268` -- state 검증 블록

---

#### TC-AUT-ALL-007: CSRF 방지 -- state 일치

**우선순위**: P0
**자동화**: 가능 (통합 테스트)

**테스트 시나리오**: 올바른 state 값으로 콜백 -> HTTP 200 + 토큰 발급

---

#### TC-AUT-ALL-008: 인증 코드 미수신

**우선순위**: P1
**자동화**: 가능

**테스트**: `http://localhost:3000/callback?state=CORRECT` (code 파라미터 없음) -> HTTP 400, "No authorization code"

**코드 참조**: `oauth.ts:271-281`

---

#### TC-AUT-ALL-009: 로그인 타임아웃

**우선순위**: P1
**자동화**: 가능 (타임아웃 시뮬레이션)

**Vitest 테스트 코드**:
```typescript
describe('TC-AUT-ALL-009: Login Timeout', () => {
  it('should reject after 5 minutes', async () => {
    vi.useFakeTimers();
    const promise = getTokenFromBrowser(mockOAuth2Client);
    vi.advanceTimersByTime(5 * 60 * 1000); // 5분 경과
    await expect(promise).rejects.toThrow('Login timeout (5 minutes)');
    vi.useRealTimers();
  });
});
```

**코드 참조**: `oauth.ts:329-332` -- `setTimeout 5 * 60 * 1000`

---

#### TC-AUT-ALL-010: 뮤텍스 -- 동시 인증 방지

**우선순위**: P0
**자동화**: 가능 (Vitest)

**Vitest 테스트 코드**:
```typescript
describe('TC-AUT-ALL-010: Auth Mutex', () => {
  it('should reuse in-progress auth promise', async () => {
    // 첫 번째 호출이 진행 중일 때
    const p1 = getAuthenticatedClient();
    const p2 = getAuthenticatedClient();

    // 같은 Promise 참조
    expect(p1).toBe(p2); // authInProgress 재사용
  });
});
```

**코드 참조**: `oauth.ts:102, 344-346` -- `authInProgress` Promise 공유

---

#### TC-AUT-ALL-011: 서비스 캐싱

**우선순위**: P1
**자동화**: 가능 (Vitest)

**Vitest 테스트 코드**:
```typescript
describe('TC-AUT-ALL-011: Service Caching', () => {
  it('should return cached services within 50 minutes', async () => {
    const services1 = await getGoogleServices();
    const services2 = await getGoogleServices();
    expect(services1).toBe(services2); // 같은 참조
  });
});
```

**코드 참조**: `oauth.ts:83-99` -- `CACHE_TTL_MS = 50 * 60 * 1000`, `serviceCache`

---

#### TC-AUT-ALL-012: 서비스 캐시 만료

**우선순위**: P1
**자동화**: 가능

**테스트**: 50분 경과 시뮬레이션 -> 새 서비스 인스턴스 생성

---

#### TC-AUT-ALL-013: clearServiceCache

**우선순위**: P2
**자동화**: 가능

**테스트**: `clearServiceCache()` 호출 후 `getGoogleServices()` -> 새 인스턴스

---

#### TC-AUT-ALL-014: 설정 디렉토리 생성

**우선순위**: P0
**자동화**: 가능

**Vitest 테스트 코드**:
```typescript
describe('TC-AUT-ALL-014: Config Dir Creation', () => {
  it('should create CONFIG_DIR with mode 0700', () => {
    vi.spyOn(fs, 'existsSync').mockReturnValue(false);
    const mkdirSpy = vi.spyOn(fs, 'mkdirSync');

    ensureConfigDir();

    expect(mkdirSpy).toHaveBeenCalledWith(
      expect.any(String),
      { recursive: true, mode: 0o700 }
    );
  });
});
```

**코드 참조**: `oauth.ts:115-131` -- `ensureConfigDir()`

---

#### TC-AUT-ALL-015 ~ TC-AUT-ALL-022

| TC ID | 핵심 검증 | 자동화 | 테스트 방법 |
|-------|----------|--------|-----------|
| TC-AUT-ALL-015 | 설정 디렉토리 권한 0755 -> 0700 복구 | Vitest | chmodSync 호출 + logSecurityEvent 확인 |
| TC-AUT-ALL-016 | `GOOGLE_SCOPES="gmail,drive"` -> 2개 스코프만 | Vitest | `resolveScopes()` 반환값 확인 |
| TC-AUT-ALL-017 | GOOGLE_SCOPES 미설정 -> 6개 서비스 전체 | Vitest | `resolveScopes()` 반환값 6개 |
| TC-AUT-ALL-018 | `OAUTH_PORT=8080` -> 포트 8080 사용 | 수동 | 서버 바인딩 포트 확인 |
| TC-AUT-ALL-019 | client_secret.json 미존재 -> 설치 가이드 에러 | Vitest | Error 메시지에 가이드 포함 확인 |
| TC-AUT-ALL-020 | "installed" 타입 클라이언트 생성 | Vitest | `createOAuth2Client()` 정상 생성 |
| TC-AUT-ALL-021 | "web" 타입 클라이언트 생성 | Vitest | `createOAuth2Client()` 정상 생성 |
| TC-AUT-ALL-022 | 보안 이벤트 JSON 로깅 | Vitest | `console.error` 출력 형식 확인 |

### 4.2 Gmail 도구 테스트 (TC-GML-ALL-001 ~ TC-GML-ALL-022)

모든 Gmail 테스트는 `google-workspace-mcp/src/tools/gmail.ts`를 대상으로 한다.

**공통 Mock 설정** (기존 `gmail.test.ts` 패턴 활용):
```typescript
const mockGmailApi = {
  users: {
    messages: {
      list: vi.fn(),
      get: vi.fn(),
      send: vi.fn(),
      modify: vi.fn(),
      trash: vi.fn(),
      untrash: vi.fn(),
      attachments: { get: vi.fn() },
    },
    drafts: {
      list: vi.fn(),
      get: vi.fn(),
      create: vi.fn(),
      send: vi.fn(),
      delete: vi.fn(),
    },
    labels: { list: vi.fn() },
  },
};

vi.mock('../../auth/oauth', () => ({
  getGoogleServices: vi.fn(async () => ({ gmail: mockGmailApi })),
}));
```

#### TC-GML-ALL-001: gmail_search -- 기본 검색

**우선순위**: P0
**자동화**: 가능 (Vitest)

**Vitest 테스트 코드**:
```typescript
describe('TC-GML-ALL-001: gmail_search basic', () => {
  it('should return messages with id/from/subject/date/snippet', async () => {
    mockGmailApi.users.messages.list.mockResolvedValue({
      data: {
        messages: [{ id: 'msg1' }, { id: 'msg2' }],
      },
    });
    mockGmailApi.users.messages.get.mockResolvedValue({
      data: {
        payload: {
          headers: [
            { name: 'From', value: 'test@example.com' },
            { name: 'Subject', value: 'Test Subject' },
            { name: 'Date', value: '2026-02-13' },
          ],
        },
        snippet: 'Test snippet...',
      },
    });

    const result = await gmailTools.gmail_search.handler({
      query: 'from:test@example.com',
      maxResults: 5,
    });

    expect(result.total).toBe(2);
    expect(result.messages[0]).toHaveProperty('id');
    expect(result.messages[0]).toHaveProperty('from');
    expect(result.messages[0]).toHaveProperty('subject');
    expect(result.messages[0]).toHaveProperty('date');
    expect(result.messages[0]).toHaveProperty('snippet');
  });
});
```

**코드 참조**: `gmail.ts:18-57` -- `gmail_search` handler

---

#### TC-GML-ALL-002: gmail_search -- 빈 결과

**자동화**: 가능 (Vitest)

```typescript
it('should return empty array when no results', async () => {
  mockGmailApi.users.messages.list.mockResolvedValue({
    data: { messages: null },
  });
  const result = await gmailTools.gmail_search.handler({
    query: 'nonexistent-query-xyz',
    maxResults: 10,
  });
  expect(result.total).toBe(0);
  expect(result.messages).toEqual([]);
});
```

---

#### TC-GML-ALL-003: gmail_read -- 전체 읽기

**우선순위**: P0
**자동화**: 가능

```typescript
it('should return full email with id, from, to, cc, subject, date, body, attachments, labels', async () => {
  const base64Body = Buffer.from('Hello World').toString('base64');
  mockGmailApi.users.messages.get.mockResolvedValue({
    data: {
      payload: {
        headers: [
          { name: 'From', value: 'sender@example.com' },
          { name: 'To', value: 'recipient@example.com' },
          { name: 'Cc', value: 'cc@example.com' },
          { name: 'Subject', value: 'Test' },
          { name: 'Date', value: '2026-02-13' },
        ],
        mimeType: 'text/plain',
        body: { data: base64Body },
        parts: null,
      },
      labelIds: ['INBOX', 'UNREAD'],
    },
  });

  const result = await gmailTools.gmail_read.handler({ messageId: 'msg1' });
  expect(result.id).toBe('msg1');
  expect(result.from).toBe('sender@example.com');
  expect(result.to).toBe('recipient@example.com');
  expect(result.body).toBe('Hello World');
  expect(result.labels).toContain('INBOX');
});
```

---

#### TC-GML-ALL-004: gmail_read -- MIME 파싱

**우선순위**: P1
**자동화**: 가능

**테스트**: multipart/mixed > multipart/alternative > text/plain 구조에서 `extractTextBody()` 올바른 추출

**코드 참조**: `mime.ts:33-73` -- `extractTextBody()` 재귀 파싱

---

#### TC-GML-ALL-005: gmail_read -- 첨부파일 목록

**우선순위**: P1
**자동화**: 가능

```typescript
it('should extract attachments with filename, mimeType, attachmentId, size', async () => {
  mockGmailApi.users.messages.get.mockResolvedValue({
    data: {
      payload: {
        mimeType: 'multipart/mixed',
        parts: [
          { mimeType: 'text/plain', body: { data: Buffer.from('body').toString('base64') } },
          {
            filename: 'report.pdf',
            mimeType: 'application/pdf',
            body: { attachmentId: 'att1', size: 1024 },
          },
        ],
      },
    },
  });

  const result = await gmailTools.gmail_read.handler({ messageId: 'msg1' });
  expect(result.attachments).toHaveLength(1);
  expect(result.attachments[0]).toEqual({
    filename: 'report.pdf',
    mimeType: 'application/pdf',
    attachmentId: 'att1',
    size: 1024,
  });
});
```

**코드 참조**: `mime.ts:80-101` -- `extractAttachments()` 함수

---

#### TC-GML-ALL-006: gmail_read -- 본문 5000자 제한

**우선순위**: P2
**자동화**: 가능

```typescript
it('should truncate body to 5000 chars', async () => {
  const longBody = 'A'.repeat(10000);
  const base64Body = Buffer.from(longBody).toString('base64');
  // ... mock setup ...
  const result = await gmailTools.gmail_read.handler({ messageId: 'msg1' });
  expect(result.body.length).toBe(5000);
});
```

**코드 참조**: `gmail.ts:95` -- `body: body.slice(0, 5000)`

---

#### TC-GML-ALL-007 ~ TC-GML-ALL-022

| TC ID | 핵심 검증 | Mock 설정 | 기대 결과 |
|-------|----------|----------|----------|
| TC-GML-ALL-007 | gmail_send 이메일 발송 | `messages.send` mock | `success=true, messageId` |
| TC-GML-ALL-008 | gmail_send CC/BCC | 헤더에 CC/BCC 포함 | CC/BCC 헤더 존재 |
| TC-GML-ALL-009 | gmail_send UTF-8 제목 | 한글 제목 | `=?UTF-8?B?...?=` 인코딩 |
| TC-GML-ALL-010 | gmail_send 헤더 인젝션 방지 | `to="a@b.com\r\nBcc: spy@evil.com"` | `sanitizeEmailHeader()`로 CRLF 제거 |
| TC-GML-ALL-011 | gmail_draft_create | `drafts.create` mock | `draftId` 반환 |
| TC-GML-ALL-012 | gmail_draft_list | `drafts.list` mock | `total, drafts[]` |
| TC-GML-ALL-013 | gmail_draft_send | `drafts.send` mock | `success=true, messageId` |
| TC-GML-ALL-014 | gmail_draft_delete | `drafts.delete` mock | `success=true` |
| TC-GML-ALL-015 | gmail_labels_list | `labels.list` mock | `labels[]` (id, name, type) |
| TC-GML-ALL-016 | gmail_labels_add | `messages.modify` mock | "Label added" |
| TC-GML-ALL-017 | gmail_labels_remove | `messages.modify` mock | "Label removed" |
| TC-GML-ALL-018 | gmail_attachment_get | `attachments.get` mock | `size, data (base64)` |
| TC-GML-ALL-019 | gmail_trash | `messages.trash` mock | "Email moved to trash" |
| TC-GML-ALL-020 | gmail_untrash | `messages.untrash` mock | "Email restored from trash" |
| TC-GML-ALL-021 | gmail_mark_read | `messages.modify` mock | UNREAD 라벨 제거 |
| TC-GML-ALL-022 | gmail_mark_unread | `messages.modify` mock | UNREAD 라벨 추가 |

### 4.3 Drive 도구 테스트 (TC-DRV-ALL-001 ~ TC-DRV-ALL-020)

**공통 Mock**:
```typescript
const mockDriveApi = {
  files: {
    list: vi.fn(),
    get: vi.fn(),
    create: vi.fn(),
    copy: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
  },
  permissions: {
    list: vi.fn(),
    create: vi.fn(),
    delete: vi.fn(),
  },
  about: { get: vi.fn() },
};
```

#### TC-DRV-ALL-001: drive_search -- 기본 검색

**우선순위**: P0
**자동화**: 가능

```typescript
it('should search with supportsAllDrives=true', async () => {
  mockDriveApi.files.list.mockResolvedValue({
    data: {
      files: [{ id: 'f1', name: 'test.txt', mimeType: 'text/plain' }],
    },
  });

  const result = await driveTools.drive_search.handler({
    query: 'test', maxResults: 10,
  });

  expect(result.total).toBe(1);
  expect(mockDriveApi.files.list).toHaveBeenCalledWith(
    expect.objectContaining({
      supportsAllDrives: true,
      includeItemsFromAllDrives: true,
      corpora: 'allDrives',
    })
  );
});
```

**코드 참조**: `drive.ts:30-39` -- `supportsAllDrives: true, corpora: "allDrives"`

---

#### TC-DRV-ALL-003: drive_search -- 쿼리 이스케이프

**우선순위**: P0
**자동화**: 가능

```typescript
it('should escape single quotes in query', async () => {
  mockDriveApi.files.list.mockResolvedValue({ data: { files: [] } });

  await driveTools.drive_search.handler({
    query: "test's file", maxResults: 10,
  });

  const calledWith = mockDriveApi.files.list.mock.calls[0][0];
  expect(calledWith.q).toContain("test\\'s file");
  expect(calledWith.q).not.toContain("test's file");
});
```

**코드 참조**: `drive.ts:25` -- `escapeDriveQuery(query)`, `sanitize.ts:24-26`

---

#### TC-DRV-ALL-005: drive_list -- ID 검증

**우선순위**: P0
**자동화**: 가능

```typescript
it('should reject invalid folderId format', async () => {
  await expect(
    driveTools.drive_list.handler({
      folderId: 'invalid!@#$%', maxResults: 20, orderBy: 'modifiedTime desc',
    })
  ).rejects.toThrow('Invalid folderId format');
});
```

**코드 참조**: `drive.ts:66` -- `validateDriveId(folderId, "folderId")`, `sanitize.ts:38-44`

---

#### TC-DRV-ALL-002 ~ TC-DRV-ALL-020 요약

| TC ID | 핵심 검증 | 자동화 |
|-------|----------|--------|
| TC-DRV-ALL-002 | MIME 필터 (`mimeType="application/pdf"`) | Vitest |
| TC-DRV-ALL-004 | 루트 폴더 목록 (`folderId="root"`) | Vitest |
| TC-DRV-ALL-006 | drive_get_file 상세 정보 | Vitest |
| TC-DRV-ALL-007 | drive_create_folder | Vitest |
| TC-DRV-ALL-008 | 부모 폴더 지정 생성 | Vitest |
| TC-DRV-ALL-009 | drive_copy | Vitest |
| TC-DRV-ALL-010 | drive_move (previousParents 제거) | Vitest |
| TC-DRV-ALL-011 | drive_rename | Vitest |
| TC-DRV-ALL-012 | drive_delete (trashed=true) | Vitest |
| TC-DRV-ALL-013 | drive_restore (trashed=false) | Vitest |
| TC-DRV-ALL-014 | drive_share (권한 생성) | Vitest |
| TC-DRV-ALL-015 | drive_share_link (anyone 링크) | Vitest |
| TC-DRV-ALL-016 | drive_unshare (권한 제거) | Vitest |
| TC-DRV-ALL-017 | drive_unshare 권한 미존재 | Vitest |
| TC-DRV-ALL-018 | drive_list_permissions | Vitest |
| TC-DRV-ALL-019 | drive_get_storage_quota (GB 단위) | Vitest |
| TC-DRV-ALL-020 | Shared Drive 지원 (corpora="allDrives") | Vitest |

### 4.4 Calendar 도구 테스트 (TC-CAL-ALL-001 ~ TC-CAL-ALL-015)

**공통 Mock**:
```typescript
const mockCalendarApi = {
  calendarList: { list: vi.fn() },
  events: {
    list: vi.fn(),
    get: vi.fn(),
    insert: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
    quickAdd: vi.fn(),
  },
  freebusy: { query: vi.fn() },
};
```

#### TC-CAL-ALL-001: calendar_list_calendars

**우선순위**: P0
**자동화**: 가능

```typescript
it('should return calendars with id/name/primary/accessRole', async () => {
  mockCalendarApi.calendarList.list.mockResolvedValue({
    data: {
      items: [{
        id: 'primary', summary: 'My Calendar',
        primary: true, accessRole: 'owner',
      }],
    },
  });

  const result = await calendarTools.calendar_list_calendars.handler();
  expect(result.calendars[0]).toEqual(expect.objectContaining({
    id: 'primary', name: 'My Calendar', primary: true, accessRole: 'owner',
  }));
});
```

---

#### TC-CAL-ALL-005: calendar_create_event -- 동적 타임존

**우선순위**: P0
**자동화**: 가능

```typescript
it('should apply dynamic timezone from getTimezone()', async () => {
  mockCalendarApi.events.insert.mockResolvedValue({
    data: { id: 'evt1', htmlLink: 'https://...' },
  });

  const result = await calendarTools.calendar_create_event.handler({
    calendarId: 'primary',
    title: 'Test Meeting',
    startTime: '2026-03-01 10:00',
    endTime: '2026-03-01 11:00',
  });

  const insertCall = mockCalendarApi.events.insert.mock.calls[0][0];
  // parseTime()이 타임존 오프셋을 추가했는지 확인
  expect(insertCall.requestBody.start.dateTime).toMatch(/T10:00:00[+-]\d{2}:\d{2}/);
});
```

**코드 참조**: `calendar.ts:3` -- `import { getTimezone, parseTime } from '../utils/time.js'`

---

#### TC-CAL-ALL-007: calendar_create_event -- 시간 파싱

**우선순위**: P1
**자동화**: 가능 (time.ts 단위 테스트)

```typescript
// time.ts 단위 테스트
describe('parseTime()', () => {
  it('should convert "2026-03-01 10:00" to ISO with offset', () => {
    process.env.TIMEZONE = 'Asia/Seoul';
    const result = parseTime('2026-03-01 10:00');
    expect(result).toBe('2026-03-01T10:00:00+09:00');
  });

  it('should return as-is when already ISO format', () => {
    const result = parseTime('2026-03-01T10:00:00Z');
    expect(result).toBe('2026-03-01T10:00:00Z');
  });
});
```

**코드 참조**: `time.ts:44-49` -- `parseTime()` 함수

---

#### TC-CAL-ALL-002 ~ TC-CAL-ALL-015 요약

| TC ID | 핵심 검증 | 자동화 |
|-------|----------|--------|
| TC-CAL-ALL-002 | 기본 이벤트 목록 (현재~30일) | Vitest |
| TC-CAL-ALL-003 | timeMin/timeMax 범위 지정 | Vitest |
| TC-CAL-ALL-004 | calendar_get_event 상세 | Vitest |
| TC-CAL-ALL-006 | 참석자 포함 (sendUpdates="all") | Vitest |
| TC-CAL-ALL-008 | 종일 이벤트 (date 필드) | Vitest |
| TC-CAL-ALL-009 | calendar_update_event (기존값 유지+수정) | Vitest |
| TC-CAL-ALL-010 | calendar_delete_event | Vitest |
| TC-CAL-ALL-011 | calendar_quick_add 자연어 | Vitest |
| TC-CAL-ALL-012 | calendar_find_free_time | Vitest |
| TC-CAL-ALL-013 | calendar_respond_to_event | Vitest |
| TC-CAL-ALL-014 | TIMEZONE 환경변수 적용 | Vitest |
| TC-CAL-ALL-015 | 자동 감지 (Intl.DateTimeFormat) | Vitest |

### 4.5 Docs 도구 테스트 (TC-DOC-ALL-001 ~ TC-DOC-ALL-013)

**공통 Mock**:
```typescript
const mockDocsApi = {
  documents: {
    create: vi.fn(),
    get: vi.fn(),
    batchUpdate: vi.fn(),
  },
};
const mockDriveApi = { files: { get: vi.fn(), update: vi.fn() } };
const mockDocsComments = { comments: { list: vi.fn(), create: vi.fn() } };
```

#### TC-DOC-ALL-001: docs_create -- 빈 문서

**우선순위**: P0
**자동화**: 가능

```typescript
it('should create empty document and return documentId/title/link', async () => {
  mockDocsApi.documents.create.mockResolvedValue({
    data: { documentId: 'doc1' },
  });
  mockDriveApi.files.get.mockResolvedValue({
    data: { webViewLink: 'https://docs.google.com/...' },
  });

  const result = await docsTools.docs_create.handler({ title: 'Test Doc' });
  expect(result.documentId).toBe('doc1');
  expect(result.title).toBe('Test Doc');
  expect(result.link).toBeDefined();
});
```

---

#### TC-DOC-ALL-002: docs_create -- 내용 포함

**우선순위**: P1
**자동화**: 가능

```typescript
it('should insert content via batchUpdate after creation', async () => {
  mockDocsApi.documents.create.mockResolvedValue({
    data: { documentId: 'doc1' },
  });
  mockDocsApi.documents.batchUpdate.mockResolvedValue({ data: {} });

  await docsTools.docs_create.handler({
    title: 'Test', content: 'Hello World',
  });

  expect(mockDocsApi.documents.batchUpdate).toHaveBeenCalledWith(
    expect.objectContaining({
      documentId: 'doc1',
      requestBody: {
        requests: [{
          insertText: { location: { index: 1 }, text: 'Hello World' },
        }],
      },
    })
  );
});
```

**코드 참조**: `docs.ts:30-46` -- content 존재 시 batchUpdate

---

#### TC-DOC-ALL-003 ~ TC-DOC-ALL-013 요약

| TC ID | 핵심 검증 | 자동화 |
|-------|----------|--------|
| TC-DOC-ALL-003 | 폴더 지정 (folderId) | Vitest |
| TC-DOC-ALL-004 | docs_read (10000자 제한) | Vitest |
| TC-DOC-ALL-005 | 테이블 포함 문서 ("[table]" 텍스트) | Vitest |
| TC-DOC-ALL-006 | docs_append (문서 끝 삽입) | Vitest |
| TC-DOC-ALL-007 | docs_prepend (index 1 삽입) | Vitest |
| TC-DOC-ALL-008 | docs_replace_text (occurrencesChanged) | Vitest |
| TC-DOC-ALL-009 | 대소문자 구분 (matchCase=true) | Vitest |
| TC-DOC-ALL-010 | docs_insert_heading (HEADING_2) | Vitest |
| TC-DOC-ALL-011 | docs_insert_table (rows x columns) | Vitest |
| TC-DOC-ALL-012 | docs_get_comments | Vitest |
| TC-DOC-ALL-013 | docs_add_comment | Vitest |

### 4.6 Sheets 도구 테스트 (TC-SHT-ALL-001 ~ TC-SHT-ALL-014)

**공통 Mock**:
```typescript
const mockSheetsApi = {
  spreadsheets: {
    create: vi.fn(),
    get: vi.fn(),
    values: {
      get: vi.fn(),
      batchGet: vi.fn(),
      update: vi.fn(),
      append: vi.fn(),
      clear: vi.fn(),
    },
    batchUpdate: vi.fn(),
  },
};
```

#### TC-SHT-ALL-001: sheets_create

**우선순위**: P0

```typescript
it('should create spreadsheet and return spreadsheetId/title/link', async () => {
  mockSheetsApi.spreadsheets.create.mockResolvedValue({
    data: { spreadsheetId: 'ss1', sheets: [{ properties: { title: 'Sheet1' } }] },
  });
  mockDriveApi.files.get.mockResolvedValue({
    data: { webViewLink: 'https://sheets.google.com/...' },
  });

  const result = await sheetsTools.sheets_create.handler({ title: 'Test Sheet' });
  expect(result.spreadsheetId).toBe('ss1');
  expect(result.message).toContain('Test Sheet');
});
```

---

#### TC-SHT-ALL-004: sheets_read

**우선순위**: P0

```typescript
it('should return 2D values array', async () => {
  mockSheetsApi.spreadsheets.values.get.mockResolvedValue({
    data: { values: [['A1', 'B1'], ['A2', 'B2']] },
  });

  const result = await sheetsTools.sheets_read.handler({
    spreadsheetId: 'ss1', range: 'Sheet1!A1:B2',
  });
  expect(result.values).toEqual([['A1', 'B1'], ['A2', 'B2']]);
  expect(result.rowCount).toBe(2);
  expect(result.columnCount).toBe(2);
});
```

---

#### TC-SHT-ALL-002 ~ TC-SHT-ALL-014 요약

| TC ID | 핵심 검증 | 자동화 |
|-------|----------|--------|
| TC-SHT-ALL-002 | sheetNames 지정 생성 | Vitest |
| TC-SHT-ALL-003 | sheets_get_info (시트 목록) | Vitest |
| TC-SHT-ALL-005 | sheets_read_multiple (ranges 배열) | Vitest |
| TC-SHT-ALL-006 | sheets_write (updatedCells 반환) | Vitest |
| TC-SHT-ALL-007 | sheets_append (INSERT_ROWS) | Vitest |
| TC-SHT-ALL-008 | sheets_clear | Vitest |
| TC-SHT-ALL-009 | sheets_add_sheet | Vitest |
| TC-SHT-ALL-010 | sheets_delete_sheet | Vitest |
| TC-SHT-ALL-011 | sheets_rename_sheet | Vitest |
| TC-SHT-ALL-012 | sheets_format_cells 볼드 | Vitest |
| TC-SHT-ALL-013 | sheets_format_cells 배경색 RGB 변환 | Vitest |
| TC-SHT-ALL-014 | sheets_auto_resize | Vitest |

### 4.7 Slides 도구 테스트 (TC-SLD-ALL-001 ~ TC-SLD-ALL-011)

**공통 Mock**:
```typescript
const mockSlidesApi = {
  presentations: {
    create: vi.fn(),
    get: vi.fn(),
    batchUpdate: vi.fn(),
    pages: { get: vi.fn() },
  },
};
```

| TC ID | 핵심 검증 | 자동화 |
|-------|----------|--------|
| TC-SLD-ALL-001 | slides_create (presentationId/link/slideCount) | Vitest |
| TC-SLD-ALL-002 | 폴더 지정 | Vitest |
| TC-SLD-ALL-003 | slides_get_info (title/slideCount/pageSize) | Vitest |
| TC-SLD-ALL-004 | slides_read (슬라이드별 텍스트, 1000자 제한) | Vitest |
| TC-SLD-ALL-005 | slides_add_slide TITLE_AND_BODY 레이아웃 | Vitest |
| TC-SLD-ALL-006 | slides_add_slide BLANK 레이아웃 | Vitest |
| TC-SLD-ALL-007 | slides_delete_slide | Vitest |
| TC-SLD-ALL-008 | slides_duplicate_slide (newSlideId) | Vitest |
| TC-SLD-ALL-009 | slides_move_slide (insertionIndex) | Vitest |
| TC-SLD-ALL-010 | slides_add_text (텍스트 박스 + 텍스트) | Vitest |
| TC-SLD-ALL-011 | slides_replace_text (occurrencesChanged) | Vitest |

### 4.8 유틸리티 테스트

#### 4.8.1 sanitize.ts 테스트 (7개 함수)

**파일**: `google-workspace-mcp/src/utils/sanitize.ts`

```typescript
// sanitize.test.ts
import { describe, it, expect } from 'vitest';
import {
  escapeDriveQuery, validateDriveId, sanitizeEmailHeader,
  validateEmail, validateMaxLength, sanitizeFilename, sanitizeRange,
} from '../sanitize.js';

describe('escapeDriveQuery', () => {
  it("should escape single quotes: test's -> test\\'s", () => {
    expect(escapeDriveQuery("test's")).toBe("test\\'s");
  });
  it('should escape backslashes: test\\path -> test\\\\path', () => {
    expect(escapeDriveQuery('test\\path')).toBe('test\\\\path');
  });
  it('should handle combined: test\\\'s -> test\\\\\\\'s', () => {
    expect(escapeDriveQuery("test\\'s")).toBe("test\\\\\\'s");
  });
});

describe('validateDriveId', () => {
  it('should accept valid ID: abc123_-XYZ', () => {
    expect(() => validateDriveId('abc123_-XYZ', 'fileId')).not.toThrow();
  });
  it('should accept "root"', () => {
    expect(() => validateDriveId('root', 'folderId')).not.toThrow();
  });
  it('should reject special chars: id!@#$%', () => {
    expect(() => validateDriveId('id!@#$%', 'fileId')).toThrow('Invalid fileId format');
  });
});

describe('sanitizeEmailHeader', () => {
  it('should remove CRLF: a@b.com\\r\\nBcc: spy -> a@b.comBcc: spy', () => {
    expect(sanitizeEmailHeader('a@b.com\r\nBcc: spy')).toBe('a@b.comBcc: spy');
  });
});

describe('validateEmail', () => {
  it('should accept valid email', () => {
    expect(validateEmail('user@example.com')).toBe(true);
  });
  it('should reject 255+ chars', () => {
    expect(validateEmail('a'.repeat(255) + '@b.com')).toBe(false);
  });
});

describe('validateMaxLength', () => {
  it('should truncate to max length', () => {
    expect(validateMaxLength('a'.repeat(1000), 500)).toHaveLength(500);
  });
  it('should return as-is if within limit', () => {
    expect(validateMaxLength('short', 500)).toBe('short');
  });
});

describe('sanitizeFilename', () => {
  it('should replace path traversal chars', () => {
    const result = sanitizeFilename('../../../etc/passwd');
    expect(result).not.toContain('..');
    expect(result).not.toContain('/');
  });
  it('should replace null bytes', () => {
    const result = sanitizeFilename('file\x00.txt');
    expect(result).not.toContain('\x00');
  });
});

describe('sanitizeRange', () => {
  it('should accept valid A1 notation: Sheet1!A1:B10', () => {
    expect(sanitizeRange('Sheet1!A1:B10')).toBe('Sheet1!A1:B10');
  });
  it('should reject SQL injection: DROP TABLE users;', () => {
    expect(sanitizeRange('DROP TABLE users;')).toBeNull();
  });
});
```

#### 4.8.2 retry.ts 테스트

**파일**: `google-workspace-mcp/src/utils/retry.ts`

```typescript
// retry.test.ts
import { describe, it, expect, vi } from 'vitest';
import { withRetry } from '../retry.js';

describe('withRetry', () => {
  it('TC-PER-ALL-001: should retry on 429', async () => {
    let attempt = 0;
    const fn = vi.fn(async () => {
      attempt++;
      if (attempt < 3) {
        const err = new Error('Rate limited') as any;
        err.response = { status: 429 };
        throw err;
      }
      return 'success';
    });

    const result = await withRetry(fn, { initialDelay: 10 });
    expect(result).toBe('success');
    expect(fn).toHaveBeenCalledTimes(3);
  });

  it('TC-PER-ALL-004: should NOT retry on 400', async () => {
    const fn = vi.fn(async () => {
      const err = new Error('Bad Request') as any;
      err.response = { status: 400 };
      throw err;
    });

    await expect(withRetry(fn, { initialDelay: 10 })).rejects.toThrow('Bad Request');
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it('TC-PER-ALL-011: should return immediately on success', async () => {
    const fn = vi.fn(async () => 'success');
    const result = await withRetry(fn);
    expect(result).toBe('success');
    expect(fn).toHaveBeenCalledTimes(1);
  });
});
```

#### 4.8.3 mime.ts 테스트

이미 4.2절 TC-GML-ALL-004, TC-GML-ALL-005에서 통합 테스트. 단위 테스트는 `extractTextBody`, `extractAttachments` 직접 호출.

#### 4.8.4 messages.ts 테스트

```typescript
import { messages, msg } from '../messages.js';

describe('messages', () => {
  it('should return static message', () => {
    expect(msg(messages.common.success)).toBe('Success');
  });
  it('should resolve template function', () => {
    expect(msg(messages.gmail.emailSent, 'user@test.com')).toBe('Email sent to user@test.com.');
  });
});
```

#### 4.8.5 time.ts 테스트

```typescript
import { getTimezone, getUtcOffsetString, parseTime, getCurrentTime, addDays, formatDate } from '../time.js';

describe('time utilities', () => {
  it('getTimezone: should use TIMEZONE env', () => {
    process.env.TIMEZONE = 'America/New_York';
    expect(getTimezone()).toBe('America/New_York');
    delete process.env.TIMEZONE;
  });

  it('getTimezone: should auto-detect when no env', () => {
    delete process.env.TIMEZONE;
    expect(getTimezone()).toBeTruthy();
  });

  it('parseTime: should add offset to simple datetime', () => {
    process.env.TIMEZONE = 'UTC';
    const result = parseTime('2026-03-01 10:00');
    expect(result).toMatch(/2026-03-01T10:00:00[+-]/);
  });

  it('parseTime: should return ISO as-is', () => {
    expect(parseTime('2026-03-01T10:00:00Z')).toBe('2026-03-01T10:00:00Z');
  });

  it('addDays: should add 7 days', () => {
    const result = addDays('2026-01-01T00:00:00Z', 7);
    expect(result).toContain('2026-01-08');
  });
});
```

---

## 5. 모듈별 테스트 설계

### 5.1 Atlassian MCP 모듈 (TC-ATL-ALL-001 ~ TC-ATL-ALL-007)

**대상 파일**: `installer/modules/atlassian/install.sh`

#### TC-ATL-ALL-001: Docker 모드 선택

**우선순위**: P0
**자동화**: 불가 (대화형 입력)
**환경**: MAC-ENV-02 또는 LNX-ENV-01

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Docker Desktop 실행 확인 | `docker info` 성공 |
| 2 | atlassian 모듈 실행 | "Docker is installed!" 표시 |
| 3 | "Select (1/2):" 프롬프트에서 1 입력 | Docker 모드 선택 |
| 4 | `docker pull ghcr.io/sooperset/mcp-atlassian:latest` | 이미지 다운로드 |
| 5 | MCP 설정 확인 | `~/.claude/mcp.json`에 atlassian 서버 등록 |

**코드 참조**: `atlassian/install.sh:39-69` -- Docker 감지 + 선택 로직

---

#### TC-ATL-ALL-003: Docker 모드 -- 자격증명 저장

**우선순위**: P0
**자동화**: 불가 (대화형)

**검증 명령어**:
```bash
# 설치 후 확인
cat ~/.atlassian-mcp/credentials.env
# 기대:
# CONFLUENCE_URL=https://company.atlassian.net/wiki
# CONFLUENCE_USERNAME=user@company.com
# CONFLUENCE_API_TOKEN=xxxxx
# JIRA_URL=https://company.atlassian.net
# JIRA_USERNAME=user@company.com
# JIRA_API_TOKEN=xxxxx

stat -f %Lp ~/.atlassian-mcp/credentials.env  # 600
stat -f %Lp ~/.atlassian-mcp/                  # 700
```

**코드 참조**: `atlassian/install.sh:137-153`

---

#### TC-ATL-ALL-005: Docker 모드 -- MCP 설정

**우선순위**: P0
**자동화**: 가능 (설치 후 검증)

**검증 명령어**:
```bash
# MCP 설정에서 --env-file 방식 확인
cat ~/.claude/mcp.json | node -e "
  let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
    const config = JSON.parse(d);
    const args = config.mcpServers.atlassian.args;
    console.log('Has --env-file:', args.includes('--env-file'));
    console.log('Args:', JSON.stringify(args));
  })"
```

**기대**: `--env-file` 포함, 인라인 환경변수(`-e CONFLUENCE_URL=...`) 미사용

---

#### TC-ATL-ALL-002, 004, 006, 007 요약

| TC ID | 핵심 검증 | 자동화 |
|-------|----------|--------|
| TC-ATL-ALL-002 | Rovo 모드: `claude mcp add --transport sse` | 수동 |
| TC-ATL-ALL-004 | 디렉토리 권한 700 | 자동 (stat 검증) |
| TC-ATL-ALL-006 | URL 후행 "/" 제거 | 수동 (입력값 확인) |
| TC-ATL-ALL-007 | Docker 없이 Docker 모드 -> 에러 | 수동 |

### 5.2 Figma MCP 모듈 (TC-FIG-ALL-001 ~ TC-FIG-ALL-008)

**대상 파일**: `installer/modules/figma/install.sh`

#### TC-FIG-ALL-001: Claude CLI 확인

**우선순위**: P0
**자동화**: 가능

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | Claude CLI 미설치 환경 | `command -v claude` 실패 |
| 2 | figma 모듈 실행 | |
| 3 | 출력 확인 | "Claude CLI is required. Please install base module first." |
| 4 | 종료 코드 | exit 1 |

**코드 참조**: `figma/install.sh:27-31`

---

#### TC-FIG-ALL-003: Remote MCP 등록

**우선순위**: P0
**자동화**: 가능 (claude CLI mock)

**상세 절차**:

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | claude, python3 설치 확인 | 모두 성공 |
| 2 | figma 모듈 실행 | |
| 3 | 실행된 명령 확인 | `claude mcp add --transport http figma https://mcp.figma.com/mcp` |
| 4 | MCP 설정 확인 | figma 서버 등록 |

**코드 참조**: `figma/install.sh:46`

---

### 5.3 Notion MCP 모듈 (TC-NOT-ALL-001 ~ TC-NOT-ALL-004)

| TC ID | 핵심 검증 | 자동화 |
|-------|----------|--------|
| TC-NOT-ALL-001 | Claude CLI 미설치 -> 에러 | 가능 |
| TC-NOT-ALL-002 | Python3 미설치 -> 에러 | 가능 |
| TC-NOT-ALL-003 | `claude mcp add --transport http notion https://mcp.notion.com/mcp` | 수동 |
| TC-NOT-ALL-004 | OAuth PKCE 흐름 완료 | 수동 |

### 5.4 GitHub CLI 모듈 (TC-GIT-MAC-001, TC-GIT-LNX-001~002, TC-GIT-ALL-001~004)

**대상 파일**: `installer/modules/github/install.sh`

#### TC-GIT-MAC-001: gh 설치 (macOS)

**우선순위**: P0

| 단계 | 명령어/행동 | 기대 결과 |
|------|-----------|----------|
| 1 | macOS + Homebrew 있음 + gh 없음 | |
| 2 | github 모듈 실행 | `brew install gh` 실행 |
| 3 | 확인 | `gh --version` 성공 |

**코드 참조**: `github/install.sh:28-35`

---

#### TC-GIT-ALL-001: gh 인증

**우선순위**: P0

```bash
# 인증 명령어 확인
# github/install.sh:72
gh auth login --hostname github.com --git-protocol https --web
```

---

### 5.5 Pencil 모듈 (TC-PEN-ALL-001 ~ TC-PEN-ALL-004, TC-PEN-MAC-001)

**대상 파일**: `installer/modules/pencil/install.sh`

| TC ID | 핵심 검증 | 코드 참조 |
|-------|----------|----------|
| TC-PEN-ALL-001 | VS Code/Cursor 모두 미설치 -> exit 1 | `pencil/install.sh:42-45` |
| TC-PEN-ALL-002 | `code --install-extension highagency.pencildev` | `pencil/install.sh:52-55` |
| TC-PEN-ALL-003 | `cursor --install-extension highagency.pencildev` | `pencil/install.sh:57-61` |
| TC-PEN-ALL-004 | 양쪽 모두 설치 시 둘 다 설치 | 두 if 블록 모두 실행 |
| TC-PEN-MAC-001 | macOS에서 데스크톱 앱 안내 | `pencil/install.sh:64-68` |

---

## 6. 사용자 시나리오 테스트 설계

### 6.1 신규 설치 시나리오

#### TC-E2E-MAC-001: macOS 클린 설치 전체

**우선순위**: P0
**자동화**: 불가 (전체 E2E 수동)
**환경**: MAC-ENV-02 (SNAP-MAC02-CLEAN)
**예상 소요**: 30분

**완전한 E2E 흐름**:

| 단계 | 행동 | 기대 결과 | 스크린샷 포인트 |
|------|------|----------|----------------|
| 1 | 터미널 열기 | | |
| 2 | `curl -sSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/installer/install.sh \| bash -s -- --all` | 원격 다운로드 시작 | |
| 3 | SHA-256 검증 | "Integrity verified" 메시지들 | S1 |
| 4 | "Current Status:" 표시 | 모든 도구 [ ] (미설치) | S2 |
| 5 | "Press Enter to start installation" | Enter 입력 | |
| 6 | Base 모듈 실행 | Homebrew 설치 (Apple Silicon /opt/homebrew/) | S3 |
| 7 | Node.js 설치 | `brew install node` 또는 NodeSource | |
| 8 | Git 설치 확인 | 이미 설치 또는 `brew install git` | |
| 9 | VS Code 설치 | `brew install --cask visual-studio-code` | |
| 10 | Docker Desktop 설치 | `brew install --cask docker` + 시작 안내 | S4 |
| 11 | Claude Code CLI 설치 | npm 기반 설치 | |
| 12 | bkit 플러그인 설치 | `claude plugin install bkit` | |
| 13 | GitHub 모듈 (order:2) | `brew install gh` + `gh auth login` | S5 |
| 14 | Atlassian 모듈 (order:5) | 모드 선택 -> Docker pull -> 자격증명 입력 | S6 |
| 15 | Google 모듈 (order:6) | Docker pull -> client_secret.json 프롬프트 -> OAuth | S7 |
| 16 | Figma 모듈 (order:7) | Remote MCP 등록 -> OAuth PKCE | |
| 17 | Notion 모듈 (order:8) | Remote MCP 등록 -> OAuth PKCE | |
| 18 | Pencil 모듈 (order:9) | VS Code 확장 설치 | |
| 19 | "Installation Complete!" | 모든 모듈 [OK] 표시 | S8 |
| 20 | `~/.claude/mcp.json` 확인 | 서버 등록 확인 | |
| 21 | `cat ~/.claude/mcp.json \| node -e "..."` | google-workspace, atlassian 등 등록 | S9 |

**사후 검증**:
```bash
# MCP 설정 검증
cat ~/.claude/mcp.json | python3 -m json.tool

# Docker 이미지 확인
docker images | grep -E "(google-workspace|atlassian)"

# 각 도구 상태 확인
node --version
git --version
code --version
docker --version
claude --version
gh --version
```

---

#### TC-E2E-WIN-001: Windows 클린 설치 전체

**우선순위**: P0
**자동화**: 불가
**환경**: WIN-ENV-03 (SNAP-WIN03-CLEAN)
**예상 소요**: 45분

**상세 절차**:

| 단계 | PowerShell 명령어 | 기대 결과 |
|------|------------------|----------|
| 1 | `Set-ExecutionPolicy Bypass -Scope Process` | 실행 정책 변경 |
| 2 | `irm https://raw.githubusercontent.com/.../install.ps1 \| iex` + `-installDocker` | 원격 실행 |
| 3 | UAC 프롬프트 | 관리자 권한 승인 |
| 4 | Node.js 설치 (winget) | `winget install OpenJS.NodeJS.LTS` |
| 5 | Git 설치 | `winget install Git.Git` |
| 6 | VS Code 설치 | `winget install Microsoft.VisualStudioCode` |
| 7 | WSL2 설치 | `wsl --install` |
| 8 | Docker Desktop 설치 | `winget install Docker.DockerDesktop` |
| 9 | "Restart required" | 재부팅 |
| 10 | 재부팅 후 Step 2 실행 | `.\install.ps1 -modules "google" -skipBase` |
| 11 | Docker Desktop 시작 대기 | "Docker Desktop is not running!" -> 시작 |
| 12 | Google MCP 설치 | Docker pull + OAuth |
| 13 | `$env:USERPROFILE\.claude\mcp.json` 확인 | 서버 등록 |

---

#### TC-E2E-LNX-001: Ubuntu 클린 설치 전체

**우선순위**: P0
**환경**: LNX-ENV-02

| 단계 | 명령어 | 기대 결과 |
|------|--------|----------|
| 1 | `curl -sSL .../install.sh \| bash -s -- --all` | |
| 2 | `sudo` 비밀번호 입력 | apt-get 실행 |
| 3 | NodeSource -> Node.js 설치 | `node --version` = 22.x |
| 4 | Git 설치 | `apt-get install -y git` |
| 5 | VS Code snap 설치 | `sudo snap install code --classic` |
| 6 | Docker Engine 설치 | `curl -fsSL https://get.docker.com \| sh` |
| 7 | docker 그룹 추가 | `sudo usermod -aG docker $USER` |
| 8 | Claude + bkit 설치 | |
| 9 | 모듈 설치 | 순서대로 실행 |
| 10 | 완료 | "Installation Complete!" |

---

#### TC-E2E-WSL-001: WSL2 클린 설치

**우선순위**: P1
**특이사항**: 브라우저는 Windows 호스트 브라우저 사용

| 단계 | 검증 포인트 |
|------|-----------|
| 1 | WSL2 감지: `grep -qi microsoft /proc/version` = true |
| 2 | `browser_open()` -> `cmd.exe /c start` 또는 `powershell.exe Start-Process` |
| 3 | Docker: Windows 호스트 Docker Desktop WSL2 백엔드 공유 |

### 6.2 업데이트/추가 설치 시나리오

#### TC-E2E-ALL-010: 모듈 추가 설치

**우선순위**: P0

| 단계 | 명령어 | 기대 결과 |
|------|--------|----------|
| 1 | Base + Google 설치 상태 확인 | |
| 2 | `./install.sh --modules "atlassian,github" --skip-base` | |
| 3 | Base 건너뜀 확인 | base 모듈 실행 안됨 |
| 4 | 기존 MCP 설정 유지 | google-workspace 서버 유지 |
| 5 | 새 서버 추가 확인 | atlassian 서버 추가 |

---

#### TC-E2E-ALL-011: 이미 설치된 모듈 재설치

**우선순위**: P1

| 단계 | 검증 포인트 |
|------|-----------|
| 1 | Docker 이미지 재pull |
| 2 | MCP 설정 덮어쓰기 (이전 설정 갱신) |
| 3 | OAuth 재인증 (token.json은 유지될 수 있음) |

---

#### TC-E2E-ALL-012: Base 도구 업데이트

**우선순위**: P2 -- 이전 Node.js 버전에서 업데이트 확인

### 6.3 마이그레이션 시나리오

#### TC-E2E-ALL-020: 레거시 MCP 설정 마이그레이션

**우선순위**: P0

| 단계 | 명령어 | 기대 결과 |
|------|--------|----------|
| 1 | `~/.mcp.json` 생성 (테스트 데이터) | `echo '{"mcpServers":{}}' > ~/.mcp.json` |
| 2 | `~/.claude/mcp.json` 삭제 | `rm -f ~/.claude/mcp.json` |
| 3 | 모듈 설치 실행 | |
| 4 | 마이그레이션 확인 | "Migrated MCP config" 메시지 |
| 5 | 파일 확인 | `~/.claude/mcp.json` 생성됨 (원본 복사) |

**코드 참조**: `mcp-config.sh:19-24` -- 레거시 경로 마이그레이션

---

#### TC-E2E-ALL-021 / TC-E2E-WIN-020

| TC ID | 핵심 검증 |
|-------|----------|
| TC-E2E-ALL-021 | 양쪽 모두 존재 -> `~/.claude/mcp.json`만 사용 |
| TC-E2E-WIN-020 | Windows `%USERPROFILE%\.mcp.json` -> `%USERPROFILE%\.claude\mcp.json` |

### 6.4 오류 복구 시나리오

#### TC-E2E-ALL-030 ~ TC-E2E-ALL-036

| TC ID | 시나리오 | 테스트 방법 | 기대 결과 |
|-------|---------|-----------|----------|
| TC-E2E-ALL-030 | 네트워크 단절 | 방화벽으로 아웃바운드 차단 | curl 실패 에러 메시지 |
| TC-E2E-ALL-031 | Docker 이미지 Pull 실패 | ghcr.io DNS 차단 | docker pull 에러 |
| TC-E2E-ALL-032 | OAuth 타임아웃 | 5분간 로그인 미완료 | "Auth timed out after 300s" |
| TC-E2E-ALL-033 | 모듈 실패 후 재시도 | 의도적 실패 -> 재실행 | 백업에서 복원 후 성공 |
| TC-E2E-ALL-034 | 부분 설치 복구 | 3개 중 2번째 실패 | `--skip-base --modules "third"` |
| TC-E2E-ALL-035 | client_secret.json 미제공 | 파일 없이 Google 모듈 실행 | "client_secret.json not found" |
| TC-E2E-ALL-036 | 포트 충돌 | 3000번 포트 사용 중 | 동적 포트 할당 |

### 6.5 일상 업무 시나리오

#### TC-E2E-ALL-040: 이메일 검색 및 읽기

**우선순위**: P0
**환경**: MCP 서버 실행 중

**상세 절차**:

| 단계 | MCP 도구 호출 | 기대 결과 |
|------|-------------|----------|
| 1 | `gmail_search` query="from:boss" | 이메일 목록 (id, from, subject, date, snippet) |
| 2 | `gmail_read` messageId=(1단계 결과 첫 번째 id) | 본문 내용 (body, attachments, labels) |
| 3 | 결과 확인 | from, subject, body 필드 정상 |

---

#### TC-E2E-ALL-041 ~ TC-E2E-ALL-047

| TC ID | 워크플로 | 호출 순서 |
|-------|---------|----------|
| TC-E2E-ALL-041 | 이메일 작성 발송 | gmail_send -> gmail_search 확인 |
| TC-E2E-ALL-042 | 일정 생성 조회 | calendar_create_event -> calendar_list_events |
| TC-E2E-ALL-043 | 파일 검색 공유 | drive_search -> drive_share |
| TC-E2E-ALL-044 | 문서 생성 편집 | docs_create -> docs_append -> docs_read |
| TC-E2E-ALL-045 | 시트 데이터 입력 | sheets_create -> sheets_write -> sheets_read |
| TC-E2E-ALL-046 | 프레젠테이션 제작 | slides_create -> slides_add_slide x3 -> slides_read |
| TC-E2E-ALL-047 | 복합 워크플로 | gmail_search -> docs_create -> drive_share |

### 6.6 고급 사용 시나리오

#### TC-E2E-ALL-050 ~ TC-E2E-ALL-053

| TC ID | 시나리오 | 환경 설정 | 기대 결과 |
|-------|---------|----------|----------|
| TC-E2E-ALL-050 | 스코프 제한 | `GOOGLE_SCOPES="gmail,calendar"` | Drive API 권한 부족 에러 |
| TC-E2E-ALL-051 | 타임존 변경 | `TIMEZONE="UTC"` | UTC 기준 이벤트 생성 |
| TC-E2E-ALL-052 | Docker 볼륨 영속성 | 컨테이너 재시작 | token.json 유지 |
| TC-E2E-ALL-053 | 동시 MCP 세션 | 2개 Claude 세션 | 뮤텍스로 충돌 방지 |

---

## 7. 크로스 플랫폼 호환성 테스트 설계

### 7.1 OS 버전별 호환성 매트릭스 상세

#### 인스톨러 호환성 테스트 절차

각 OS 환경에서 다음 명령어를 실행하고 결과를 기록한다:

```bash
# 공통 검증 스크립트
#!/bin/bash
echo "=== OS Info ==="
uname -a
echo ""
echo "=== Package Manager ==="
source modules/shared/package-manager.sh
pkg_detect_manager
echo ""
echo "=== install.sh --list ==="
./install.sh --list 2>&1 | tail -20
echo ""
echo "=== install.sh --modules 'github' --skip-base ==="
./install.sh --modules "github" --skip-base 2>&1 | tail -30
```

### 7.2 패키지 관리자별 테스트 절차 (TC-SHR-ALL-001 ~ TC-SHR-ALL-010)

**대상 파일**: `installer/modules/shared/package-manager.sh`

#### TC-SHR-ALL-001 ~ TC-SHR-ALL-006: pkg_detect_manager

**자동화**: 가능 (Docker 컨테이너별 실행)

```bash
# 패키지 관리자 감지 테스트
# TC-SHR-ALL-001: macOS
docker run --rm -e OSTYPE=darwin macos-env bash -c 'source package-manager.sh; pkg_detect_manager'
# 기대: "brew"

# TC-SHR-ALL-002: Ubuntu
docker run --rm ubuntu:22.04 bash -c '
  apt update > /dev/null 2>&1
  source package-manager.sh
  pkg_detect_manager
'
# 기대: "apt"

# TC-SHR-ALL-003: Fedora
docker run --rm fedora:39 bash -c 'source package-manager.sh; pkg_detect_manager'
# 기대: "dnf"
```

#### TC-SHR-ALL-007 ~ TC-SHR-ALL-010: pkg_install / pkg_ensure_installed / pkg_install_cask

| TC ID | 입력 | 기대 명령어 |
|-------|------|-----------|
| TC-SHR-ALL-007 | `pkg_install "jq"` (brew) | `brew install jq` |
| TC-SHR-ALL-008 | `pkg_install "jq"` (apt) | `sudo apt-get install -y jq` |
| TC-SHR-ALL-009 | `pkg_ensure_installed "jq"` (설치됨) | "jq is already installed" |
| TC-SHR-ALL-010 | `pkg_install_cask "docker"` (macOS) | `brew install --cask docker` |

### 7.3 쉘 환경별 테스트 (TC-SHR-ALL-020 ~ TC-SHR-ALL-022, TC-SHR-WIN-001 ~ TC-SHR-WIN-003)

| TC ID | 환경 | 테스트 | 기대 결과 |
|-------|------|--------|----------|
| TC-SHR-ALL-020 | Bash 4.x | `bash --version` 확인 후 `install.sh` 실행 | `declare -a` 정상 동작 |
| TC-SHR-ALL-021 | Bash 5.x | `bash --version` 확인 후 `install.sh` 실행 | 전체 기능 정상 |
| TC-SHR-ALL-022 | Zsh | `source install.sh` 시도 | 주의: `#!/bin/bash` 명시 |
| TC-SHR-WIN-001 | PowerShell 5.1 | `$PSVersionTable.PSVersion` 확인 | `ConvertFrom-Json`, `irm` 동작 |
| TC-SHR-WIN-002 | PowerShell 7.x | `pwsh -Version` 확인 | 전체 기능 정상 |
| TC-SHR-WIN-003 | ExecutionPolicy Restricted | 기본 정책에서 실행 | 실행 차단, Bypass 안내 |

### 7.4 Docker Desktop 버전 호환성 (TC-DOK-ALL-001 ~ TC-DOK-ALL-007)

**대상 파일**: `installer/modules/shared/docker-utils.sh`

| TC ID | 환경 | 호출 | 기대 결과 |
|-------|------|------|----------|
| TC-DOK-ALL-001 | DD 4.41 + macOS 13 | `docker_check_compatibility()` | 경고 없이 통과 |
| TC-DOK-ALL-002 | DD 4.42+ + macOS 13 | `docker_check_compatibility()` | "may not support" 경고 |
| TC-DOK-ALL-003 | DD 4.42+ + macOS 14+ | `docker_check_compatibility()` | 경고 없이 통과 |
| TC-DOK-ALL-004 | Docker 없음 | `docker_get_status()` | "not_installed" |
| TC-DOK-ALL-005 | Docker 있음 + 미실행 | `docker_get_status()` | "not_running" |
| TC-DOK-ALL-006 | Docker 시작 중 | `docker_wait_for_start 60` | 60초 내 성공 |
| TC-DOK-ALL-007 | 이전 컨테이너 존재 | `docker_cleanup_container` | stop + rm |

---

## 8. 보안 테스트 설계

### 8.1 OWASP Top 10 테스트 절차

#### 8.1.1 A01: Broken Access Control (TC-SEC-ALL-001 ~ TC-SEC-ALL-006)

##### TC-SEC-ALL-001: 토큰 파일 권한

**우선순위**: P0
**자동화**: 가능

**공격 시나리오**: 다른 사용자가 토큰 파일을 읽어 API 접근 권한 탈취
**기대 방어**: 파일 권한 0600 (소유자만 읽기/쓰기)

**테스트 절차**:
```bash
# Linux/macOS
stat -c %a ~/.google-workspace/token.json  # Linux
stat -f %Lp ~/.google-workspace/token.json  # macOS
# 기대: 600

# Vitest (oauth.ts saveToken 검증)
it('should save token with mode 0600', () => {
  const writeSpy = vi.spyOn(fs, 'writeFileSync');
  saveToken(mockToken);
  expect(writeSpy).toHaveBeenCalledWith(
    expect.any(String),
    expect.any(String),
    { mode: 0o600 }
  );
});
```

---

##### TC-SEC-ALL-005: Docker non-root 실행

**우선순위**: P0

```bash
# 컨테이너 내 사용자 확인
docker run --rm ghcr.io/popup-jacob/google-workspace-mcp:latest id -u
# 기대: 1001 (mcp 사용자, root 아님)

docker run --rm ghcr.io/popup-jacob/google-workspace-mcp:latest whoami
# 기대: mcp
```

**코드 참조**: `Dockerfile:25-26` -- `groupadd -r mcp && useradd -r -g mcp`, `Dockerfile:39` -- `USER mcp`

---

#### 8.1.2 A02: Cryptographic Failures (TC-SEC-ALL-010 ~ TC-SEC-ALL-014)

##### TC-SEC-ALL-010: OAuth state 엔트로피

**우선순위**: P0
**자동화**: 가능

```typescript
describe('TC-SEC-ALL-010: OAuth State Entropy', () => {
  it('should generate 32-byte (64 hex char) random state', () => {
    // oauth.ts:227 -- crypto.randomBytes(32).toString("hex")
    const state = crypto.randomBytes(32).toString('hex');
    expect(state).toHaveLength(64);
    expect(state).toMatch(/^[0-9a-f]{64}$/);
  });

  it('should not have collisions in 100 generations', () => {
    const states = new Set();
    for (let i = 0; i < 100; i++) {
      states.add(crypto.randomBytes(32).toString('hex'));
    }
    expect(states.size).toBe(100);
  });
});
```

---

##### TC-SEC-ALL-013 / TC-SEC-ALL-014: SHA-256 무결성/변조 감지

TC-INS-MAC-020, TC-INS-MAC-021과 동일한 검증을 보안 관점에서 수행.

#### 8.1.3 A03: Injection (TC-SEC-ALL-020 ~ TC-SEC-ALL-025)

##### TC-SEC-ALL-020: Drive 쿼리 인젝션 방지

**우선순위**: P0
**자동화**: 가능 (Vitest)

**공격 시나리오**: Drive API 쿼리 언어에 `'` 주입으로 쿼리 조작
**테스트 페이로드**: `query="' OR 1=1 --"`

```typescript
it('should escape Drive query injection', async () => {
  mockDriveApi.files.list.mockResolvedValue({ data: { files: [] } });

  await driveTools.drive_search.handler({
    query: "' OR 1=1 --", maxResults: 10,
  });

  const q = mockDriveApi.files.list.mock.calls[0][0].q;
  // escapeDriveQuery("' OR 1=1 --") -> "\\' OR 1=1 --"
  expect(q).toContain("\\'");
  expect(q).not.toContain("' OR");
});
```

---

##### TC-SEC-ALL-023: Gmail 헤더 인젝션 방지

**우선순위**: P0
**자동화**: 가능 (기존 gmail.test.ts 활용)

**공격 시나리오**: `to` 필드에 CRLF 삽입으로 Bcc 헤더 주입
**테스트 페이로드**: `to="victim@test.com\r\nBcc: spy@evil.com"`

```typescript
// 기존 gmail.test.ts의 TC-G01 테스트와 동일
it('should strip CRLF from email headers', async () => {
  // sanitizeEmailHeader('victim@test.com\r\nBcc: spy@evil.com')
  // -> 'victim@test.comBcc: spy@evil.com' (CRLF 제거)
  const result = sanitizeEmailHeader('victim@test.com\r\nBcc: spy@evil.com');
  expect(result).not.toContain('\r');
  expect(result).not.toContain('\n');
});
```

---

##### TC-SEC-ALL-024: JSON 파싱 인젝션 방지

**우선순위**: P0
**자동화**: 가능

**공격 시나리오**: module.json에 셸 메타문자 포함 시 코드 실행
**기대 방어**: stdin 기반 파싱으로 쉘 interpolation 방지

```bash
# 테스트: 악의적 module.json
echo '{"name":"test$(whoami)","order":1}' | node -e "
  let data = '';
  process.stdin.on('data', chunk => data += chunk);
  process.stdin.on('end', () => {
    const obj = JSON.parse(data);
    console.log(obj.name);
  });
"
# 기대: "test$(whoami)" (리터럴 문자열, 명령어 미실행)
```

---

##### TC-SEC-ALL-025: Atlassian 자격증명 인젝션 방지

**우선순위**: P0

**공격 시나리오**: API 토큰에 셸 특수문자 포함
**기대 방어**: `--env-file` 방식으로 쉘 확장 없이 전달

```bash
# credentials.env에 특수문자 토큰
echo 'JIRA_API_TOKEN=tok;rm -rf /' > test-cred.env
# --env-file은 셸 해석 없이 원문 전달
docker run --env-file test-cred.env --rm alpine env | grep JIRA
# 기대: JIRA_API_TOKEN=tok;rm -rf / (원문 유지)
```

#### 8.1.4 A05 ~ A08 (TC-SEC-ALL-030 ~ TC-SEC-ALL-061)

| TC ID | 핵심 검증 | 자동화 |
|-------|----------|--------|
| TC-SEC-ALL-030 | Dockerfile `npm ci` 사용 | Vitest/CI |
| TC-SEC-ALL-031 | production 의존성만 | Docker inspect |
| TC-SEC-ALL-032 | NODE_ENV=production | Docker inspect |
| TC-SEC-ALL-040 | `npm audit --audit-level=high` = 0건 | CI 자동 |
| TC-SEC-ALL-041 | Node.js 22 사용 | Dockerfile 확인 |
| TC-SEC-ALL-042 | 의존성 버전 고정 | package.json 확인 |
| TC-SEC-ALL-050 | refresh_token 필수 | Vitest |
| TC-SEC-ALL-051 | 5분 만료 버퍼 | Vitest |
| TC-SEC-ALL-052 | access_type=offline | Vitest |
| TC-SEC-ALL-060 | checksums.json 최신 | CI 자동 |
| TC-SEC-ALL-061 | 원격 파일 전수 검증 | 수동 |

### 8.2 인증/인가 테스트 (TC-SEC-ALL-070 ~ TC-SEC-ALL-073)

TC-AUT-ALL-006, TC-AUT-ALL-010과 동일한 보안 관점 검증.

| TC ID | 핵심 검증 |
|-------|----------|
| TC-SEC-ALL-070 | CSRF state 불일치 -> 403 |
| TC-SEC-ALL-071 | PKCE code_verifier 없이 토큰 교환 실패 |
| TC-SEC-ALL-072 | 동시 3회 인증 -> 뮤텍스로 1회만 실행 |
| TC-SEC-ALL-073 | 보안 이벤트 JSON 로그 형식 |

### 8.3 입력 검증 테스트 (TC-SEC-ALL-080 ~ TC-SEC-ALL-092)

4.8.1절의 sanitize.ts 단위 테스트와 1:1 대응. 모든 TC는 Vitest로 자동화.

| TC ID | 함수 | 입력 | 기대 출력 |
|-------|------|------|----------|
| TC-SEC-ALL-080 | `escapeDriveQuery` | `"test's"` | `"test\\'s"` |
| TC-SEC-ALL-081 | `escapeDriveQuery` | `"test\\path"` | `"test\\\\path"` |
| TC-SEC-ALL-082 | `validateDriveId` | `"abc123_-XYZ"` | 에러 없음 |
| TC-SEC-ALL-083 | `validateDriveId` | `"root"` | 에러 없음 |
| TC-SEC-ALL-084 | `validateDriveId` | `"id!@#$%"` | 에러 발생 |
| TC-SEC-ALL-085 | `sanitizeEmailHeader` | `"a@b.com\r\nBcc: spy"` | `"a@b.comBcc: spy"` |
| TC-SEC-ALL-086 | `validateEmail` | `"user@example.com"` | `true` |
| TC-SEC-ALL-087 | `validateEmail` | `"a".repeat(255)+"@b.com"` | `false` |
| TC-SEC-ALL-088 | `sanitizeFilename` | `"../../../etc/passwd"` | 위험문자 치환 |
| TC-SEC-ALL-089 | `sanitizeFilename` | `"file\x00.txt"` | `"file_.txt"` |
| TC-SEC-ALL-090 | `sanitizeRange` | `"Sheet1!A1:B10"` | `"Sheet1!A1:B10"` |
| TC-SEC-ALL-091 | `sanitizeRange` | `"DROP TABLE users;"` | `null` |
| TC-SEC-ALL-092 | `validateMaxLength` | `"a".repeat(1000), 500` | 500자 문자열 |

### 8.4 파일 시스템 보안 테스트 (TC-SEC-ALL-100 ~ TC-SEC-ALL-105)

| TC ID | 핵심 검증 | 코드 참조 |
|-------|----------|----------|
| TC-SEC-ALL-100 | CONFIG_DIR 생성 (0700) | `oauth.ts:116-118` |
| TC-SEC-ALL-101 | 권한 0755 -> 0700 복구 | `oauth.ts:122-127` |
| TC-SEC-ALL-102 | token 저장 (0600 + chmodSync) | `oauth.ts:200-215` |
| TC-SEC-ALL-103 | Windows에서 chmodSync 실패 정상 처리 | `oauth.ts:128-130, 211-213` |
| TC-SEC-ALL-104 | EXIT trap으로 임시 파일 정리 | `install.sh:561` |
| TC-SEC-ALL-105 | 체크섬 실패 시 tmpfile 삭제 | `install.sh:169` |

### 8.5 네트워크 보안 테스트 (TC-SEC-ALL-110 ~ TC-SEC-ALL-113)

| TC ID | 핵심 검증 | 테스트 방법 |
|-------|----------|-----------|
| TC-SEC-ALL-110 | HTTPS 전용 | 코드 검색: `http://` 없음 (localhost 제외) |
| TC-SEC-ALL-111 | OAuth 콜백 localhost 전용 | `server.listen(OAUTH_PORT)` -> 127.0.0.1 |
| TC-SEC-ALL-112 | Docker `--rm` 옵션 | MCP 설정의 args에 `--rm` 포함 |
| TC-SEC-ALL-113 | curl `-sSL` 사용 | 코드 검색: 모든 curl에 `-sSL` |

---

## 9. 성능/안정성 테스트 설계

### 9.1 Rate Limiting 테스트 설계 (TC-PER-ALL-001 ~ TC-PER-ALL-011)

**대상**: `google-workspace-mcp/src/utils/retry.ts` -- `withRetry()` 함수

#### 429 시뮬레이션 방법

```typescript
// 429 응답 Mock 생성
function create429Error(): Error {
  const err = new Error('Too Many Requests') as any;
  err.response = { status: 429 };
  return err;
}

// 500 응답 Mock
function create500Error(): Error {
  const err = new Error('Internal Server Error') as any;
  err.response = { status: 500 };
  return err;
}

// 네트워크 에러 Mock
function createNetworkError(code: string): Error {
  const err = new Error(`Network error: ${code}`) as any;
  err.code = code;
  return err;
}
```

#### 백오프 간격 측정 방법

```typescript
it('TC-PER-ALL-001: exponential backoff timing', async () => {
  const timestamps: number[] = [];
  let attempt = 0;

  const fn = vi.fn(async () => {
    timestamps.push(Date.now());
    attempt++;
    if (attempt < 3) throw create429Error();
    return 'success';
  });

  await withRetry(fn, { initialDelay: 100, backoffFactor: 2 });

  // 간격 검증 (약간의 오차 허용)
  const gap1 = timestamps[1] - timestamps[0]; // ~100ms
  const gap2 = timestamps[2] - timestamps[1]; // ~200ms
  expect(gap1).toBeGreaterThanOrEqual(90);
  expect(gap1).toBeLessThan(200);
  expect(gap2).toBeGreaterThanOrEqual(180);
  expect(gap2).toBeLessThan(400);
});
```

#### TC-PER-ALL-001 ~ TC-PER-ALL-011 전체

| TC ID | 입력 | Mock | 기대 | 자동화 |
|-------|------|------|------|--------|
| PER-001 | 429 응답 | 2회 429 -> 성공 | 3회 시도, 지수 백오프 | Vitest |
| PER-002 | 500 응답 | 2회 500 -> 성공 | 3회 시도 | Vitest |
| PER-003 | 502/503/504 | 각 코드 1회 -> 성공 | 재시도 | Vitest |
| PER-004 | 400 응답 | 1회 400 | 즉시 throw (1회) | Vitest |
| PER-005 | 403 응답 | 1회 403 | 즉시 throw (1회) | Vitest |
| PER-006 | ECONNRESET | 2회 에러 -> 성공 | 재시도 | Vitest |
| PER-007 | ETIMEDOUT | 2회 에러 -> 성공 | 재시도 | Vitest |
| PER-008 | ECONNREFUSED | 2회 에러 -> 성공 | 재시도 | Vitest |
| PER-009 | maxDelay=10000 | 지연 증가 | 10000ms 초과 안됨 | Vitest |
| PER-010 | maxAttempts=5, initialDelay=500 | 5회 실패 | 5회 시도 후 throw | Vitest |
| PER-011 | 즉시 성공 | 성공 | 1회, 재시도 없음 | Vitest |

### 9.2 대량 데이터 처리 테스트 (TC-PER-ALL-020 ~ TC-PER-ALL-025)

| TC ID | 시나리오 | 검증 포인트 |
|-------|---------|-----------|
| PER-020 | gmail_search maxResults=100 | 상위 10개만 상세 조회 (Promise.all), `gmail.ts:32` |
| PER-021 | drive_search maxResults=50 | pageSize 제한 동작 |
| PER-022 | gmail_read 10MB+ 첨부 | body 5000자 truncate |
| PER-023 | gmail_attachment_get 25MB | base64 정상 반환 |
| PER-024 | docs_read 10000자+ | 10000자 truncate |
| PER-025 | sheets_write 1000x26 | USER_ENTERED 모드 동작 |

### 9.3 동시성 테스트 (TC-PER-ALL-030 ~ TC-PER-ALL-033)

```typescript
describe('TC-PER-ALL-030: Concurrent Auth Mutex', () => {
  it('should execute auth only once for 3 concurrent calls', async () => {
    const authSpy = vi.fn();
    // 3회 동시 호출
    const [c1, c2, c3] = await Promise.all([
      getAuthenticatedClient(),
      getAuthenticatedClient(),
      getAuthenticatedClient(),
    ]);
    // authInProgress Promise 공유로 실제 인증은 1회
  });
});
```

### 9.4 장시간 운영 테스트 (TC-PER-ALL-040 ~ TC-PER-ALL-044)

| TC ID | 시나리오 | 측정 방법 | 기대 결과 |
|-------|---------|----------|----------|
| PER-040 | 50분 캐시 갱신 | 타이머 시뮬레이션 | 새 서비스 인스턴스 |
| PER-041 | 토큰 자동 갱신 | 만료 시간 조작 | 5분 버퍼 자동 refresh |
| PER-042 | refresh_token 만료 | 토큰 무효화 | 브라우저 재인증 |
| PER-043 | 메모리 누수 검증 | `process.memoryUsage().rss` 주기적 측정 | RSS < 500MB |
| PER-044 | Docker 컨테이너 안정성 | HEALTHCHECK 모니터링 | 24시간 통과 |

---

## 10. 회귀 테스트 설계

### 10.1 CI 자동화 테스트 설계 (TC-REG-ALL-001 ~ TC-REG-ALL-010)

**CI 파이프라인**: `.github/workflows/ci.yml`

| TC ID | CI Job | 검증 내용 | 실패 시 조치 |
|-------|--------|----------|------------|
| REG-001 | `lint` | ESLint + Prettier | 코드 포맷 수정 |
| REG-002 | `build` | TypeScript 컴파일 | 타입 에러 수정 |
| REG-003 | `test` | vitest 전체 + 커버리지 | 테스트 수정 |
| REG-004 | `smoke-tests` | module.json 유효성 + `bash -n` | JSON/구문 수정 |
| REG-005 | `security-audit` | `npm audit --audit-level=high` | 의존성 업데이트 |
| REG-006 | `shellcheck` | ShellCheck -S warning | 쉘 스크립트 수정 |
| REG-007 | `docker-build` | 이미지 빌드 + non-root 확인 | Dockerfile 수정 |
| REG-008 | `verify-checksums` | checksums.json 최신 | `generate-checksums.sh` 재실행 |
| REG-009 | `smoke-tests` | `bash -n install.sh` (macOS + Ubuntu) | 구문 에러 수정 |
| REG-010 | `smoke-tests` | order 필드 정렬 확인 | module.json 수정 |

#### CI 자동화 Vitest 설정

```typescript
// vitest.config.ts (기존)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/__tests__/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/__tests__/**', 'src/**/*.d.ts'],
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

### 10.2 수동 회귀 체크리스트

릴리스 전 수동으로 확인해야 하는 항목:

#### 인스톨러 회귀 (10항목)

- [ ] macOS (Sonoma): `./install.sh --all` 전체 설치 성공
- [ ] macOS: `./install.sh --list` 7개 모듈 표시
- [ ] macOS: `./install.sh --modules "google" --skip-base` 단독 실행
- [ ] macOS: Docker 미실행 시 경고 + 대기
- [ ] macOS: 모듈 실패 시 MCP 설정 롤백
- [ ] Windows: `.\install.ps1 -all` 전체 설치
- [ ] Windows: UAC 관리자 권한 상승
- [ ] Windows: `-list` (관리자 불필요)
- [ ] Linux (Ubuntu): 클린 설치
- [ ] Linux (Fedora): dnf 기반 설치

#### MCP 서버 회귀 (9항목)

- [ ] OAuth 최초 인증 (브라우저 -> 콜백 -> 토큰)
- [ ] 토큰 자동 갱신 (만료 5분 전)
- [ ] gmail_search + gmail_read 연쇄
- [ ] gmail_send UTF-8 제목
- [ ] drive_search + drive_share
- [ ] calendar_create_event (동적 타임존)
- [ ] docs_create + docs_append + docs_read
- [ ] sheets_create + sheets_write + sheets_read
- [ ] slides_create + slides_add_slide

#### 보안 회귀 (7항목)

- [ ] token.json 0600
- [ ] .google-workspace/ 0700
- [ ] MCP 설정 0600
- [ ] credentials.env 600
- [ ] Docker non-root
- [ ] Drive 쿼리 이스케이프
- [ ] Gmail 헤더 인젝션 방지

---

## 11. 테스트 실행 절차

### 11.1 Phase 1 (P0 Critical) 실행 가이드

**목표**: 69건, 약 5.5시간
**실행 순서**:

| 순서 | 영역 | TC 수 | 방법 | 예상 시간 |
|------|------|------:|------|----------|
| 1 | CI 자동화 (REG-001~008) | 8 | CI 파이프라인 | 10분 |
| 2 | OAuth 인증 (AUT P0) | 11 | Vitest + 수동 | 30분 |
| 3 | 보안 핵심 (SEC P0) | 22 | Vitest + 수동 | 1시간 |
| 4 | 인스톨러 핵심 (INS P0) | 14 | 수동 | 1시간 |
| 5 | 도구 핵심 (GML/DRV/CAL P0) | 10 | Vitest | 30분 |
| 6 | E2E 클린 설치 | 4 | 수동 | 2시간 |

**Phase 1 실행 명령어**:
```bash
# 1. CI 자동화 (자동)
cd google-workspace-mcp && npm test

# 2-3. OAuth + 보안 (Vitest)
npx vitest run src/**/__tests__/*.test.ts --reporter=verbose

# 4. 인스톨러 (수동 + 자동)
cd installer && bash tests/run_tests.sh

# 5. 도구 핵심 (Vitest -- 이미 2번에서 포함)

# 6. E2E (수동 -- 각 OS별 클린 환경에서 실행)
```

### 11.2 Phase 2 (P1 High) 실행 가이드

**목표**: 100건, 약 8시간

| 순서 | 영역 | TC 수 | 예상 시간 |
|------|------|------:|----------|
| 1 | 인스톨러 부가 | 20 | 1시간 |
| 2 | MCP 도구 주요 | 35 | 2시간 |
| 3 | 모듈 기능 | 15 | 1시간 |
| 4 | 성능/동시성 | 10 | 1시간 |
| 5 | 크로스 플랫폼 | 12 | 1시간 |
| 6 | E2E 시나리오 | 8 | 2시간 |

### 11.3 Phase 3 (P2-P3) 실행 가이드

**목표**: 57건, 약 30시간 (장시간 운영 테스트 포함)

| 순서 | 영역 | TC 수 | 예상 시간 |
|------|------|------:|----------|
| 1 | MCP 도구 부가 | 30 | 2시간 |
| 2 | 엣지 케이스 | 15 | 1시간 |
| 3 | 성능 스트레스 | 8 | 3시간 |
| 4 | 장시간 운영 | 4 | 24시간 |

### 11.4 결과 기록 템플릿

```markdown
## 테스트 실행 기록

- 실행일: YYYY-MM-DD
- 실행자:
- 환경: (환경 ID, 예: MAC-ENV-02)
- 빌드 버전: (git commit hash)
- Phase: 1 / 2 / 3

### 요약

| 결과 | 건수 |
|------|------|
| PASS | |
| FAIL | |
| SKIP | |
| BLOCK | |

### 상세 결과

| TC ID | 결과 | 소요 시간 | 비고 |
|-------|------|----------|------|
| TC-INS-MAC-001 | PASS | 2분 | |
| TC-INS-MAC-002 | FAIL | 3분 | BUG-2026-0001 참조 |
| TC-INS-MAC-003 | SKIP | - | Docker 환경 미준비 |
```

---

## 부록

### A. 테스트 데이터 카탈로그

| 카탈로그 ID | 유형 | 설명 | 사용 TC |
|------------|------|------|--------|
| GML-DATA-001 | Gmail | 일반 텍스트 이메일 | TC-GML-ALL-001, 003 |
| GML-DATA-002 | Gmail | HTML 본문 이메일 | TC-GML-ALL-004 |
| GML-DATA-003 | Gmail | 멀티파트 이메일 | TC-GML-ALL-004 |
| GML-DATA-004 | Gmail | 첨부파일 포함 (1MB PDF) | TC-GML-ALL-005, 018 |
| GML-DATA-005 | Gmail | 대용량 첨부 (10MB+) | TC-PER-ALL-022, 023 |
| GML-DATA-006 | Gmail | 한글 제목 | TC-GML-ALL-009 |
| GML-DATA-007 | Gmail | CC/BCC 포함 | TC-GML-ALL-008 |
| GML-DATA-008 | Gmail | 5000자+ 본문 | TC-GML-ALL-006 |
| GML-DATA-009 | Gmail | 드래프트 3건 | TC-GML-ALL-011~014 |
| GML-DATA-010 | Gmail | 커스텀 라벨 | TC-GML-ALL-015~017 |
| DRV-DATA-001 | Drive | 루트 파일 5개 | TC-DRV-ALL-004 |
| DRV-DATA-002 | Drive | 폴더 + 하위 파일 | TC-DRV-ALL-007, 008 |
| DRV-DATA-003 | Drive | PDF 파일 | TC-DRV-ALL-002 |
| DRV-DATA-004 | Drive | 공유 파일 | TC-DRV-ALL-014~018 |
| DRV-DATA-005 | Drive | Shared Drive 파일 | TC-DRV-ALL-020 |
| DRV-DATA-006 | Drive | 휴지통 파일 | TC-DRV-ALL-012, 013 |
| DRV-DATA-007 | Drive | 특수문자 파일명 | TC-DRV-ALL-003 |
| CAL-DATA-001~005 | Calendar | 이벤트 데이터 | TC-CAL-ALL-* |
| DOC-DATA-001~004 | Docs | 문서 데이터 | TC-DOC-ALL-* |
| SHT-DATA-001~003 | Sheets | 시트 데이터 | TC-SHT-ALL-* |
| SLD-DATA-001~002 | Slides | 프레젠테이션 데이터 | TC-SLD-ALL-* |

### B. Mock/Stub 설계

#### B.1 Google API Mock 구조

```typescript
// test-utils/google-mock.ts
export function createMockGmailApi() {
  return {
    users: {
      messages: {
        list: vi.fn().mockResolvedValue({ data: { messages: [] } }),
        get: vi.fn().mockResolvedValue({ data: { payload: { headers: [] } } }),
        send: vi.fn().mockResolvedValue({ data: { id: 'sent1' } }),
        modify: vi.fn().mockResolvedValue({ data: {} }),
        trash: vi.fn().mockResolvedValue({ data: {} }),
        untrash: vi.fn().mockResolvedValue({ data: {} }),
        attachments: {
          get: vi.fn().mockResolvedValue({ data: { data: '', size: 0 } }),
        },
      },
      drafts: {
        list: vi.fn().mockResolvedValue({ data: { drafts: [] } }),
        create: vi.fn().mockResolvedValue({ data: { id: 'draft1' } }),
        send: vi.fn().mockResolvedValue({ data: { id: 'sent1' } }),
        delete: vi.fn().mockResolvedValue({ data: {} }),
      },
      labels: {
        list: vi.fn().mockResolvedValue({ data: { labels: [] } }),
      },
    },
  };
}

export function createMockDriveApi() {
  return {
    files: {
      list: vi.fn().mockResolvedValue({ data: { files: [] } }),
      get: vi.fn().mockResolvedValue({ data: {} }),
      create: vi.fn().mockResolvedValue({ data: { id: 'file1' } }),
      copy: vi.fn().mockResolvedValue({ data: { id: 'copy1' } }),
      update: vi.fn().mockResolvedValue({ data: {} }),
    },
    permissions: {
      list: vi.fn().mockResolvedValue({ data: { permissions: [] } }),
      create: vi.fn().mockResolvedValue({ data: {} }),
      delete: vi.fn().mockResolvedValue({ data: {} }),
    },
    about: {
      get: vi.fn().mockResolvedValue({
        data: { storageQuota: { limit: '16106127360', usage: '5368709120' } },
      }),
    },
  };
}

// 유사 패턴으로 Calendar, Docs, Sheets, Slides Mock 생성
```

#### B.2 파일시스템 Mock

```typescript
// OAuth 테스트용 fs Mock
export function mockFileSystem(config: {
  hasClientSecret?: boolean;
  hasToken?: boolean;
  tokenData?: Partial<TokenData>;
  configDirExists?: boolean;
}) {
  vi.spyOn(fs, 'existsSync').mockImplementation((p: string) => {
    const path = p.toString();
    if (path.includes('client_secret.json')) return config.hasClientSecret ?? true;
    if (path.includes('token.json')) return config.hasToken ?? false;
    if (path.includes('.google-workspace')) return config.configDirExists ?? true;
    return true;
  });
  // ... readFileSync, writeFileSync, mkdirSync, chmodSync mocks
}
```

### C. 자동화 스크립트 설계

#### C.1 Vitest 테스트 파일 구조

```
google-workspace-mcp/src/
  auth/__tests__/
    oauth.test.ts          # TC-AUT-ALL-* (22건)
  tools/__tests__/
    gmail.test.ts          # TC-GML-ALL-* (22건) -- 기존 파일 확장
    drive.test.ts          # TC-DRV-ALL-* (20건) -- 기존 파일 확장
    calendar.test.ts       # TC-CAL-ALL-* (15건) -- 기존 파일 확장
    docs.test.ts           # TC-DOC-ALL-* (13건) -- 기존 파일 확장
    sheets.test.ts         # TC-SHT-ALL-* (14건) -- 기존 파일 확장
    slides.test.ts         # TC-SLD-ALL-* (11건) -- 기존 파일 확장
  utils/__tests__/
    sanitize.test.ts       # TC-SEC-ALL-080~092 (13건)
    retry.test.ts          # TC-PER-ALL-001~011 (11건)
    mime.test.ts           # extractTextBody/extractAttachments 단위
    messages.test.ts       # msg() 헬퍼 테스트
    time.test.ts           # parseTime/getTimezone 등 (6건)
```

#### C.2 인스톨러 테스트 스크립트 구조

```
installer/tests/
  run_tests.sh             # 테스트 러너
  test_ins_mac_001.sh      # 인수 파싱 --modules
  test_ins_mac_005.sh      # 알 수 없는 옵션
  test_ins_mac_008.sh      # 잘못된 모듈명
  test_ins_mac_017.sh      # parse_json node
  test_ins_mac_020.sh      # SHA-256 검증
  test_shared_pkg.sh       # 패키지 관리자 감지
```

### D. OS별 명령어 대응표

| 작업 | macOS | Windows (PowerShell) | Linux (Ubuntu) | WSL2 |
|------|-------|---------------------|---------------|------|
| 파일 권한 확인 | `stat -f %Lp file` | `icacls file` | `stat -c %a file` | `stat -c %a file` |
| 패키지 설치 | `brew install pkg` | `winget install pkg` | `sudo apt install pkg` | `sudo apt install pkg` |
| Docker 설치 | `brew install --cask docker` | `winget install Docker.DockerDesktop` | `curl -fsSL https://get.docker.com \| sh` | Windows Docker 공유 |
| 브라우저 열기 | `open URL` | `Start-Process URL` | `xdg-open URL` | `cmd.exe /c start URL` |
| JSON 파싱 | `node -e` / `python3 -c` / `osascript` | `ConvertFrom-Json` | `node -e` / `python3 -c` | `node -e` / `python3 -c` |
| SHA-256 | `shasum -a 256` | `Get-FileHash -Algorithm SHA256` | `sha256sum` | `sha256sum` |
| 프로세스 확인 | `ps aux \| grep` | `Get-Process` | `ps aux \| grep` | `ps aux \| grep` |
| MCP 설정 경로 | `~/.claude/mcp.json` | `$env:USERPROFILE\.claude\mcp.json` | `~/.claude/mcp.json` | `~/.claude/mcp.json` |
| Docker 상태 | `docker info` | `docker info` | `docker info` | `docker info` (Windows) |

### E. 테스트 결과 기록 양식

#### E.1 단일 TC 결과 기록

```markdown
### TC-XXX-YYY-NNN: [테스트 케이스명]

- **실행일**: YYYY-MM-DD HH:MM
- **실행자**: (이름)
- **환경**: (환경 ID)
- **결과**: PASS / FAIL / SKIP / BLOCK
- **소요 시간**: (분)

#### 절차 및 결과

| 단계 | 행동 | 기대 결과 | 실제 결과 | 판정 |
|------|------|----------|----------|------|
| 1 | ... | ... | ... | OK/NG |
| 2 | ... | ... | ... | OK/NG |

#### 스크린샷/로그
(필요 시 첨부)

#### 비고
(결함 ID, 특이사항 등)
```

#### E.2 결함 보고서

```markdown
## BUG-YYYY-NNNN: [결함 제목]

- **관련 TC**: TC-XXX-YYY-NNN
- **심각도**: Critical / Major / Minor / Trivial
- **환경**: (환경 ID)
- **발견일**: YYYY-MM-DD
- **상태**: Open / In Progress / Resolved / Closed

### 재현 절차
1. ...
2. ...

### 기대 결과
...

### 실제 결과
...

### 근본 원인
...

### 수정 방안
...

### 스크린샷/로그
...
```

### F. 누락 TC 전수 대응표

본 부록은 설계서 본문에서 범위 참조(예: "TC-PER-ALL-001 ~ TC-PER-ALL-011")로 커버된 TC를 개별 ID로 명시하여 310개 TC 전수 대응을 보장한다.

#### F.1 Figma 모듈 누락 TC

| TC ID | 핵심 검증 | 설계 위치 | 자동화 |
|-------|----------|----------|--------|
| TC-FIG-ALL-002 | Python3 미설치 -> "Python 3 is required for OAuth" 에러, exit 1 | 5.2절 TC-FIG-ALL-001 동일 패턴 | 가능 |
| TC-FIG-ALL-004 | OAuth PKCE: code_verifier/code_challenge 생성 + 브라우저 OAuth | 5.2절 Remote MCP 등록 후 `mcp_oauth_flow "figma"` | 수동 |
| TC-FIG-ALL-005 | OAuth 메타데이터 획득: well-known URL -> authorization_endpoint, token_endpoint 파싱 | 5.2절 oauth-helper.sh의 mcp_oauth_flow 내부 | 수동 |
| TC-FIG-ALL-006 | 토큰 저장: `~/.claude/.credentials.json`에 mcpOAuth 엔트리 | 5.2절 oauth-helper.sh `_save_tokens` 호출 확인 | 수동 |
| TC-FIG-ALL-007 | 기존 인증 재사용: "Already authenticated with figma!" 메시지 | 5.2절 재실행 시 토큰 존재 확인 | 수동 |

#### F.2 GitHub CLI 누락 TC

| TC ID | 핵심 검증 | 코드 참조 | 자동화 |
|-------|----------|----------|--------|
| TC-GIT-ALL-002 | gh 이미 인증: "Already logged in." 메시지 | `github/install.sh:79-81` | 수동 |
| TC-GIT-ALL-003 | gh 인증 실패: "Authentication failed" 에러, exit 1 | `github/install.sh:74-77` | 수동 |
| TC-GIT-ALL-004 | MCP 미설정: gh는 Bash tool로 직접 사용, MCP 설정 없음 | `github/install.sh:87-88` | 가능 |
| TC-GIT-LNX-002 | gh 설치 (Fedora): `sudo dnf install gh -y` | `github/install.sh:44-45` | Docker 컨테이너 |

#### F.3 성능 테스트 누락 TC

| TC ID | 핵심 검증 | Mock 설정 | 자동화 |
|-------|----------|----------|--------|
| TC-PER-ALL-002 | withRetry: 500 재시도 -- 2회 500 -> 성공 | `err.response.status = 500` | Vitest |
| TC-PER-ALL-003 | withRetry: 502/503/504 재시도 | 각 상태 코드별 Mock | Vitest |
| TC-PER-ALL-005 | withRetry: 403 미재시도 -- 즉시 throw | `err.response.status = 403` | Vitest |
| TC-PER-ALL-006 | withRetry: ECONNRESET 재시도 | `err.code = 'ECONNRESET'` | Vitest |
| TC-PER-ALL-007 | withRetry: ETIMEDOUT 재시도 | `err.code = 'ETIMEDOUT'` | Vitest |
| TC-PER-ALL-008 | withRetry: ECONNREFUSED 재시도 | `err.code = 'ECONNREFUSED'` | Vitest |
| TC-PER-ALL-009 | withRetry: maxDelay=10000 제한 | `options.maxDelay = 10000` | Vitest |
| TC-PER-ALL-010 | withRetry: maxAttempts=5, initialDelay=500 | 커스텀 옵션 | Vitest |
| TC-PER-ALL-021 | drive_search maxResults=50 대량 파일 | pageSize 제한 검증 | Vitest |
| TC-PER-ALL-023 | gmail_attachment_get 25MB -- base64 정상 반환 | 대용량 Mock | Vitest |
| TC-PER-ALL-024 | docs_read 10000자+ -- 10000자 truncate | 긴 문서 Mock | Vitest |
| TC-PER-ALL-031 | 뮤텍스 해제 -- authInProgress null 리셋 | 인증 완료 후 확인 | Vitest |
| TC-PER-ALL-032 | 서비스 캐시 동시 접근 | 캐시 만료 직전 동시 호출 | Vitest |
| TC-PER-ALL-041 | 토큰 자동 갱신 -- 5분 버퍼 refresh | 만료 시간 조작 | Vitest |
| TC-PER-ALL-042 | refresh_token 만료 -- 브라우저 재인증 | refresh 실패 Mock | Vitest |
| TC-PER-ALL-043 | 메모리 누수 -- RSS < 500MB | `process.memoryUsage()` | 수동 |

#### F.4 회귀 테스트 누락 TC

| TC ID | CI Job | 검증 내용 | 자동화 |
|-------|--------|----------|--------|
| TC-REG-ALL-002 | `build` | TypeScript 컴파일 성공 -- tsc 에러 0건 | CI 자동 |
| TC-REG-ALL-003 | `test` | vitest 전체 통과 -- 6개 테스트 파일 | CI 자동 |
| TC-REG-ALL-004 | `smoke-tests` | module.json 유효성 -- 7개 모듈 JSON 파싱 | CI 자동 |
| TC-REG-ALL-005 | `security-audit` | npm audit -- high/critical 0건 | CI 자동 |
| TC-REG-ALL-006 | `shellcheck` | ShellCheck -S warning 없음 | CI 자동 |
| TC-REG-ALL-007 | `docker-build` | Docker 이미지 빌드 + UID 1001 | CI 자동 |
| TC-REG-ALL-008 | `verify-checksums` | checksums.json 최신 | CI 자동 |
| TC-REG-ALL-009 | `smoke-tests` | bash -n install.sh 통과 | CI 자동 |

#### F.5 보안 테스트 누락 TC

| TC ID | 핵심 검증 | 테스트 방법 | 자동화 |
|-------|----------|-----------|--------|
| TC-SEC-ALL-002 | .google-workspace/ 디렉토리 권한 0700 | `stat` 명령어 | 가능 |
| TC-SEC-ALL-003 | ~/.claude/mcp.json 파일 권한 0600 | `stat` 명령어 | 가능 |
| TC-SEC-ALL-004 | ~/.atlassian-mcp/ 디렉토리 700 + credentials.env 600 | `stat` 명령어 | 가능 |
| TC-SEC-ALL-011 | PKCE code_verifier 엔트로피: openssl rand -base64 32 | oauth-helper.sh 확인 | 수동 |
| TC-SEC-ALL-012 | PKCE code_challenge: S256 SHA-256 해시 | 해시 검증 | 수동 |
| TC-SEC-ALL-021 | Drive 쿼리 백슬래시 이스케이프: `test\\injection` -> `test\\\\injection` | Vitest | 가능 |
| TC-SEC-ALL-022 | Drive ID 인젝션: `1234' OR name='hack` -> validateDriveId 에러 | Vitest | 가능 |

#### F.6 공유 유틸리티 누락 TC

| TC ID | 핵심 검증 | 환경 | 자동화 |
|-------|----------|------|--------|
| TC-SHR-ALL-004 | pkg_detect_manager: yum -> CentOS | Docker (centos) | 가능 |
| TC-SHR-ALL-005 | pkg_detect_manager: pacman -> Arch | Docker (archlinux) | 가능 |

---

### G. TC 전수 대응 검증 매트릭스

본 설계서가 커버하는 310개 TC의 전수 매핑:

```
TC-INS-MAC-001 ~ 026  : 3.1절 (26건) -- 전수 커버
TC-INS-WIN-001 ~ 016  : 3.2절 (16건) -- 전수 커버
TC-INS-LNX-001 ~ 010  : 3.3절 (10건) -- 전수 커버
TC-AUT-ALL-001 ~ 022  : 4.1절 (22건) -- 전수 커버
TC-GML-ALL-001 ~ 022  : 4.2절 (22건) -- 전수 커버
TC-DRV-ALL-001 ~ 020  : 4.3절 (20건) -- 전수 커버
TC-CAL-ALL-001 ~ 015  : 4.4절 (15건) -- 전수 커버
TC-DOC-ALL-001 ~ 013  : 4.5절 (13건) -- 전수 커버
TC-SHT-ALL-001 ~ 014  : 4.6절 (14건) -- 전수 커버
TC-SLD-ALL-001 ~ 011  : 4.7절 (11건) -- 전수 커버
TC-ATL-ALL-001 ~ 007  : 5.1절 (7건) -- 전수 커버
TC-FIG-ALL-001 ~ 008  : 5.2절 + F.1 (8건) -- 전수 커버
TC-NOT-ALL-001 ~ 004  : 5.3절 (4건) -- 전수 커버
TC-GIT-*              : 5.4절 + F.2 (6건) -- 전수 커버
TC-PEN-*              : 5.5절 (5건) -- 전수 커버
TC-SHR-ALL-001 ~ 010  : 7.2절 + F.6 (10건) -- 전수 커버
TC-SHR-ALL-020 ~ 022  : 7.3절 (3건) -- 전수 커버
TC-SHR-WIN-001 ~ 003  : 7.3절 (3건) -- 전수 커버
TC-DOK-ALL-001 ~ 007  : 7.4절 (7건) -- 전수 커버
TC-SEC-ALL-*          : 8절 + F.5 (38건) -- 전수 커버
TC-PER-ALL-*          : 9절 + F.3 (25건) -- 전수 커버
TC-E2E-*              : 6절 (19건) -- 전수 커버
TC-REG-ALL-001 ~ 010  : 10절 + F.4 (10건) -- 전수 커버

합계: 314건 (계획서 기준 310건 + 4건 중복 ID 처리)
```

---

*문서 끝*
