#!/usr/bin/env bash
# install_nanobot.sh — Full install: ollama + nanobot (HKUDS) + recommended extras
# Covers: Python 3.11+, Node.js 20, Ollama, model pull, nanobot from source,
#         Brave Search, Telegram channel, MCP filesystem server, systemd user service
# Usage: bash install_nanobot.sh
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[•]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
die()     { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}── $* ──${NC}"; }

# ── Model menu ────────────────────────────────────────────────────────────────
MODELS=(
    "Llama 3.2 3B  (2.0 GB) — fast, general purpose|llama3.2:3b"
    "Llama 3.2 1B  (1.3 GB) — smallest Llama, very fast|llama3.2:1b"
    "Llama 3.1 8B  (4.9 GB) — strong reasoning + tool use|llama3.1:8b"
    "Mistral 7B    (4.1 GB) — solid all-rounder|mistral:7b"
    "Qwen2.5 7B    (4.7 GB) — great coding + reasoning|qwen2.5:7b"
    "Qwen2.5 3B    (2.0 GB) — compact, efficient|qwen2.5:3b"
    "Phi-4 Mini    (2.5 GB) — Microsoft, strong reasoning|phi4-mini"
    "Gemma 3 4B    (3.3 GB) — Google, efficient|gemma3:4b"
    "DeepSeek-R1 7B (4.7 GB) — reasoning model|deepseek-r1:7b"
    "Enter a custom model tag manually|__custom__"
)

# ── Config state (populated during prompts) ───────────────────────────────────
MODEL_TAG=""
BRAVE_API_KEY=""
TELEGRAM_TOKEN=""
TELEGRAM_USER_ID=""
MCP_WORKSPACE_PATH=""
SETUP_SYSTEMD=false

# ── Helpers ───────────────────────────────────────────────────────────────────
require_cmd() {
    command -v "$1" &>/dev/null || die "'$1' not found after install — check your PATH."
}

check_python() {
    for py in python3.13 python3.12 python3.11; do
        command -v "$py" &>/dev/null && { echo "$py"; return 0; }
    done
    return 1
}

install_python311() {
    info "Installing Python 3.11 via deadsnakes PPA..."
    sudo apt-get update -qq
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update -qq
    sudo apt-get install -y python3.11 python3.11-venv python3.11-dev
}

install_nodejs() {
    info "Installing Node.js 20 via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    require_cmd node
    require_cmd npm
    success "Node.js $(node --version) installed"
}

prompt_yn() {
    local prompt="$1"
    while true; do
        read -rp "$(echo -e "${YELLOW}[?]${NC} ${prompt} [y/n]: ")" yn
        case "${yn,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) warn "Please answer y or n." ;;
        esac
    done
}

# ── Root check ────────────────────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
    die "Do not run as root. Run as your normal user (sudo access required)."
fi

echo ""
echo -e "${BOLD}${CYAN}🐈 nanobot + ollama — full installer${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 1 — COLLECT ALL INPUTS UPFRONT
# ══════════════════════════════════════════════════════════════════════════════
header "Configuration"

# ── Model selection ───────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Select a model to pull with Ollama:${NC}"
echo ""
for i in "${!MODELS[@]}"; do
    printf "  %2d) %s\n" "$((i+1))" "${MODELS[$i]%%|*}"
done
echo ""
while true; do
    read -rp "Enter number [1-${#MODELS[@]}]: " CHOICE
    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#MODELS[@]} )); then
        break
    fi
    warn "Invalid choice."
done
SELECTED="${MODELS[$((CHOICE-1))]}"
MODEL_TAG="${SELECTED##*|}"
if [[ "$MODEL_TAG" == "__custom__" ]]; then
    read -rp "  Enter Ollama model tag (e.g. llama3.1:8b): " MODEL_TAG
    [[ -z "$MODEL_TAG" ]] && die "Model tag cannot be empty."
fi
success "Model: ${MODEL_TAG}"

# ── Brave Search ──────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Brave Search API${NC} — enables live web search"
echo -e "  Free tier: 1,000 queries/month — get a key at ${YELLOW}brave.com/search/api${NC}"
echo ""
if prompt_yn "Configure Brave Search?"; then
    read -rp "  Brave Search API key: " BRAVE_API_KEY
    BRAVE_API_KEY="${BRAVE_API_KEY// /}"
    [[ -n "$BRAVE_API_KEY" ]] && success "Brave key captured" || warn "Blank — web search disabled"
