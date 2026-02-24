# Gemini CLI Support Plan

> **Summary**: ADW 인스톨러에 Claude / Gemini 선택 옵션 추가 — 사용자가 선택하면 IDE, CLI, 플러그인, MCP 설정까지 전부 해당 플랫폼에 맞게 설치
>
> **Project**: popup-claude (AI-Driven Work Installer)
> **Feature**: gemini-cli-support
> **Author**: Claude (PDCA Plan)
> **Date**: 2026-02-22
> **Status**: Draft (v2 — 호환성 조사 반영)

---

## 1. Overview

### 1.1 Purpose

현재 ADW 인스톨러는 Claude 전용으로 하드코딩되어 있다. 사용자가 **Claude 또는 Gemini 중 하나를 선택**하면 IDE, CLI, 플러그인, MCP 설정까지 **전부 해당 플랫폼에 맞게** 설치되도록 한다.

### 1.2 호환성 조사 결과

#### Claude vs Gemini — 설치 항목 비교

| 항목 | Claude | Gemini |
|------|--------|--------|
| **IDE** | VS Code | Antigravity |
| **IDE 설치** | `winget install Microsoft.VisualStudioCode` / `brew install --cask visual-studio-code` | `winget install Google.Antigravity` / `brew install --cask antigravity` |
| **VS Code 확장** | `anthropic.claude-code` | 불필요 (Antigravity 자체가 IDE) |
| **CLI 설치** | `curl claude.ai/install.sh \| bash` / `irm claude.ai/install.ps1 \| iex` | `npm install -g @google/gemini-cli` |
| **플러그인** | `claude plugin install bkit@bkit-marketplace` | `gemini extensions install https://github.com/popup-studio-ai/bkit-gemini.git` |
| **MCP 설정 파일** | `~/.claude/mcp.json` | `~/.gemini/settings.json` |
| **MCP 등록 명령어** | `claude mcp add` | `gemini mcp add` |
| **MCP JSON 구조** | `{ "mcpServers": { ... } }` | `{ "mcpServers": { ... } }` (동일) |
| **CLI 존재 체크** | `command -v claude` | `command -v gemini` |
| **인증** | Anthropic 계정/API 키 | Google 계정 (무료) |

#### MCP 모듈별 변경 필요 사항

| 모듈 | CLI 체크 | MCP 등록 명령어 | MCP 설정 파일 경로 | 변경 필요 |
|------|:--------:|:--------------:|:----------------:|:---------:|
| **Notion** | `claude` → `gemini` | `claude mcp add` → `gemini mcp add` | — | 2곳 |
| **Figma** | `claude` → `gemini` | `claude mcp add` → `gemini mcp add` | — | 2곳 |
| **Atlassian** | — | `claude mcp add` → `gemini mcp add` | `~/.claude/` → `~/.gemini/` | 2곳 |
| **Google** | — | — | `~/.claude/` → `~/.gemini/` | 1곳 |
| **GitHub** | — | — | — | 없음 |
| **Pencil** | — | — | VS Code 확장 | 미확인 |
| **OAuth Helper** | — | `claude mcp list` → `gemini mcp list` | — | 1곳 |

### 1.3 분기 포인트 요약

모든 변경은 아래 **4가지 분기**로 귀결됨:

1. **IDE 설치**: VS Code vs Antigravity
2. **CLI 설치 + 체크**: `claude` vs `gemini` 명령어
3. **플러그인 설치**: bkit(claude) vs bkit-gemini
4. **MCP 설정**: `~/.claude/mcp.json` vs `~/.gemini/settings.json`

---

## 2. Scope

### 2.1 In Scope

