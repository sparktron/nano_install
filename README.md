# nano_install

A complete, automated installation and configuration script for **nanobot** — an open-source AI agent framework for building intelligent, multi-tool applications with local LLMs.

## 🎯 What is nanobot?

**nanobot** is a TypeScript/Python agent framework that enables you to build AI applications with:
- **Local LLM support** via Ollama (Llama, Mistral, Qwen, Phi, Deepseek, Gemma, and more)
- **Multi-channel interfaces** (CLI, Telegram, HTTP gateway)
- **Tool ecosystem** (web search, filesystem access, custom tools)
- **Agent scaffolding** with AGENT.md, SOUL.md, and memory management
- **Model Context Protocol (MCP)** integrations for secure, scoped access

This installer streamlines the entire setup process for you.

---

## 💻 Platform Support

- **Linux/macOS**: `bash install_nanobot.sh`
- **Windows 10/11**: See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) — fully automated PowerShell + batch installer with Chocolatey

👉 **Windows users**: [Quick Windows installation guide →](WINDOWS_SETUP.md)

---

## ✨ What This Installer Does

The `install_nanobot.sh` script automates the complete nanobot stack:

✅ **Runtime Setup**
- Python 3.11+ (via deadsnakes PPA if needed)
- Node.js 20+ (via NodeSource)
- git, curl (system dependencies)

✅ **Ollama Integration**
- Installs Ollama (local inference engine)
- Pulls your chosen LLM from a curated menu
- Starts the Ollama service

✅ **nanobot Framework**
- Clones from HKUDS/nanobot repository
- Installs the latest local package without leaving the runtime tied to an editable checkout
- Initializes workspace (AGENT.md, SOUL.md, memory)

✅ **Features & Integrations**
- **Brave Search** — live web search (optional, free tier available)
- **Telegram** — real-time chat interface (optional)
- **MCP Filesystem Server** — scoped file access (optional)
- **systemd user service** — auto-start on login/reboot with DNS preflight and tighter filesystem scope (optional)
- **Health check command** — verifies Ollama, GPU offload, gateway status, Telegram token injection, and workspace write access

---

## 📋 Prerequisites

- **OS**: Ubuntu 20.04+ (or any Debian-based system)
- **RAM**: 4GB minimum (8GB+ recommended for larger models)
- **Disk**: 20GB+ (model sizes range from 1–10GB)
- **Non-root user** with `sudo` access
- **Network access** to download models and dependencies

---

## 🚀 Quick Start

### 1. Clone This Repo
```bash
git clone https://github.com/your-username/nano_install.git
cd nano_install
```

### 2. Run the Installer
```bash
bash install_nanobot.sh
```

The script is **interactive** — you'll be prompted for:
- **Model selection** (choose from 9 curated models or enter a custom tag)
- **Brave Search API** (optional; get free key at brave.com/search/api)
- **Telegram bot** (optional; set up via @BotFather)
- **MCP filesystem** (optional; defaults to `~/.nanobot/workspace`)
- **systemd service** (optional; auto-start on login)

### 3. Start Using nanobot
Once installation completes, you can:

**Interactive CLI**
```bash
nanobot agent
```

**One-shot query**
```bash
nanobot agent -m "What is the weather in San Francisco?"
```

**Start the gateway** (runs the always-on agent loop, Telegram integration, and local health endpoint)
```bash
nanobot gateway
```

**Start the local OpenAI-compatible API**
```bash
nanobot serve
```

---

## 🤖 Model Options

The installer includes these pre-configured models:

| Model | Size | Speed | Best For |
|-------|------|-------|----------|
| **Llama 3.2 3B** | 2.0 GB | ⚡⚡⚡ | Fast, general-purpose tasks |
| **Llama 3.2 1B** | 1.3 GB | ⚡⚡⚡⚡ | Ultra-lightweight, very fast |
| **Llama 3.1 8B** | 4.9 GB | ⚡⚡ | Strong reasoning, tool use |
| **Mistral 7B** | 4.1 GB | ⚡⚡ | Solid all-rounder |
| **Qwen2.5 7B** | 4.7 GB | ⚡⚡ | Great at coding & reasoning |
| **Qwen2.5 3B** | 2.0 GB | ⚡⚡⚡ | Compact, efficient |
| **Phi-4 Mini** | 2.5 GB | ⚡⚡⚡ | Microsoft, strong reasoning |
| **Gemma 3 4B** | 3.3 GB | ⚡⚡ | Google, efficient |
| **DeepSeek-R1 7B** | 4.7 GB | ⚡⚡ | Specialized reasoning model |

You can also manually specify any Ollama-compatible model during installation.

---

## 📝 Configuration

After installation, the config file is located at `~/.nanobot/config.json`. You can edit it anytime to:

- Add/update Brave Search API key
- Enable Telegram later
- Configure MCP servers
- Adjust model parameters (temperature, max tokens)
- Change the gateway health endpoint bind (`gateway.host` / `gateway.port`)
- Change the OpenAI-compatible API bind (`api.host` / `api.port`)

