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
DISCORD_TOKEN=""
DISCORD_CHANNEL_ID=""
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
    local default="${2:-n}"  # n = no by default, y = yes by default
    local opts="[y/N]"
    [[ "$default" == "y" ]] && opts="[Y/n]"

    while true; do
        read -rp "$(echo -e "${YELLOW}[?]${NC} ${prompt} ${opts}: ")" yn
        case "${yn,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            "") [[ "$default" == "y" ]] && return 0 || return 1 ;;
            *) warn "Please answer y or n, or press Enter for default." ;;
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
    if (( i == 0 )); then
        printf "  %2d) %s %s[RECOMMENDED - Fast & Capable]%s\n" "$((i+1))" "${MODELS[$i]%%|*}" "${GREEN}" "${NC}"
    else
        printf "  %2d) %s\n" "$((i+1))" "${MODELS[$i]%%|*}"
    fi
done
echo ""
while true; do
    read -rp "Enter number [1-${#MODELS[@]}, default: 1]: " CHOICE
    CHOICE="${CHOICE:-1}"  # Default to 1 if empty
    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#MODELS[@]} )); then
        break
    fi
    warn "Invalid choice. Enter a number between 1 and ${#MODELS[@]}"
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
echo -e "  ${YELLOW}[Optional - can add later]${NC}"
echo ""
if prompt_yn "Configure Brave Search now?" "n"; then
    read -rp "  Brave Search API key: " BRAVE_API_KEY
    BRAVE_API_KEY="${BRAVE_API_KEY// /}"
    [[ -n "$BRAVE_API_KEY" ]] && success "Brave key captured" || warn "Blank — web search disabled"
else
    warn "Skipped — you can add Brave Search later"
fi

# ── Discord ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Discord channel${NC} — gives nanobot a real UI"
echo -e "  1. Create a bot at ${YELLOW}discord.com/developers/applications${NC} → copy token"
echo -e "  2. Copy your Discord channel ID (from Discord → right-click channel → Copy ID)"
echo -e "  ${YELLOW}[Recommended - easier than Telegram]${NC}"
echo ""
if prompt_yn "Configure Discord?" "y"; then
    read -rp "  Bot token: " DISCORD_TOKEN
    DISCORD_TOKEN="${DISCORD_TOKEN// /}"
    read -rp "  Discord channel ID: " DISCORD_CHANNEL_ID
    DISCORD_CHANNEL_ID="${DISCORD_CHANNEL_ID// /}"
    if [[ -n "$DISCORD_TOKEN" && -n "$DISCORD_CHANNEL_ID" ]]; then
        success "Discord config captured"
    else
        warn "Incomplete — Discord will not be enabled"
        DISCORD_TOKEN=""
        DISCORD_CHANNEL_ID=""
    fi
else
    warn "Skipped — CLI mode only"
fi

# ── MCP filesystem server ─────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}MCP filesystem server${NC} — scoped file access via Model Context Protocol"
echo -e "  ${YELLOW}[Recommended for file operations]${NC}"
echo ""
if prompt_yn "Configure MCP filesystem server?" "y"; then
    read -rp "  Path to expose [default: $HOME/.nanobot/workspace]: " MCP_WORKSPACE_PATH
    MCP_WORKSPACE_PATH="${MCP_WORKSPACE_PATH:-$HOME/.nanobot/workspace}"
    [[ -z "$MCP_WORKSPACE_PATH" ]] && info "Using default: $HOME/.nanobot/workspace"
    MCP_WORKSPACE_PATH="${MCP_WORKSPACE_PATH%/}"
    MCP_WORKSPACE_PATH="${MCP_WORKSPACE_PATH/#\~/$HOME}"
    if mkdir -p "$MCP_WORKSPACE_PATH" && [[ -d "$MCP_WORKSPACE_PATH" ]]; then
        success "MCP path: ${MCP_WORKSPACE_PATH}"
    else
        warn "Path could not be created — MCP filesystem will not be configured"
        MCP_WORKSPACE_PATH=""
    fi