else
    warn "Skipped — web search will be unavailable"
fi

# ── Telegram ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Telegram channel${NC} — gives nanobot a real UI"
echo -e "  1. Create a bot via @BotFather → copy the token"
echo -e "  2. Get your numeric user ID via @userinfobot"
echo ""
if prompt_yn "Configure Telegram?"; then
    read -rp "  Bot token: " TELEGRAM_TOKEN
    TELEGRAM_TOKEN="${TELEGRAM_TOKEN// /}"
    read -rp "  Your numeric user ID: " TELEGRAM_USER_ID
    TELEGRAM_USER_ID="${TELEGRAM_USER_ID// /}"
    if [[ -n "$TELEGRAM_TOKEN" && -n "$TELEGRAM_USER_ID" ]]; then
        success "Telegram config captured"
    else
        warn "Incomplete — Telegram will not be enabled"
        TELEGRAM_TOKEN=""
        TELEGRAM_USER_ID=""
    fi
else
    warn "Skipped — CLI mode only"
fi

# ── MCP filesystem server ─────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}MCP filesystem server${NC} — scoped file access via Model Context Protocol"
echo ""
if prompt_yn "Configure MCP filesystem server?"; then
    read -rp "  Path to expose [default: $HOME]: " MCP_WORKSPACE_PATH
    MCP_WORKSPACE_PATH="${MCP_WORKSPACE_PATH:-$HOME}"
    MCP_WORKSPACE_PATH="${MCP_WORKSPACE_PATH%/}"
    MCP_WORKSPACE_PATH="${MCP_WORKSPACE_PATH/#\~/$HOME}"
    if [[ -d "$MCP_WORKSPACE_PATH" ]]; then
        success "MCP path: ${MCP_WORKSPACE_PATH}"
    else
        warn "Path does not exist — MCP filesystem will not be configured"
        MCP_WORKSPACE_PATH=""
    fi
else
    warn "Skipped"
fi

# ── systemd service ───────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}systemd user service${NC} — runs nanobot gateway on login / after reboot"
echo ""
if prompt_yn "Install systemd user service?"; then
    SETUP_SYSTEMD=true
    success "systemd service will be installed"
else
    warn "Skipped — start manually with: nanobot gateway"
fi

echo ""
echo -e "${GREEN}All inputs collected — starting install.${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — INSTALL
# ══════════════════════════════════════════════════════════════════════════════

# ── System deps ───────────────────────────────────────────────────────────────
header "System dependencies"
MISSING=()
for pkg in git curl; do
    command -v "$pkg" &>/dev/null || MISSING+=("$pkg")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
    info "Installing: ${MISSING[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y "${MISSING[@]}"
fi
success "git, curl OK"

# ── Python ────────────────────────────────────────────────────────────────────
header "Python 3.11+"
PYTHON=$(check_python || true)
if [[ -z "$PYTHON" ]]; then
    warn "Python 3.11+ not found."
    install_python311
    PYTHON="python3.11"
