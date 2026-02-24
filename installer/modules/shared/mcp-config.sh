#!/bin/bash
# ============================================
# Shared MCP Configuration Utilities
# FR-S3-05a: Eliminate 4x duplicate MCP config logic
# FR-S2-03: Unified config path (~/.claude/mcp.json)
# ============================================

# Source colors if not already loaded
if [ -z "$NC" ]; then
    SCRIPT_DIR_MCP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SHARED_DIR:-$SCRIPT_DIR_MCP}/colors.sh"
fi

# Get the MCP config file path (unified across platforms)
# Branches on CLI_TYPE: claude -> ~/.claude/mcp.json, gemini -> ~/.gemini/settings.json
mcp_get_config_path() {
    local config_path
    if [ "$CLI_TYPE" = "gemini" ]; then
        config_path="$HOME/.gemini/settings.json"
    else
        config_path="$HOME/.claude/mcp.json"
    fi
    local legacy_path="$HOME/.mcp.json"

    # Migrate legacy config if needed (claude only)
    if [ "$CLI_TYPE" != "gemini" ] && [ -f "$legacy_path" ] && [ ! -f "$config_path" ]; then
        mkdir -p "$(dirname "$config_path")"
        cp "$legacy_path" "$config_path"
        echo -e "  ${YELLOW}Migrated MCP config from $legacy_path to $config_path${NC}"
    fi

    echo "$config_path"
}

# Check if Node.js is available (required for MCP config manipulation)
mcp_check_node() {
    if ! command -v node > /dev/null 2>&1; then
        echo -e "  ${RED}Node.js is required for MCP configuration${NC}"
        return 1
    fi
    return 0
}

# Add a Docker-based MCP server to config
# Usage: mcp_add_docker_server "server_name" "image_name" [extra_args...]
mcp_add_docker_server() {
    local server_name="$1"
    local image_name="$2"
    shift 2
    local extra_args=("$@")

    local config_path
    config_path=$(mcp_get_config_path)

    MCP_CONFIG_PATH="$config_path" \
    SERVER_NAME="$server_name" \
    IMAGE_NAME="$image_name" \
    EXTRA_ARGS="${extra_args[*]}" \
    node -e "
const fs = require('fs');
const path = require('path');
const configPath = process.env.MCP_CONFIG_PATH;
const serverName = process.env.SERVER_NAME;
const imageName = process.env.IMAGE_NAME;
const extraArgs = process.env.EXTRA_ARGS ? process.env.EXTRA_ARGS.split(' ').filter(Boolean) : [];

const dir = path.dirname(configPath);
if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

let config = { mcpServers: {} };
if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    if (!config.mcpServers) config.mcpServers = {};
}

config.mcpServers[serverName] = {
    command: 'docker',
    args: ['run', '-i', '--rm', ...extraArgs, imageName]
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2), { mode: 0o600 });
"
    echo -e "  ${GREEN}[OK] MCP server '$server_name' configured${NC}"
}

# Add a stdio-based MCP server to config
# Usage: mcp_add_stdio_server "server_name" "command" [args...]
mcp_add_stdio_server() {
    local server_name="$1"
    local cmd="$2"
    shift 2
    local cmd_args=("$@")

    local config_path
    config_path=$(mcp_get_config_path)

    MCP_CONFIG_PATH="$config_path" \
    SERVER_NAME="$server_name" \
    CMD="$cmd" \
    CMD_ARGS="${cmd_args[*]}" \
    node -e "
const fs = require('fs');
const path = require('path');
const configPath = process.env.MCP_CONFIG_PATH;
const serverName = process.env.SERVER_NAME;
const cmd = process.env.CMD;
const cmdArgs = process.env.CMD_ARGS ? process.env.CMD_ARGS.split(' ').filter(Boolean) : [];

const dir = path.dirname(configPath);
if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

let config = { mcpServers: {} };
if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    if (!config.mcpServers) config.mcpServers = {};
}

config.mcpServers[serverName] = {
    command: cmd,
    args: cmdArgs
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2), { mode: 0o600 });
"
    echo -e "  ${GREEN}[OK] MCP server '$server_name' configured${NC}"
}

# Remove an MCP server from config
mcp_remove_server() {
    local server_name="$1"
    local config_path
    config_path=$(mcp_get_config_path)

    if [ ! -f "$config_path" ]; then
        return 0
    fi

    MCP_CONFIG_PATH="$config_path" \
    SERVER_NAME="$server_name" \
    node -e "
const fs = require('fs');
const configPath = process.env.MCP_CONFIG_PATH;
const serverName = process.env.SERVER_NAME;

const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
if (config.mcpServers) {
    delete config.mcpServers[serverName];
}
fs.writeFileSync(configPath, JSON.stringify(config, null, 2), { mode: 0o600 });
"
}

# Add MCP server permission to ~/.claude/settings.json
# Usage: mcp_add_permission "mcp__server-name"
mcp_add_permission() {
    local permission="$1"

    # Claude only (not gemini)
    if [ "$CLI_TYPE" = "gemini" ]; then
        return 0
    fi

    local settings_path="$HOME/.claude/settings.json"

    if ! mcp_check_node; then
        return 1
    fi

    SETTINGS_PATH="$settings_path" \
    PERMISSION="$permission" \
    node -e "
const fs = require('fs');
const settingsPath = process.env.SETTINGS_PATH;
const permission = process.env.PERMISSION;

let settings = {};
if (fs.existsSync(settingsPath)) {
    try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8').replace(/^\uFEFF/, '')); } catch(e) {}
}

if (!settings.permissions) settings.permissions = {};
if (!settings.permissions.allow) settings.permissions.allow = [];

if (!settings.permissions.allow.includes(permission)) {
    settings.permissions.allow.push(permission);
    fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
    console.log('  Added permission: ' + permission);
} else {
    console.log('  Permission already set: ' + permission);
}
"
    echo -e "  ${GREEN}[OK] Claude settings updated${NC}"
}

# Check if an MCP server exists in config
mcp_server_exists() {
    local server_name="$1"
    local config_path
    config_path=$(mcp_get_config_path)

    if [ ! -f "$config_path" ]; then
        return 1
    fi

    MCP_CONFIG_PATH="$config_path" \
    SERVER_NAME="$server_name" \
    node -e "
const fs = require('fs');
const config = JSON.parse(fs.readFileSync(process.env.MCP_CONFIG_PATH, 'utf8'));
process.exit(config.mcpServers && config.mcpServers[process.env.SERVER_NAME] ? 0 : 1);
"
}