else
    warn "Skipped"
fi

# ── GPU Configuration ─────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}GPU Acceleration${NC} — force Ollama to use GPU (NVIDIA/AMD/Intel)"
echo -e "  ${YELLOW}[Optional - auto-detection usually works]${NC}"
echo ""
GPU_CONFIG=""
if prompt_yn "Configure GPU acceleration?" "n"; then
    echo ""
    echo -e "${CYAN}Select your GPU type:${NC}"
    echo "  1) NVIDIA CUDA (RTX, GTX, Tesla, etc.)"
    echo "  2) AMD ROCm (Radeon RX, Radeon Pro, etc.)"
    echo "  3) Intel Arc"
    echo "  4) Apple Metal (macOS only)"
    echo "  5) CPU only (no GPU)"
    echo ""
    while true; do
        read -rp "Enter GPU type [1-5, default: auto-detect]: " gpu_choice
        gpu_choice="${gpu_choice:-0}"
        if [[ "$gpu_choice" =~ ^[0-5]$ ]]; then
            break
        fi
        warn "Invalid choice. Enter 1-5 or press Enter for auto-detect."
    done

    case "$gpu_choice" in
        1)
            info "NVIDIA CUDA selected — will force CUDA acceleration"
            GPU_CONFIG="nvidia"
            ;;
        2)
            info "AMD ROCm selected — will force AMD acceleration"
            GPU_CONFIG="amd"
            ;;
        3)
            info "Intel Arc selected — will use Intel GPU"
            GPU_CONFIG="intel"
            ;;
        4)
            info "Apple Metal selected (macOS only)"
            GPU_CONFIG="metal"
            ;;
        5)
            info "CPU only mode — no GPU acceleration"
            GPU_CONFIG="cpu"
            ;;
        *)
            info "Auto-detection enabled"
            GPU_CONFIG=""
            ;;
    esac
else
    info "GPU auto-detection enabled (Ollama will detect automatically)"
fi

# ── systemd service ───────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}systemd user service${NC} — runs nanobot gateway on login / after reboot"
echo -e "  ${YELLOW}[Recommended for always-on AI agent]${NC}"
echo ""
if prompt_yn "Install systemd user service?" "y"; then
    SETUP_SYSTEMD=true
    success "systemd service will be installed"
else
    warn "Skipped — you can start manually with: nanobot gateway"
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
info "Installing nanobot package..."
"$PYTHON" -m pip install --user --upgrade "$NANOBOT_DIR" --quiet
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
if [[ -n "$DISCORD_TOKEN" ]]; then
    DISCORD_BLOCK="    \"discord\": {
      \"enabled\": true,
      \"token\": \"\",
      \"channelId\": \"${DISCORD_CHANNEL_ID}\"
    }"
else
    DISCORD_BLOCK="    \"discord\": {
      \"enabled\": false,
      \"token\": \"\",
      \"channelId\": \"\"
    }"
fi

# Build web search block
if [[ -n "$BRAVE_API_KEY" ]]; then
    WEB_SEARCH_INNER="\"provider\": \"brave\", \"apiKey\": \"${BRAVE_API_KEY}\", \"maxResults\": 5"
else
    WEB_SEARCH_INNER="\"provider\": \"duckduckgo\", \"apiKey\": \"\", \"maxResults\": 5"
fi

# Build tools block (with or without MCP)
if [[ -n "$MCP_WORKSPACE_PATH" ]]; then
    TOOLS_BLOCK="  \"tools\": {
    \"web\": { \"enable\": true, \"search\": { ${WEB_SEARCH_INNER} } },
    \"exec\": { \"enable\": true, \"timeout\": 60, \"pathAppend\": \"\" },
    \"restrictToWorkspace\": true,
    \"mcpServers\": {
      \"filesystem\": {
        \"command\": \"npx\",
        \"args\": [\"-y\", \"@modelcontextprotocol/server-filesystem\", \"${MCP_WORKSPACE_PATH}\"]
      }
    },
    \"ssrfWhitelist\": []
  }"
