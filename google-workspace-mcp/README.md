# Google Workspace MCP

Claude Code에서 Google Workspace (Gmail, Calendar, Drive)에 접근할 수 있게 해주는 MCP 서버입니다.

---

## 설치 방법

### 일반 사용자 (권장)

원클릭 설치를 사용하세요:

**Windows:**
```
Win + R 누르고 실행:
powershell -ep bypass -c "irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/adw/manual-installer/setup_mcp.ps1|iex"
```

**Mac:**
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/adw/manual-installer/setup_all.sh | bash
```

설치 중 "Set up Google MCP? (y/n)" 질문에 `y`를 입력하세요.

### 관리자

팀을 위해 Google MCP를 설정하려면:

| 상황 | 가이드 |
|------|--------|
| Google Workspace 사용 (회사 도메인) | [내부 관리자 가이드](../docs/SETUP_GOOGLE_INTERNAL_ADMIN.md) |
| Gmail 사용 (개인/외부) | [외부 관리자 가이드](../docs/SETUP_GOOGLE_EXTERNAL_ADMIN.md) |

---

## Docker 이미지

Docker 이미지는 ghcr.io에 호스팅되어 있습니다 (multi-arch: amd64 + arm64).

```bash
# 이미지 다운로드
docker pull ghcr.io/popup-jacob/google-workspace-mcp:latest

# 실행
docker run -i --rm \
  -v "$HOME/.google-workspace:/app/.google-workspace" \
  ghcr.io/popup-jacob/google-workspace-mcp:latest
```

---

## 지원 기능

| 서비스 | 기능 |
|--------|------|
| Gmail | 이메일 읽기, 검색, 전송 |
| Calendar | 일정 조회, 생성 |
| Drive | 파일 검색, 다운로드 |
| Docs | 문서 읽기, 생성 |
| Sheets | 스프레드시트 읽기, 생성 |
| Slides | 프레젠테이션 읽기, 생성 |

---

## 개발

### 빌드

```bash
npm install
npm run build
```

### Docker 이미지 빌드

```bash
docker build -t google-workspace-mcp .
```

### Multi-arch 빌드 (AMD64 + ARM64)

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/popup-jacob/google-workspace-mcp:latest --push .
```