If you enable Telegram, the installer stores the bot token in `~/.config/nanobot/gateway.env` instead of keeping it in the main JSON config.

**Restart the service after config changes:**
```bash
systemctl --user restart nanobot-gateway
```

---

## 🔧 Post-Installation Commands

### nanobot CLI
```bash
nanobot agent                          # Interactive chat mode
nanobot agent -m "question here"       # Single message
nanobot onboard                        # Re-initialize workspace
nanobot serve                          # OpenAI-compatible local API
nanobot-health-check                   # Verify runtime health
```

### Gateway Mode (Agent Loop + Telegram + Health)
```bash
nanobot gateway                        # Foreground (Ctrl+C to stop)
```

### systemd Service (if enabled)
```bash
systemctl --user status nanobot-gateway
systemctl --user restart nanobot-gateway
systemctl --user stop nanobot-gateway
journalctl --user -u nanobot-gateway -f  # Stream logs
```

### Ollama
```bash
ollama serve                           # Start Ollama service (if not running)
ollama list                            # See pulled models
ollama pull <model-tag>                # Pull another model
```

---

## Operational Policy

### Health Check First

Run the health check after installs, reboots, driver updates, Ollama updates, or nanobot config changes:

```bash
nanobot-health-check
```

It checks:
- nanobot config JSON validity
- Ollama API reachability
- a real completion against the configured model
- nonzero Ollama `size_vram`, which confirms GPU offload
- `/dev/nvidia-uvm`, which CUDA compute needs even when `nvidia-smi` works
- `nanobot-gateway` systemd status
- Telegram token injection without printing the token
- workspace writability

### Tool Access

The default config keeps shell execution enabled because it is useful for local automation, but it also sets `tools.restrictToWorkspace=true`. Treat shell access as an operational tool, not a general chat feature.

Recommended defaults:
- Keep the nanobot workspace at `~/.nanobot/workspace`.
- Put reusable safe operations in scripts such as `nanobot-health-check` instead of asking the agent to invent shell commands repeatedly.
- Disable `tools.exec.enable` if you only want chat/search behavior and do not need local shell automation.
- Keep `tools.ssrfWhitelist` empty unless you have a specific local service that nanobot must call.

### OpenAI-Compatible API

`nanobot serve` is optional. Leave `nanobot-api.service` disabled unless another local application needs the OpenAI-compatible API. If you do enable it, keep `api.host` bound to `127.0.0.1`.

### Ollama Runtime

Keep Ollama overrides minimal unless measurement shows a real bottleneck:

```ini
Environment="OLLAMA_HOST=127.0.0.1:11434"
Environment="OLLAMA_NO_CLOUD=1"
Environment="OLLAMA_KEEP_ALIVE=30m"
```

Do not force aggressive model scheduling or CUDA library settings by default. First verify that the configured model is GPU-backed with `nanobot-health-check`.

To inspect the live service override:

```bash
systemctl cat ollama
```

If a previous troubleshooting session left forced CUDA settings in the override, remove those lines with:

```bash
sudo systemctl edit ollama
sudo systemctl daemon-reload
sudo systemctl restart ollama
nanobot-health-check
```

---

## 🌐 Optional Features

