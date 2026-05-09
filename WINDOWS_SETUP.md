# nanobot Windows 10/11 Installation Guide

Complete, automated installation of **nanobot**, **Ollama**, and all dependencies on Windows 10/11.

## 📋 Prerequisites

- **Windows 10 (build 19041+) or Windows 11**
- **Administrator privileges** (to install Chocolatey and system packages)
- **RAM**: 4GB minimum (8GB+ recommended for larger models)
- **Disk Space**: 20GB+ (model sizes range from 1–10GB)
- **Network**: Access to download dependencies and models

## 🚀 Quick Start

### 1. Download the Installer

Download both files to your computer:
- `install_nanobot.bat` (batch launcher)
- `install_nanobot.ps1` (PowerShell script)

Keep them in the same folder.

### 2. Run the Installer

#### Option A: Using the Batch File (Easiest)
1. Right-click **`install_nanobot.bat`**
2. Select **"Run as administrator"**
3. Follow the prompts

#### Option B: Using PowerShell Directly
1. Right-click **PowerShell** in the Start menu
2. Select **"Run as administrator"**
3. Navigate to the folder containing the scripts:
   ```powershell
   cd "C:\Users\YourUsername\Downloads"  # or wherever you saved them
   ```
4. Run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
   .\install_nanobot.ps1
   ```

### 3. Follow the Setup Prompts

The installer will ask you to configure:

- **Model Selection** — choose from 9 curated models or specify a custom one
- **Brave Search API** (optional) — for live web search capability
- **Discord Bot** (default) — for real-time chat interface
- **MCP Filesystem** (optional) — for scoped file access
- **Auto-start Task** (optional) — run on login automatically

---

## 🎯 What Gets Installed

✅ **Chocolatey** — package manager for Windows  
✅ **Python 3.11+** — via Chocolatey  
✅ **Node.js 20+** — via Chocolatey  
✅ **Git & curl** — system dependencies  
✅ **Ollama** — local inference engine with Windows service  
✅ **nanobot** — AI agent framework  
✅ **Configuration** — fully set up and ready to use  

---

## 🤖 Model Options

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

---

## 📁 Where Files Are Stored

After installation:

| Item | Location |
|------|----------|
| **nanobot config** | `%USERPROFILE%\.nanobot\config.json` |
| **nanobot source** | `%USERPROFILE%\nanobot` |
| **workspace** | `%USERPROFILE%\.nanobot\workspace` |
| **Discord token** | `%APPDATA%\nanobot\gateway.env` |
| **Ollama models** | `%USERPROFILE%\.ollama\models` |

(Note: `%USERPROFILE%` is typically `C:\Users\YourUsername`)

---

## 🚀 Using nanobot After Installation

### Interactive Chat
```powershell
nanobot agent
```

### One-Shot Query
```powershell
nanobot agent -m "What is the capital of France?"
```

### Run the Gateway (Always-On Mode)
```powershell
nanobot gateway
```
Runs the agent loop with Discord integration and health endpoints.

### Local OpenAI-Compatible API
```powershell
nanobot serve
```
Exposes an OpenAI-compatible API on `http://localhost:18789`.

### Auto-Start on Login
If you enabled the Windows Task Scheduler option:
- The `NanobotGateway` task will run automatically on login
- To start it manually: `Start-ScheduledTask -TaskName NanobotGateway`
- To check status: `Get-ScheduledTask -TaskName NanobotGateway`
- To manage it: Open **Task Scheduler** and find it under `\Anthropic\NanobotGateway`

---

## ⚙️ Managing Ollama

Ollama runs as a Windows service after installation.

### Check Service Status
```powershell
Get-Service -Name Ollama | Select Status
```

### Start/Stop Ollama
```powershell
Start-Service -Name Ollama    # Start
Stop-Service -Name Ollama     # Stop
```

### View Ollama Logs
Open the Services app (`services.msc`) and look for "Ollama" — right-click and select Properties to view details.

### Pull Additional Models
```powershell
ollama pull mistral:7b
ollama pull llama3.1:70b
```

Then update `%USERPROFILE%\.nanobot\config.json` to change the default model.

---

## 🔧 Configuration & Customization

### Edit the Config
Open `%USERPROFILE%\.nanobot\config.json` in your preferred text editor (Notepad, VS Code, etc.).

You can modify:
- **Default model** — change `agents.defaults.model`
- **Temperature** — adjust reasoning creativity (0.0–2.0)
- **Max tokens** — control response length
- **Discord** — enable/disable and set token/channel ID
- **Brave Search API** — add your key later
- **MCP servers** — add or modify scoped file access

### Restart nanobot After Config Changes
If you set up auto-start, restart the service:
```powershell
Stop-ScheduledTask -TaskName NanobotGateway
Start-ScheduledTask -TaskName NanobotGateway
```

Or if running in foreground, press **Ctrl+C** and re-run the command.

---

## 🌐 Optional Features

