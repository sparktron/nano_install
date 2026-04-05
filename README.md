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
- Installs Python dependencies
- Initializes workspace (AGENT.md, SOUL.md, memory)

✅ **Features & Integrations**
- **Brave Search** — live web search (optional, free tier available)
- **Telegram** — real-time chat interface (optional)
- **MCP Filesystem Server** — scoped file access (optional)
- **systemd user service** — auto-start on login/reboot (optional)

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
- **MCP filesystem** (optional; choose a workspace path)
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

**Start the gateway** (runs HTTP + Telegram interface)
```bash
nanobot gateway
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
- Change gateway host/port

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
```

### Gateway Mode (HTTP + Telegram)
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

## 🌐 Optional Features

### Brave Search (Web Access)
1. Get a **free API key** at [brave.com/search/api](https://brave.com/search/api) (1,000 queries/month)
2. During installation, provide your key when prompted
3. Or edit `~/.nanobot/config.json` and set `tools.web.search.apiKey`

### Telegram Bot (Chat Interface)
1. Create a bot via [@BotFather](https://t.me/BotFather) — get the **token**
2. Get your numeric user ID via [@userinfobot](https://t.me/userinfobot)
3. During installation, provide both when prompted
4. Or edit config and set `channels.telegram.enabled` + credentials

Your bot will be available immediately for real-time chat.

### MCP Filesystem Server
Enables nanobot to safely access files within a scoped directory:
1. During installation, specify a workspace path (e.g., `~/projects`)
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

If the output is empty or doesn't show `mcpServers`, you'll need to add it.

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

**Replace `/path/to/workspace`** with the directory you want nanobot to access (e.g., `~/projects`, `~/documents`, or `/home/user/data`).

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

You can configure multiple MCP servers for different purposes. For example:

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

---

## 🐛 Troubleshooting

### "ollama not found" or Ollama API not responding
```bash
# Start Ollama in the background (or in another terminal)
ollama serve
```

### Model pulling is slow
- Check your internet connection
- Large models (7B+) can take 10+ minutes on slower connections
- Models are cached in `~/.ollama/models` after first pull

### "nanobot" command not found
```bash
# Reinstall the Python package
python3.11 -m pip install -e ~/nanobot --upgrade
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