- [ ] **메인 인스톨러**: `--cli claude|gemini` 파라미터 + `CLI_TYPE` 환경변수
- [ ] **base 모듈**: IDE, CLI, 플러그인, VS Code 확장 분기
- [ ] **Notion 모듈**: CLI 체크 + MCP 등록 명령어 분기
- [ ] **Figma 모듈**: CLI 체크 + MCP 등록 명령어 분기
- [ ] **Atlassian 모듈**: MCP 등록 명령어 + 설정 파일 경로 분기
- [ ] **Google 모듈**: MCP 설정 파일 경로 분기
- [ ] **공유 유틸(mcp-config.sh)**: 설정 파일 경로 분기
- [ ] **공유 유틸(oauth-helper.sh)**: `claude mcp list` → CLI별 분기
- [ ] **README 업데이트**

### 2.2 Out of Scope

- Gemini + Claude 동시 설치 (하나만 선택)
- 랜딩페이지 UI 변경 (별도 작업)
- Pencil 모듈의 Gemini 대응 (확인 후 별도 작업)

---

## 3. Requirements

### 3.1 Functional Requirements

#### 메인 인스톨러 (install.sh / install.ps1)

| ID | Requirement | Priority | 대상 파일 |
|----|-------------|:--------:|----------|
| FR-01 | **`--cli claude\|gemini` 파라미터 추가** — 미지정 시 기본값 `claude` | **High** | `install.sh`, `install.ps1` |
| FR-02 | **`CLI_TYPE` 환경변수 지원** — 원격 실행 시 `CLI_TYPE=gemini bash` | **High** | `install.sh`, `install.ps1` |
| FR-03 | **`$CLI_TYPE`을 모든 하위 모듈에 export** | **High** | `install.sh`, `install.ps1` |

#### base 모듈 (base/install.sh / install.ps1)

| ID | Requirement | Priority | 대상 파일 |
|----|-------------|:--------:|----------|
| FR-04 | **IDE 설치 분기** — `claude` → VS Code, `gemini` → Antigravity | **High** | `base/install.sh`, `base/install.ps1` |
| FR-05 | **CLI 설치 분기** — `claude` → claude.ai 설치, `gemini` → `npm install -g @google/gemini-cli` | **High** | `base/install.sh`, `base/install.ps1` |
| FR-06 | **플러그인 분기** — `claude` → bkit, `gemini` → bkit-gemini | **High** | `base/install.sh`, `base/install.ps1` |
| FR-07 | **VS Code 확장 분기** — `claude` → `anthropic.claude-code`, `gemini` → 스킵 (Antigravity 내장) | **Medium** | `base/install.sh`, `base/install.ps1` |

#### MCP 모듈 (각 모듈 install.sh / install.ps1)

| ID | Requirement | Priority | 대상 파일 |
|----|-------------|:--------:|----------|
| FR-08 | **Notion: CLI 체크 + MCP 등록 분기** | **High** | `notion/install.sh`, `notion/install.ps1` |
| FR-09 | **Figma: CLI 체크 + MCP 등록 분기** | **High** | `figma/install.sh`, `figma/install.ps1` |
| FR-10 | **Atlassian: MCP 등록 + 설정 경로 분기** | **High** | `atlassian/install.sh`, `atlassian/install.ps1` |
| FR-11 | **Google: MCP 설정 경로 분기** | **High** | `google/install.sh`, `google/install.ps1` |

#### 공유 유틸리티

| ID | Requirement | Priority | 대상 파일 |
|----|-------------|:--------:|----------|
| FR-12 | **mcp-config.sh 경로 분기** — `CLI_TYPE`에 따라 `~/.claude/mcp.json` 또는 `~/.gemini/settings.json` | **High** | `shared/mcp-config.sh` |
| FR-13 | **oauth-helper.sh 명령어 분기** — `claude mcp list` → `gemini mcp list` | **High** | `shared/oauth-helper.sh`, `shared/oauth-helper.ps1` |

#### 기타

| ID | Requirement | Priority | 대상 파일 |
|----|-------------|:--------:|----------|
| FR-14 | **README.md 업데이트** — Gemini 설치 명령어 예시 추가 | **Low** | `README.md` |

### 3.2 Non-Functional Requirements