### Brave Search (Web Access)
1. Get a **free API key** at [brave.com/search/api](https://brave.com/search/api) (1,000 queries/month)
2. Edit `%USERPROFILE%\.nanobot\config.json`
3. Find `tools.web.search.apiKey` and paste your key
4. Restart nanobot

### Discord Bot (Chat Interface)
1. Create a bot at [discord.com/developers/applications](https://discord.com/developers/applications) — copy the **token**
2. Right-click your Discord channel and copy the **Channel ID**
3. Edit `%USERPROFILE%\.nanobot\config.json`:
   - Set `channels.discord.enabled` to `true`
   - Set `channels.discord.channelId` to `"your_channel_id"`
4. Edit `%APPDATA%\nanobot\gateway.env` and add/update:
   ```
   NANOBOT_DISCORD_TOKEN=your_bot_token
   ```
5. Restart nanobot

Your bot will be available for real-time chat immediately. See [DISCORD_SETUP.md](DISCORD_SETUP.md) for detailed instructions.

### MCP Filesystem Server
If you skipped this during installation, you can add it later:

1. Create a folder for nanobot to access (e.g., `C:\Users\YourUsername\nanobot-workspace`)
2. Edit `%USERPROFILE%\.nanobot\config.json`
3. Find the `mcpServers` section and replace `{}` with:
   ```json
   {
     "filesystem": {
       "command": "npx",
       "args": ["-y", "@modelcontextprotocol/server-filesystem", "C:\\Users\\YourUsername\\nanobot-workspace"]
     }
   }
   ```
4. Restart nanobot

---

## 🔍 Troubleshooting

### "Admin rights required" error
Right-click the batch file and select **"Run as administrator"** explicitly. You must have admin privileges to install Chocolatey and system packages.

### Ollama service not starting
1. Open Services (`services.msc`)
2. Find "Ollama" in the list
3. Right-click → **Start**
4. If it fails, check the Event Viewer for errors

### Python or Node.js not found after installation
1. Close and reopen PowerShell (to refresh PATH)
2. Verify installation:
   ```powershell
   python --version
   node --version
   ```
3. If still missing, try manual installation:
   - Python: [python.org](https://www.python.org)
   - Node.js: [nodejs.org](https://www.nodejs.org)

### "nanobot" command not found
The Python package may not be on your PATH. Try:
```powershell
python -m pip install --user --upgrade C:\Users\YourUsername\nanobot
```

### Ollama not responding at localhost:11434
1. Ensure the service is running: `Get-Service -Name Ollama`
2. Restart Ollama: `Restart-Service -Name Ollama`
3. Check Windows Firewall isn't blocking it:
   - Open **Windows Defender Firewall** → **Allow an app through firewall**
   - Look for "Ollama" and ensure it's checked

### Model pulling takes forever
- This is normal for large models (7B+ can take 10+ minutes)
- Models are cached locally in `%USERPROFILE%\.ollama\models` after first pull
- Check your internet connection speed

### Task Scheduler auto-start not working
1. Open **Task Scheduler**
2. Navigate to `\Anthropic\NanobotGateway`
3. Right-click the task → **Properties**
4. Check **"Run with highest privileges"** is checked
5. Under **Triggers**, verify "At log on" is present

---

## 📚 Resources

- **nanobot Repository**: [github.com/HKUDS/nanobot](https://github.com/HKUDS/nanobot)
- **Ollama**: [ollama.com](https://ollama.com)
- **Ollama Models**: [ollama.com/library](https://ollama.com/library)
- **Model Context Protocol**: [modelcontextprotocol.io](https://modelcontextprotocol.io)
- **Brave Search API**: [brave.com/search/api](https://brave.com/search/api)

---

## 🚨 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Script won't run as admin | Right-click `.bat` → Run as administrator |
| Chocolatey install fails | Check firewall; try `choco upgrade -y` manually |
| Model download stuck | Restart Ollama service or check internet |
| nanobot gateway won't stay running | Check logs in the task; ensure Ollama is running |
| High CPU/memory usage | It's normal while models load; use smaller models if constrained |

---

## 🔧 Advanced: Manual Component Installation

If the automated installer fails, you can install components manually:

### 1. Install Chocolatey (Admin PowerShell)
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### 2. Install Dependencies
```powershell
choco install -y python nodejs git curl
```

### 3. Download & Install Ollama
- Visit [ollama.com/download](https://ollama.com/download)
- Download the Windows installer
- Run it

### 4. Clone & Install nanobot
```powershell
git clone https://github.com/HKUDS/nanobot.git C:\Users\YourUsername\nanobot
python -m pip install --user --upgrade C:\Users\YourUsername\nanobot
```

### 5. Initialize Workspace
```powershell
nanobot onboard
```

---

## 📝 License

This installer script is provided as-is. nanobot itself is governed by its own license — see the [nanobot repository](https://github.com/HKUDS/nanobot) for details.

---

**Questions?** Check the [nanobot docs](https://github.com/HKUDS/nanobot) or open an issue on GitHub.
