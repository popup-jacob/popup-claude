# AI-Driven Work - Complete Setup

All-in-one installer for Claude Code + bkit + MCP tools.

## One-Click Install (Recommended)

### Windows

**Step 1:** Open PowerShell as Administrator, then run:
```powershell
irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_basic.ps1 | iex
```

**Step 2:** Restart your computer, open PowerShell as Administrator, then run:
```powershell
irm https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_mcp.ps1 | iex
```

> **How to open PowerShell as Administrator:**
> Press `Win + X` → Click "Windows Terminal (Admin)" or "PowerShell (Admin)"

### Mac/Linux

Open Terminal and run:
```bash
curl -fsSL https://raw.githubusercontent.com/popup-jacob/popup-claude/master/final-installer/setup_all.sh | bash
```

---

## Alternative: Local Installation

### Windows (2-step process)
```powershell
# Step 1: Install basic tools + bkit
powershell -ep bypass -File setup_basic.ps1

# Restart your computer

# Step 2: Set up MCP (after restart, with Docker running)
powershell -ep bypass -File setup_mcp.ps1
```

### Mac/Linux (1-step process)
```bash
chmod +x setup_all.sh && ./setup_all.sh
```

---

## Windows Script Details

| Script | What it does |
|--------|-------------|
| `setup_basic.ps1` | Node.js, Git, VS Code, Docker, Claude CLI, bkit |
| `setup_mcp.ps1` | Google MCP, Jira/Confluence MCP (requires Docker) |

**Why 2 scripts?** Windows requires a restart after Docker installation (WSL2/Hyper-V activation).

---

## Troubleshooting

### Windows: "winget not found" Error

If you see this error, run `install_dev.ps1` first:

```powershell
# Step 1: Install basic tools (Node.js, Git, VS Code, Docker, Claude CLI)
powershell -ep bypass -File ..\installer_popup\install_dev.ps1

# Step 2: Restart your computer

# Step 3: Run setup_basic.ps1 (bkit setup)
powershell -ep bypass -File setup_basic.ps1
```

`install_dev.ps1` uses direct download instead of winget, so it works on all Windows versions.

---

## Notes

### Claude Login for bkit Plugin

bkit plugin installation may work without Claude login (downloads from GitHub).
If installation fails, try logging in first:
```
claude login
```

---

## Google MCP Admin Setup

If you are an **Admin** setting up Google MCP for your team:

1. Set up Google Cloud Console (create project, enable APIs, OAuth)
2. See the admin guide: [../docs/SETUP_GOOGLE_INTERNAL_ADMIN.md](../docs/SETUP_GOOGLE_INTERNAL_ADMIN.md)
3. Share `client_secret.json` and `google-workspace-mcp.tar` with employees

For external (non-Google Workspace) setup: [../docs/SETUP_GOOGLE_EXTERNAL_ADMIN.md](../docs/SETUP_GOOGLE_EXTERNAL_ADMIN.md)

---

## What Gets Installed

### setup_basic.ps1 / setup_all.sh (Part 1)
| Component | Description |
|-----------|-------------|
| Node.js | JavaScript runtime |
| Git | Version control |
| VS Code | Code editor |
| Docker Desktop | Container platform |
| Claude Code CLI | AI coding assistant |
| bkit Plugin | Development workflow plugin |

### setup_mcp.ps1 / setup_all.sh (Part 2)
| Component | Description |
|-----------|-------------|
| Google MCP | Gmail, Calendar, Drive access (optional) |
| Jira MCP | Jira, Confluence access (optional) |