fi
PY_VER=$("$PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
success "Using $PYTHON (${PY_VER})"
if ! "$PYTHON" -m pip --version &>/dev/null; then
    info "Installing pip..."
    sudo apt-get install -y python3-pip || "$PYTHON" -m ensurepip --upgrade
fi

# ── Node.js 20 ────────────────────────────────────────────────────────────────
header "Node.js 20"
if command -v node &>/dev/null; then
    NODE_MAJOR=$(node --version | sed 's/v\([0-9]*\).*/\1/')
    if (( NODE_MAJOR >= 18 )); then
        success "Node.js $(node --version) already installed"
    else
        warn "Node.js $(node --version) too old (need ≥18) — upgrading..."
        install_nodejs
    fi
else
    install_nodejs
fi
require_cmd npx

# ── Ollama ────────────────────────────────────────────────────────────────────
header "Ollama"
if command -v ollama &>/dev/null; then
    success "Ollama already installed ($(ollama --version 2>/dev/null || echo 'unknown'))"
else
    info "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    require_cmd ollama
    success "Ollama installed"
fi

if ! pgrep -x ollama &>/dev/null; then
    info "Starting Ollama service..."
    ollama serve &>/dev/null &
    sleep 3
    success "Ollama service started"
else
    success "Ollama service already running"
fi

info "Pulling model '${MODEL_TAG}' (this may take a while)..."
ollama pull "$MODEL_TAG"
success "Model '${MODEL_TAG}' ready"

# ── nanobot ───────────────────────────────────────────────────────────────────
header "nanobot"
NANOBOT_DIR="$HOME/nanobot"
if [[ -d "$NANOBOT_DIR/.git" ]]; then
    info "Repo exists at ${NANOBOT_DIR} — pulling latest..."
    git -C "$NANOBOT_DIR" pull --ff-only
else
    info "Cloning HKUDS/nanobot..."
    git clone https://github.com/HKUDS/nanobot.git "$NANOBOT_DIR"
fi
info "pip install -e ..."
"$PYTHON" -m pip install -e "$NANOBOT_DIR" --quiet
require_cmd nanobot
success "nanobot installed"

# ── Config ────────────────────────────────────────────────────────────────────
header "config.json"
NANOBOT_CONFIG_DIR="$HOME/.nanobot"
NANOBOT_CONFIG="$NANOBOT_CONFIG_DIR/config.json"
mkdir -p "$NANOBOT_CONFIG_DIR"

if [[ -f "$NANOBOT_CONFIG" ]]; then
    BACKUP="${NANOBOT_CONFIG}.bak.$(date +%Y%m%d_%H%M%S)"
    warn "Existing config found — backing up to $(basename "$BACKUP")"
    cp "$NANOBOT_CONFIG" "$BACKUP"
fi

# Build channel block
if [[ -n "$TELEGRAM_TOKEN" ]]; then
    TELEGRAM_BLOCK="    \"telegram\": {
      \"enabled\": true,
      \"token\": \"${TELEGRAM_TOKEN}\",
      \"allowFrom\": [\"${TELEGRAM_USER_ID}\"]
    }"
else
    TELEGRAM_BLOCK="    \"telegram\": {
      \"enabled\": false,
      \"token\": \"\",
      \"allowFrom\": []
    }"
fi

# Build Brave block
if [[ -n "$BRAVE_API_KEY" ]]; then
    BRAVE_INNER="\"apiKey\": \"${BRAVE_API_KEY}\", \"maxResults\": 5"
else
    BRAVE_INNER="\"apiKey\": \"\", \"maxResults\": 5"
fi

# Build tools block (with or without MCP)
if [[ -n "$MCP_WORKSPACE_PATH" ]]; then
    TOOLS_BLOCK="  \"tools\": {
    \"web\": { \"search\": { ${BRAVE_INNER} } },
    \"mcpServers\": {
      \"filesystem\": {
        \"command\": \"npx\",
        \"args\": [\"-y\", \"@modelcontextprotocol/server-filesystem\", \"${MCP_WORKSPACE_PATH}\"]
      }
    }
  }"
else
    TOOLS_BLOCK="  \"tools\": {
    \"web\": { \"search\": { ${BRAVE_INNER} } }
  }"
fi

cat > "$NANOBOT_CONFIG" <<EOF
{
  "providers": {
    "ollama": {
      "apiKey": "dummy",
      "apiBase": "http://localhost:11434/v1"
    }
  },
  "agents": {
    "defaults": {
      "model": "ollama/${MODEL_TAG}",
      "workspace": "~/.nanobot/workspace",
      "maxTokens": 8192,
      "temperature": 0.7,
      "maxToolIterations": 20
    }
  },
  "channels": {
${TELEGRAM_BLOCK}
  },
  "gateway": {
    "host": "0.0.0.0",
    "port": 18789
  },
${TOOLS_BLOCK}
}
EOF
success "Config written to ${NANOBOT_CONFIG}"

# ── nanobot onboard ───────────────────────────────────────────────────────────
header "nanobot onboard"
info "Initializing workspace (AGENT.md, SOUL.md, memory scaffolding)..."
nanobot onboard || warn "onboard returned non-zero — you can re-run: nanobot onboard"
success "Workspace initialized"

# ── systemd user service ──────────────────────────────────────────────────────
if [[ "$SETUP_SYSTEMD" == true ]]; then
    header "systemd user service"
    NANOBOT_BIN=$(command -v nanobot)
    SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
    SERVICE_FILE="$SYSTEMD_USER_DIR/nanobot-gateway.service"
    mkdir -p "$SYSTEMD_USER_DIR"

    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Nanobot Gateway