else
    TOOLS_BLOCK="  \"tools\": {
    \"web\": { \"enable\": true, \"search\": { ${WEB_SEARCH_INNER} } },
    \"exec\": { \"enable\": true, \"timeout\": 60, \"pathAppend\": \"\" },
    \"restrictToWorkspace\": true,
    \"mcpServers\": {},
    \"ssrfWhitelist\": []
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
      "model": "${MODEL_TAG}",
      "provider": "ollama",
      "workspace": "~/.nanobot/workspace",
      "maxTokens": 1024,
      "contextWindowTokens": 4096,
      "temperature": 0.2,
      "maxToolIterations": 20,
      "memory": {
        "maxHistoryEntries": 10000,
        "retrievedHistoryEntries": 6,
        "retrievedHistoryChars": 3000
      }
    }
  },
  "channels": {
${DISCORD_BLOCK}
  },
  "gateway": {
    "host": "127.0.0.1",
    "port": 18789
  },
${TOOLS_BLOCK}
}
EOF
success "Config written to ${NANOBOT_CONFIG}"

# Store Discord token outside the main config file.
GATEWAY_ENV_DIR="$HOME/.config/nanobot"
GATEWAY_ENV_FILE="$GATEWAY_ENV_DIR/gateway.env"
mkdir -p "$GATEWAY_ENV_DIR"
if [[ -n "$DISCORD_TOKEN" ]]; then
    cat > "$GATEWAY_ENV_FILE" <<EOF
NANOBOT_DISCORD_TOKEN=${DISCORD_TOKEN}
EOF
    chmod 600 "$GATEWAY_ENV_FILE"
    success "Discord token stored in ${GATEWAY_ENV_FILE}"
fi

# Create a launcher that injects secrets at runtime and waits for DNS.
GATEWAY_LAUNCHER="$HOME/.local/bin/nanobot-gateway-launcher"
mkdir -p "$HOME/.local/bin"
cat > "$GATEWAY_LAUNCHER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE_CONFIG="${HOME}/.nanobot/config.json"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/nanobot"
RUNTIME_CONFIG="${RUNTIME_DIR}/gateway-config.json"

mkdir -p "${RUNTIME_DIR}"
chmod 700 "${RUNTIME_DIR}"

export BASE_CONFIG
export RUNTIME_CONFIG

if [[ ! -f "${BASE_CONFIG}" ]]; then
    echo "Missing nanobot config: ${BASE_CONFIG}" >&2
    exit 1
fi

needs_discord_dns="$(python3.11 - <<'PY'
import json
import os
from pathlib import Path

data = json.loads(Path(os.environ["BASE_CONFIG"]).read_text(encoding="utf-8"))
discord = data.get("channels", {}).get("discord", {})
enabled = bool(discord.get("enabled"))
token = os.environ.get("NANOBOT_DISCORD_TOKEN", "").strip()
print("yes" if enabled and token else "no")
PY
)"

if [[ "${needs_discord_dns}" == "yes" ]]; then
    for _ in $(seq 1 30); do
        if getent hosts discord.com >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done
    if ! getent hosts discord.com >/dev/null 2>&1; then
        echo "Timed out waiting for DNS resolution for discord.com" >&2
        exit 1
    fi
fi

python3.11 - <<'PY'
import json
import os
from pathlib import Path

base_path = Path(os.environ["BASE_CONFIG"])
runtime_path = Path(os.environ["RUNTIME_CONFIG"])

data = json.loads(base_path.read_text(encoding="utf-8"))
discord = data.setdefault("channels", {}).setdefault("discord", {})
discord["token"] = os.environ.get("NANOBOT_DISCORD_TOKEN", "").strip()

runtime_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
runtime_path.chmod(0o600)
PY

