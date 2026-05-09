# Installation Defaults Guide

Both the **Linux/macOS** and **Windows** installers now have smart defaults for users who are unsure what to choose.

## Default Behavior

### 🎯 Model Selection
- **Default**: Llama 3.2 3B (marked as **RECOMMENDED**)
- **Why**: 2.0 GB, fast, and excellent for general-purpose AI tasks
- **Action**: Just press **Enter** to use the default
- **Alternative**: Type a number (1-9) to choose a different model

### 🔍 Brave Search API (Web Search)
- **Default**: **Skip** (can add later)
- **Why**: Requires getting a free API key first
- **Action**: Press **Enter** or type `n` → skipped, you can add it later
- **To enable now**: Type `y` and paste your API key

### 💬 Telegram Bot (Chat Interface)
- **Default**: **Skip** (can add later)
- **Why**: Requires creating a Telegram bot first
- **Action**: Press **Enter** or type `n` → skipped, you can configure later
- **To enable now**: Type `y` and provide your bot token + user ID

### 📁 MCP Filesystem Server
- **Default**: **Yes** (recommended)
- **Why**: Useful for file operations and content generation
- **Path**: `~/.nanobot/workspace` (Windows: `%USERPROFILE%\.nanobot\workspace`)
- **Action**: Press **Enter** to accept default path
- **Custom path**: Type a path and press Enter

### ⚙️ Auto-Start Service
- **Linux/macOS**: **Yes** (systemd service)
- **Windows**: **Yes** (Windows Task Scheduler)
- **Why**: Makes nanobot always available on startup
- **Action**: Press **Enter** to enable, or type `n` to skip

---

## Quick Start for Beginners

If you don't know what to do, just **keep pressing Enter**. The defaults are:

1. **Model**: Llama 3.2 3B (RECOMMENDED) ✓
2. **Brave Search**: Skip for now
3. **Telegram**: Skip for now
4. **MCP Filesystem**: Enable with default path ✓
5. **Auto-start**: Enable ✓

This gives you a fully functional AI agent with file access and automatic startup.

---

## Understanding the Prompts

### Format
```
[?] Question? [Y/n]: 
```

- **`[Y/n]`** = Default is YES (press Enter or type `y`)
- **`[y/N]`** = Default is NO (press Enter or type `n`)
- **Empty prompt** = Just press Enter to accept default

### Examples

#### Model Selection (with default)
```
Enter number [1-10, default: 1]: 
```
→ Just press Enter to select model #1 (Llama 3.2 3B)

#### Yes/No Question (default: NO)
```
Configure Brave Search now? [y/N]: 
```
→ Press Enter = NO (skip Brave Search)
→ Type `y` = YES (set up Brave Search)

#### Yes/No Question (default: YES)
```
Configure MCP filesystem server? [Y/n]: 
```
→ Press Enter = YES (set up MCP)
→ Type `n` = NO (skip MCP)

#### Path Input (with default)
```
Path to expose [default: /home/user/.nanobot/workspace]: 
```
→ Press Enter = use the default path
→ Type a path = use your custom path

---

## Recommended Setup for Different Users

### 🏃 Just Want Something Working?
1. Accept all defaults
2. Press Enter through all prompts
3. Done in 5 minutes

### 💻 Developer / Power User?
1. Default model (Llama 3.2 3B) or pick a larger model
2. Enable MCP filesystem (default: yes)
3. Enable auto-start (default: yes)
4. Add Brave Search later when you have an API key
5. Skip Telegram for now

### 🤖 Want Full Features?
1. Choose model based on your RAM (larger = more capable but slower)
2. Get Brave Search API key now (brave.com/search/api)
3. Create Telegram bot now (@BotFather on Telegram)
4. Enable MCP filesystem (default: yes)
5. Enable auto-start (default: yes)

---

## Adding Features Later

### Add Brave Search After Installation
```bash
# Edit the config file
nano ~/.nanobot/config.json  # Linux/macOS
notepad %USERPROFILE%\.nanobot\config.json  # Windows
```
Find `tools.web.search.apiKey` and paste your key.

### Add Telegram After Installation
```bash
# Edit the config file (same as above)
# Set channels.telegram.enabled = true
# Set channels.telegram.allowFrom = ["your_user_id"]

# Edit the environment file
nano ~/.config/nanobot/gateway.env  # Linux/macOS
notepad %APPDATA%\nanobot\gateway.env  # Windows
# Add: NANOBOT_TELEGRAM_TOKEN=your_bot_token
```

### Add MCP Filesystem After Installation
Edit `config.json` and add the MCP server block in the `tools` section.

---

## What the Defaults Install

| Component | Included | Optional | Added Later? |
|-----------|----------|----------|--------------|
| Python 3.11+ | ✅ | — | No |
| Node.js 20+ | ✅ | — | No |
| Ollama | ✅ | — | No |
| Llama 3.2 3B model | ✅ | Different model | No |
| nanobot package | ✅ | — | No |
| MCP Filesystem | ✅ (default) | Skip | Yes |
| Auto-start service | ✅ (default) | Skip | Yes |
| Brave Search | — | ✅ (optional) | **Yes** |
| Telegram | — | ✅ (optional) | **Yes** |

---

## Troubleshooting Defaults

### "I don't want auto-start"
When asked, type `n` instead of pressing Enter.

### "I want a different model"
Type the model number (2-10) instead of pressing Enter.

### "I want to add Brave Search now"
When asked, type `y` and paste your API key from brave.com/search/api.

### "I want to skip MCP filesystem"
Type `n` instead of pressing Enter when asked.

### "I made a mistake, can I change this?"
Yes! Edit `~/.nanobot/config.json` (or `%USERPROFILE%\.nanobot\config.json` on Windows) and change any settings.

---

## Default Paths

| Item | Location |
|------|----------|
| **Configuration** | `~/.nanobot/config.json` |
| **Workspace** | `~/.nanobot/workspace` |
| **Telegram token** | `~/.config/nanobot/gateway.env` |
| **Ollama models** | `~/.ollama/models` |
| **Service** | systemd user service (Linux/macOS) or Windows Task Scheduler |

Windows paths use `%USERPROFILE%` instead of `~`.

---

## Getting Help

- **Questions?** See [WINDOWS_SETUP.md](WINDOWS_SETUP.md) (Windows) or the main [README.md](README.md) (Linux/macOS)
- **Issues?** Check the Troubleshooting section
- **nanobot docs**: [github.com/HKUDS/nanobot](https://github.com/HKUDS/nanobot)