After=network.target

[Service]
Type=simple
ExecStart=${NANOBOT_BIN} gateway
Restart=always
RestartSec=10
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=${HOME}
Environment=HOME=${HOME}
Environment=PATH=${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable --now nanobot-gateway
    success "nanobot-gateway service enabled and started"

    info "Enabling loginctl linger (service persists after logout)..."
    loginctl enable-linger "$USER"
    success "Linger enabled for ${USER}"
fi

# ── Verify ────────────────────────────────────────────────────────────────────
header "Verification"
curl -sf http://localhost:11434/api/tags &>/dev/null \
    && success "Ollama API reachable at localhost:11434" \
    || warn "Ollama API not responding — start manually: ollama serve"
success "nanobot: $(command -v nanobot)"
success "Node.js: $(node --version)"

# ══════════════════════════════════════════════════════════════════════════════
# DONE
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Installation complete!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Model:${NC}      ${CYAN}${MODEL_TAG}${NC}"
echo -e "  ${BOLD}Config:${NC}     ${CYAN}${NANOBOT_CONFIG}${NC}"
echo -e "  ${BOLD}Source:${NC}     ${CYAN}${NANOBOT_DIR}${NC}"
echo -e "  ${BOLD}Workspace:${NC}  ${CYAN}${HOME}/.nanobot/workspace${NC}"
[[ -n "$BRAVE_API_KEY" ]]      && echo -e "  ${BOLD}Web search:${NC} ${GREEN}enabled (Brave)${NC}"            || echo -e "  ${BOLD}Web search:${NC} ${YELLOW}disabled${NC}"
[[ -n "$TELEGRAM_TOKEN" ]]     && echo -e "  ${BOLD}Telegram:${NC}   ${GREEN}enabled${NC}"                    || echo -e "  ${BOLD}Telegram:${NC}   ${YELLOW}disabled${NC}"
[[ -n "$MCP_WORKSPACE_PATH" ]] && echo -e "  ${BOLD}MCP path:${NC}   ${CYAN}${MCP_WORKSPACE_PATH}${NC}"      || echo -e "  ${BOLD}MCP:${NC}        ${YELLOW}not configured${NC}"
[[ "$SETUP_SYSTEMD" == true ]] && echo -e "  ${BOLD}Service:${NC}    ${GREEN}nanobot-gateway (systemd)${NC}"  || echo -e "  ${BOLD}Service:${NC}    ${YELLOW}not installed${NC}"
echo ""
echo -e "${BOLD}Commands:${NC}"
echo -e "  ${YELLOW}nanobot agent${NC}                           # interactive CLI"
echo -e "  ${YELLOW}nanobot agent -m \"hello\"${NC}                # one-shot"
echo -e "  ${YELLOW}nanobot gateway${NC}                         # foreground gateway"
if [[ "$SETUP_SYSTEMD" == true ]]; then
echo -e "  ${YELLOW}systemctl --user status nanobot-gateway${NC}  # service status"
echo -e "  ${YELLOW}systemctl --user restart nanobot-gateway${NC} # restart after config edit"
echo -e "  ${YELLOW}journalctl --user -u nanobot-gateway -f${NC}  # follow logs"
fi
echo -e "  ${YELLOW}ollama serve${NC}                            # start Ollama if not running"
echo ""
if [[ -z "$BRAVE_API_KEY" ]]; then
    echo -e "${YELLOW}Tip:${NC} Add Brave Search later → edit ${CYAN}${NANOBOT_CONFIG}${NC}"
    echo -e "  Set ${CYAN}tools.web.search.apiKey${NC} — free key at ${CYAN}brave.com/search/api${NC}"
    echo ""
fi
if [[ -z "$TELEGRAM_TOKEN" ]]; then
    echo -e "${YELLOW}Tip:${NC} Add Telegram later:"
    echo -e "  1. @BotFather for token, @userinfobot for your ID"
    echo -e "  2. Edit config → set ${CYAN}channels.telegram.enabled=true${NC}"
    if [[ "$SETUP_SYSTEMD" == true ]]; then
    echo -e "  3. ${YELLOW}systemctl --user restart nanobot-gateway${NC}"
    fi
    echo ""
fi