exec "${HOME}/.local/bin/nanobot" gateway --config "${RUNTIME_CONFIG}"
EOF
chmod 700 "$GATEWAY_LAUNCHER"
success "Gateway launcher written to ${GATEWAY_LAUNCHER}"

# Create a health check for runtime verification and GPU recovery triage.
HEALTH_CHECK="$HOME/.local/bin/nanobot-health-check"
cat > "$HEALTH_CHECK" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${NANOBOT_CONFIG:-${HOME}/.nanobot/config.json}"
WORKSPACE_PATH="${NANOBOT_WORKSPACE:-${HOME}/.nanobot/workspace}"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
GATEWAY_ENV_PATH="${NANOBOT_GATEWAY_ENV:-${HOME}/.config/nanobot/gateway.env}"
RUNTIME_CONFIG_PATH="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/nanobot/gateway-config.json"

status=0

ok()
{
    printf '[OK] %s\n' "$*"
}

warn()
{
    printf '[WARN] %s\n' "$*" >&2
}

fail()
{
    printf '[FAIL] %s\n' "$*" >&2
    status=1
}

need_command()
{
    if ! command -v "$1" >/dev/null 2>&1; then
        fail "Missing command: $1"
        return 1
    fi
}

need_command curl || true
need_command python3.11 || true
need_command systemctl || true

if [[ ! -f "${CONFIG_PATH}" ]]; then
    fail "Missing nanobot config: ${CONFIG_PATH}"
    exit "${status}"
fi

model_tag="$(python3.11 - "${CONFIG_PATH}" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
data = json.loads(config_path.read_text(encoding="utf-8"))
print(data.get("agents", {}).get("defaults", {}).get("model", ""))
PY
)"

if [[ -z "${model_tag}" ]]; then
    fail "No agents.defaults.model configured in ${CONFIG_PATH}"
else
    ok "Configured model: ${model_tag}"
fi

if python3.11 -m json.tool "${CONFIG_PATH}" >/dev/null; then
    ok "Config JSON is valid"
else
    fail "Config JSON is invalid: ${CONFIG_PATH}"
fi

if curl -fsS "${OLLAMA_URL}/api/tags" >/dev/null; then
    ok "Ollama API reachable at ${OLLAMA_URL}"
else
    fail "Ollama API is not reachable at ${OLLAMA_URL}"
fi

if [[ -n "${model_tag}" ]] && command -v curl >/dev/null 2>&1; then
    chat_payload="$(python3.11 - "${model_tag}" <<'PY'
import json
import sys

print(json.dumps({
    "model": sys.argv[1],
    "messages": [{"role": "user", "content": "Reply exactly OK"}],
    "stream": False,
    "max_tokens": 8,
}))
PY
)"
    if curl -fsS "${OLLAMA_URL}/v1/chat/completions" \
        -H 'Content-Type: application/json' \
        -d "${chat_payload}" >/dev/null; then
        ok "Ollama completion request succeeded"
    else
        fail "Ollama completion request failed for ${model_tag}"
    fi

    ps_json="$(curl -fsS "${OLLAMA_URL}/api/ps" 2>/dev/null || true)"
    if [[ -n "${ps_json}" ]]; then
        size_vram_bytes="$(python3.11 - "${ps_json}" "${model_tag}" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
model_tag = sys.argv[2]
for model in data.get("models", []):
    if model.get("name") == model_tag or model.get("model") == model_tag:
        size_vram_bytes = int(model.get("size_vram") or 0)
        print(size_vram_bytes)
        raise SystemExit(0)
print(0)
PY
)"
        if [[ "${size_vram_bytes}" =~ ^[0-9]+$ ]] && (( size_vram_bytes > 0 )); then
            ok "Ollama model is loaded in VRAM (${size_vram_bytes} bytes)"
        else
            fail "Ollama model is not GPU-backed; check /dev/nvidia-uvm and Ollama logs"
        fi
    else
        fail "Could not read Ollama /api/ps"
    fi
fi