### Brave Search (Web Access)
1. Get a **free API key** at [brave.com/search/api](https://brave.com/search/api) (1,000 queries/month)
2. During installation, provide your key when prompted
3. Or edit `~/.nanobot/config.json` and set `tools.web.search.apiKey`

### Telegram Bot (Chat Interface)
1. Create a bot via [@BotFather](https://t.me/BotFather) — get the **token**
2. Get your numeric user ID via [@userinfobot](https://t.me/userinfobot)
3. During installation, provide both when prompted
4. Or edit config and set `channels.telegram.enabled`
5. Store the token in `~/.config/nanobot/gateway.env` as `NANOBOT_TELEGRAM_TOKEN=...`

Your bot will be available immediately for real-time chat.

### MCP Filesystem Server
Enables nanobot to safely access files within a scoped directory:
1. During installation, accept the default `~/.nanobot/workspace` path or specify a narrow project directory.
2. nanobot will have read/write access only to that directory
3. Useful for content generation, analysis, and automation tasks

---

## 🔌 Post-Installation: Setting Up MCP Filesystem

If you skipped MCP configuration during installation, or want to modify it afterward, follow these steps:

### 1. Verify Current MCP Configuration
Check what's currently configured:
```bash
cat ~/.nanobot/config.json | grep -A 10 mcpServers
```

If `mcpServers` is `{}`, no MCP filesystem server is configured.

### 2. Edit the Config File
Open the config file in your editor:
```bash
nano ~/.nanobot/config.json
```

### 3. Add or Update the MCP Filesystem Server

Find the `tools` section and add the `mcpServers` block. Here's the structure:

```json
{
  "tools": {
    "web": { "search": { "apiKey": "your-brave-key", "maxResults": 5 } },
    "mcpServers": {
      "filesystem": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/workspace"]
      }
    }
  }
}
```

**Replace `/path/to/workspace`** with the narrow directory you want nanobot to access. Prefer `~/.nanobot/workspace` or one project directory over your whole home directory.

### 4. Restart the Service
If using systemd:
```bash
systemctl --user restart nanobot-gateway
```

Or if running in foreground, stop the current process and restart:
```bash
nanobot gateway
```

### 5. Verify MCP is Working
Check the logs for errors:
```bash
journalctl --user -u nanobot-gateway -n 20
```

You should see no errors related to MCP server startup. Test by asking nanobot to list or read files:
```bash
nanobot agent -m "List the files in my workspace directory"
```

### Multiple MCP Servers (Advanced)

You can configure multiple MCP servers for different purposes, but keep each one narrow. For example:

```json
{
  "tools": {
    "web": { "search": { "apiKey": "...", "maxResults": 5 } },
    "mcpServers": {
      "projects": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "~/projects"]
      },
      "documents": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "~/documents"]
      },
      "data": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "/mnt/data"]
      }
    }
  }
}
```

Each server runs independently with its own scoped directory. nanobot can access all of them.

### Security Notes

- **Scope is enforced**: The MCP filesystem server only has access to the specified directory and its subdirectories. It cannot access parent directories or anywhere else on the system.
- **Read/Write access**: By default, nanobot can both read and write files. If you need read-only access, configure a restricted user or mount with read-only permissions.
- **Never expose the home directory carelessly**: If nanobot misbehaves or is compromised, limiting its scope to a specific project directory reduces risk.
- **Use one scope first**: Add more MCP roots only when a specific workflow needs them.

---

## 🐛 Troubleshooting

### Run the health check
```bash
nanobot-health-check
```

Start here before changing config. The command verifies the full local path from nanobot config to Ollama GPU-backed inference.

### "ollama not found" or Ollama API not responding
```bash
# Start Ollama in the background (or in another terminal)
ollama serve
```

### Model pulling is slow
- Check your internet connection
- Large models (7B+) can take 10+ minutes on slower connections
- Models are cached in `~/.ollama/models` after first pull

### Ollama replies, but `size_vram` is `0`
`size_vram: 0` means the model is running on CPU. On NVIDIA systems, check CUDA UVM first:

```bash
python3 - <<'PY'
import os
fd = os.open("/dev/nvidia-uvm", os.O_RDWR)
os.close(fd)
print("nvidia-uvm OK")
PY
```

If that returns `Input/output error`, reload UVM and restart Ollama:

```bash
sudo systemctl stop ollama
sudo rmmod nvidia_uvm
sudo modprobe nvidia_uvm
sudo systemctl restart ollama
nanobot-health-check
```

If `rmmod` fails or UVM still errors, reboot. If it persists after reboot, repair the NVIDIA driver stack before tuning Ollama.

### "nanobot" command not found
```bash
# Reinstall the Python package
python3.11 -m pip install --user --upgrade ~/nanobot
```

### Telegram not working
1. Ensure your bot token and user ID are correct
2. Check config: `cat ~/.nanobot/config.json`
3. Restart gateway: `systemctl --user restart nanobot-gateway`
4. View logs: `journalctl --user -u nanobot-gateway -f`

### systemd service won't start
```bash
# Check service status and logs
systemctl --user status nanobot-gateway
journalctl --user -u nanobot-gateway --no-pager -n 50

# If issues persist, run nanobot manually
nanobot gateway  # to test in foreground
```

### Optional API service
If you installed `nanobot-api.service`, keep it disabled unless needed:

```bash
systemctl --user is-enabled nanobot-api
systemctl --user is-active nanobot-api
```

Enable it only for local clients that need `nanobot serve`.

### Performance tuning
Keep the selected model, `contextWindowTokens: 4096`, and `maxTokens: 1024` as the stable baseline until you have measured latency, VRAM pressure, or response quality problems. GPU offload matters more than small scheduling tweaks.

---

## 📚 Resources

- **nanobot Repository**: [github.com/HKUDS/nanobot](https://github.com/HKUDS/nanobot)
- **Ollama Models**: [ollama.com/library](https://ollama.com/library)
- **Model Context Protocol**: [modelcontextprotocol.io](https://modelcontextprotocol.io)
- **Brave Search API**: [brave.com/search/api](https://brave.com/search/api)

---

## 🛠️ Advanced Usage

### Custom Model
During installation, select "Enter a custom model tag manually" and specify any Ollama-compatible model:
```
deepseek-coder:33b
neural-chat:7b-v3.3
orca-mini:7b
```

### Multiple Models
Pull additional models anytime:
```bash
ollama pull mistral:7b
ollama pull llama3.1:70b
```

Then update `~/.nanobot/config.json` to switch the default agent model.

### Custom Tools
nanobot supports adding custom tools. See the [nanobot docs](https://github.com/HKUDS/nanobot) for extending agent capabilities.

---

## 📝 License

This installer script is provided as-is. nanobot itself is governed by its own license — see the [nanobot repository](https://github.com/HKUDS/nanobot) for details.

---

## 🤝 Contributing

Found a bug? Want to improve the installer? Submit a PR or open an issue!

---

**Questions?** Check the [nanobot docs](https://github.com/HKUDS/nanobot) or post an issue here.