| ID | Requirement | Priority |
|----|-------------|:--------:|
| NFR-01 | `--cli` 미지정 시 기본값 `claude` — 기존 동작 100% 유지 | **Critical** |
| NFR-02 | 설치 실패 시 명확한 에러 메시지 + 수동 설치 안내 | **High** |
| NFR-03 | 기존 테스트 깨지지 않음 | **High** |

---

## 4. Implementation Strategy

### 4.1 변경 흐름

```
사용자 입력: --cli gemini (또는 CLI_TYPE=gemini)
        │
        ▼
    install.sh / install.ps1
        │  CLI_TYPE 변수 설정 + export
        ▼
    ┌─────────────────────────────────────────────┐
    │  base 모듈                                   │
    │  ├── [공통] Node.js, Git, WSL, Docker        │
    │  ├── [분기] IDE: VS Code vs Antigravity      │
    │  ├── [분기] CLI: Claude vs Gemini CLI        │
    │  └── [분기] 플러그인: bkit vs bkit-gemini    │
    └─────────────────────────────────────────────┘
        │  CLI_TYPE 계속 전달
        ▼
    ┌─────────────────────────────────────────────┐
    │  MCP 모듈들 (notion, figma, atlassian, etc.) │
    │  ├── [분기] CLI 체크: claude vs gemini        │
    │  ├── [분기] MCP 등록: claude mcp vs gemini mcp│
    │  └── [분기] 설정 경로: ~/.claude vs ~/.gemini │
    └─────────────────────────────────────────────┘
```

### 4.2 수정 대상 파일 (총 16개)

| 파일 | 변경 내용 |
|------|----------|
| `installer/install.sh` | `--cli` 파라미터 + `CLI_TYPE` export |
| `installer/install.ps1` | `-cli` 파라미터 + `$env:CLI_TYPE` |
| `modules/base/install.sh` | IDE + CLI + 플러그인 + 확장 분기 |
| `modules/base/install.ps1` | IDE + CLI + 플러그인 + 확장 분기 |
| `modules/notion/install.sh` | CLI 체크 + MCP 등록 분기 |
| `modules/notion/install.ps1` | CLI 체크 + MCP 등록 분기 |
| `modules/figma/install.sh` | CLI 체크 + MCP 등록 분기 |
| `modules/figma/install.ps1` | CLI 체크 + MCP 등록 분기 |
| `modules/atlassian/install.sh` | MCP 등록 + 설정 경로 분기 |
| `modules/atlassian/install.ps1` | MCP 등록 + 설정 경로 분기 |
| `modules/google/install.sh` | MCP 설정 경로 분기 |
| `modules/google/install.ps1` | MCP 설정 경로 분기 |
| `modules/shared/mcp-config.sh` | 설정 파일 경로 분기 |
| `modules/shared/oauth-helper.sh` | `claude mcp list` 분기 |
| `modules/shared/oauth-helper.ps1` | `claude mcp list` 분기 |
| `README.md` | Gemini 옵션 문서화 |

---

## 5. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Gemini CLI/Antigravity가 빠르게 변화 중 | 설치 명령어 변경 가능 | npm/winget/brew 패키지명은 안정적 |
| `gemini mcp add` 문법이 `claude mcp add`와 다를 수 있음 | MCP 등록 실패 | Design 단계에서 정확한 문법 확인 |
| Pencil 모듈 Gemini 미지원 | 기능 제한 | Gemini 선택 시 Pencil 스킵 + 안내 |
| Antigravity가 무료 Preview 상태 | 서비스 변경 가능 | 설치 시 Preview 상태 안내 |

---

## 6. Success Criteria

- [ ] `./install.sh --cli gemini` → Antigravity + Gemini CLI + bkit-gemini 설치
- [ ] `.\install.ps1 -cli gemini` → 동일
- [ ] `--cli` 미지정 → 기존 Claude 설치 (하위호환 100%)
- [ ] MCP 모듈(notion, figma, atlassian, google)이 Gemini 설정에 등록됨
- [ ] 기존 테스트 통과