if [[ -e /dev/nvidia-uvm ]]; then
    if python3.11 - <<'PY'
import os

fd = os.open("/dev/nvidia-uvm", os.O_RDWR)
os.close(fd)
PY
    then
        ok "/dev/nvidia-uvm opens for CUDA compute"
    else
        fail "/dev/nvidia-uvm returned an error; reload nvidia_uvm or reboot"
    fi
else
    warn "/dev/nvidia-uvm is absent; this is only acceptable on CPU-only hosts"
fi

if systemctl --user list-unit-files nanobot-gateway.service >/dev/null 2>&1; then
    if systemctl --user is-active --quiet nanobot-gateway.service; then
        ok "nanobot-gateway service is active"
    else
        fail "nanobot-gateway service is not active"
    fi
else
    warn "nanobot-gateway service is not installed for this user"
fi

discord_enabled="$(python3.11 - "${CONFIG_PATH}" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print("yes" if data.get("channels", {}).get("discord", {}).get("enabled") else "no")
PY
)"

if [[ "${discord_enabled}" == "yes" ]]; then
    if [[ -f "${GATEWAY_ENV_PATH}" ]] && python3.11 - "${GATEWAY_ENV_PATH}" <<'PY'
import sys
from pathlib import Path

for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    key, separator, value = line.partition("=")
    if key == "NANOBOT_DISCORD_TOKEN" and separator and value.strip():
        raise SystemExit(0)
raise SystemExit(1)
PY
    then
        ok "Discord token is present in gateway env file"
    else
        fail "Discord is enabled, but ${GATEWAY_ENV_PATH} has no NANOBOT_DISCORD_TOKEN"
    fi

    if [[ -f "${RUNTIME_CONFIG_PATH}" ]] && python3.11 - "${RUNTIME_CONFIG_PATH}" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
token = data.get("channels", {}).get("discord", {}).get("token", "")
raise SystemExit(0 if token else 1)
PY
    then
        ok "Runtime gateway config has Discord token injected"
    else
        warn "Runtime gateway config is missing or has no injected Discord token"
    fi
fi

mkdir -p "${WORKSPACE_PATH}"
workspace_probe_path="${WORKSPACE_PATH}/.nanobot-health-check.tmp"
if : > "${workspace_probe_path}" && rm -f "${workspace_probe_path}"; then
    ok "Workspace is writable: ${WORKSPACE_PATH}"
else
    fail "Workspace is not writable: ${WORKSPACE_PATH}"
fi

mcp_roots="$(python3.11 - "${CONFIG_PATH}" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
for server in data.get("tools", {}).get("mcpServers", {}).values():
    args = server.get("args", [])
    if server.get("command") == "npx" and args:
        root = args[-1]
        if root.startswith("/"):
            print(root)
PY
)"

if [[ -n "${mcp_roots}" ]]; then
    while IFS= read -r mcp_root_path; do
        if [[ -d "${mcp_root_path}" ]]; then
            ok "MCP filesystem root exists: ${mcp_root_path}"
        else
            fail "MCP filesystem root does not exist: ${mcp_root_path}"
        fi
    done <<< "${mcp_roots}"
else
    warn "No MCP filesystem root configured"
fi

exit "${status}"
EOF
chmod 700 "$HEALTH_CHECK"
success "Health check written to ${HEALTH_CHECK}"

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

    # Build GPU environment variables
    GPU_ENV=""
    case "$GPU_CONFIG" in
        nvidia)
            GPU_ENV=$'Environment=CUDA_VISIBLE_DEVICES=0\nEnvironment=OLLAMA_NUM_PARALLEL=4'
            info "GPU: NVIDIA CUDA (forcing CUDA_VISIBLE_DEVICES=0)"
            ;;
        amd)
            GPU_ENV=$'Environment=OLLAMA_NUM_PARALLEL=4'
            info "GPU: AMD ROCm (ROCm auto-detection enabled)"
            ;;
        intel)
            GPU_ENV=$'Environment=OLLAMA_NUM_PARALLEL=4'
            info "GPU: Intel Arc (Intel GPU support enabled)"
            ;;
        metal)
            GPU_ENV=$'Environment=OLLAMA_NUM_PARALLEL=4'
            info "GPU: Apple Metal (macOS GPU support enabled)"
            ;;
        cpu)
            GPU_ENV=$'Environment=OLLAMA_NUM_GPU=0'
            info "GPU: CPU only (GPU acceleration disabled)"
            ;;
        *)
            info "GPU: Auto-detection (Ollama will detect automatically)"
            ;;
    esac

    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Nanobot Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${GATEWAY_LAUNCHER}
Restart=always
RestartSec=10
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=${HOME}/.nanobot
Environment=HOME=${HOME}
Environment=PATH=${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin
Environment=NPM_CONFIG_CACHE=${HOME}/.nanobot/npm-cache
${GPU_ENV}
EnvironmentFile=-${GATEWAY_ENV_FILE}
WorkingDirectory=${HOME}/.nanobot/workspace

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
success "Health check: ${HEALTH_CHECK}"

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
[[ -n "$DISCORD_TOKEN" ]]      && echo -e "  ${BOLD}Discord:${NC}    ${GREEN}enabled${NC}"                    || echo -e "  ${BOLD}Discord:${NC}    ${YELLOW}disabled${NC}"
[[ -n "$MCP_WORKSPACE_PATH" ]] && echo -e "  ${BOLD}MCP path:${NC}   ${CYAN}${MCP_WORKSPACE_PATH}${NC}"      || echo -e "  ${BOLD}MCP:${NC}        ${YELLOW}not configured${NC}"
[[ "$SETUP_SYSTEMD" == true ]] && echo -e "  ${BOLD}Service:${NC}    ${GREEN}nanobot-gateway (systemd)${NC}"  || echo -e "  ${BOLD}Service:${NC}    ${YELLOW}not installed${NC}"

# GPU summary
case "$GPU_CONFIG" in
    nvidia) echo -e "  ${BOLD}GPU:${NC}         ${GREEN}NVIDIA CUDA${NC}" ;;
    amd)    echo -e "  ${BOLD}GPU:${NC}         ${GREEN}AMD ROCm${NC}" ;;
    intel)  echo -e "  ${BOLD}GPU:${NC}         ${GREEN}Intel Arc${NC}" ;;
    cpu)    echo -e "  ${BOLD}GPU:${NC}         ${YELLOW}CPU only${NC}" ;;
    *)      echo -e "  ${BOLD}GPU:${NC}         ${YELLOW}auto-detect${NC}" ;;
esac
echo ""
echo -e "${BOLD}Commands:${NC}"
echo -e "  ${YELLOW}nanobot agent${NC}                           # interactive CLI"
echo -e "  ${YELLOW}nanobot agent -m \"hello\"${NC}                # one-shot"
echo -e "  ${YELLOW}nanobot gateway${NC}                         # foreground gateway"
echo -e "  ${YELLOW}nanobot serve${NC}                           # local OpenAI-compatible API"
echo -e "  ${YELLOW}nanobot-health-check${NC}                    # verify Ollama, GPU, gateway, and workspace"
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
if [[ -z "$DISCORD_TOKEN" ]]; then
    echo -e "${YELLOW}Tip:${NC} Add Discord later:"
    echo -e "  1. Create bot at ${CYAN}discord.com/developers/applications${NC}"
    echo -e "  2. Edit config → set ${CYAN}channels.discord.enabled=true${NC}"
    echo -e "  3. Add ${CYAN}NANOBOT_DISCORD_TOKEN=<token>${NC} to ${CYAN}${GATEWAY_ENV_FILE}${NC}"
    if [[ "$SETUP_SYSTEMD" == true ]]; then
    echo -e "  4. ${YELLOW}systemctl --user restart nanobot-gateway${NC}"
    fi
    echo ""
fi
