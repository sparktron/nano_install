# Install-Nanobot.ps1 — Full install: ollama + nanobot (HKUDS) + recommended extras for Windows 10/11
# Usage: Open PowerShell as Administrator and run: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; .\install_nanobot.ps1
# Or: PowerShell -ExecutionPolicy Bypass -File install_nanobot.ps1

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Colors ────────────────────────────────────────────────────────────────────
$Colors = @{
    Reset   = "`e[0m"
    Bold    = "`e[1m"
    Cyan    = "`e[36m"
    Green   = "`e[32m"
    Yellow  = "`e[33m"
    Red     = "`e[31m"
}

function Write-Info    { Write-Host "$($Colors.Cyan)[•]$($Colors.Reset) $args" }
function Write-Success { Write-Host "$($Colors.Green)[✓]$($Colors.Reset) $args" }
function Write-Warn    { Write-Host "$($Colors.Yellow)[!]$($Colors.Reset) $args" -ForegroundColor Yellow }
function Write-Die     { Write-Host "$($Colors.Red)[✗]$($Colors.Reset) $args" -ForegroundColor Red; exit 1 }
function Write-Header  { Write-Host "`n$($Colors.Bold)$($Colors.Cyan)── $args ──$($Colors.Reset)" }

# ── Model menu ────────────────────────────────────────────────────────────────
$Models = @(
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

# ── Config state ───────────────────────────────────────────────────────────────
$Config = @{
    ModelTag            = ""
    BraveApiKey         = ""
    TelegramToken       = ""
    TelegramUserId      = ""
    McpWorkspacePath    = ""
    SetupWindowsTask    = $false
    GpuType             = "auto"
}

# ── Helpers ───────────────────────────────────────────────────────────────────
function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Get-PythonCommand {
    foreach ($py in @("python3.13", "python3.12", "python3.11", "python3", "python")) {
        if (Test-CommandExists $py) {
            return $py
        }
    }
    return $null
}

function Invoke-Chocolatey {
    param([string]$Package)
    Write-Info "Installing $Package via Chocolatey..."
    & choco install -y $Package | Out-Null
}

function Prompt-YesNo {
    param(
        [string]$Prompt,
        [bool]$Default = $false
    )
    $defaultStr = if ($Default) { "Y/n" } else { "y/N" }
    while ($true) {
        $response = Read-Host "$($Colors.Yellow)[?]$($Colors.Reset) $Prompt [$defaultStr]"
        if ([string]::IsNullOrWhiteSpace($response)) {
            return $Default
        }
        switch ($response.ToLower()[0]) {
            "y" { return $true }
            "n" { return $false }
            default { Write-Warn "Please answer y or n (or press Enter for default)." }
        }
    }
}

# ── Check admin rights ─────────────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Die "This script must run as Administrator. Please right-click PowerShell and select 'Run as administrator'."
}

Write-Host ""
Write-Host "$($Colors.Bold)$($Colors.Cyan)🐈 nanobot + ollama — Windows installer$($Colors.Reset)"
Write-Host "$($Colors.Cyan)════════════════════════════════════════$($Colors.Reset)"

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 1 — COLLECT ALL INPUTS UPFRONT
# ══════════════════════════════════════════════════════════════════════════════
Write-Header "Configuration"

# ── Model selection ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($Colors.Cyan)Select a model to pull with Ollama:$($Colors.Reset)"
Write-Host ""
for ($i = 0; $i -lt $Models.Count; $i++) {
    $modelName = $Models[$i].Split("|")[0]
    if ($i -eq 0) {
        Write-Host "  {0:D2}) {1} $($Colors.Green)[RECOMMENDED - Fast & Capable]$($Colors.Reset)" -f ($i + 1), $modelName
    } else {
        Write-Host "  {0:D2}) {1}" -f ($i + 1), $modelName
    }
}
Write-Host ""

$choice = Read-Host "Enter number [1-$($Models.Count), default: 1]"
if ([string]::IsNullOrWhiteSpace($choice)) {
    $choice = 1
}

while ($choice -notmatch '^\d+$' -or [int]$choice -lt 1 -or [int]$choice -gt $Models.Count) {
    Write-Warn "Invalid choice. Enter a number between 1 and $($Models.Count)"
    $choice = Read-Host "Enter number [1-$($Models.Count)]"
}

$selected = $Models[[int]$choice - 1]
$Config.ModelTag = $selected.Split("|")[1]

if ($Config.ModelTag -eq "__custom__") {
    $Config.ModelTag = Read-Host "  Enter Ollama model tag (e.g. llama3.1:8b)"
    if ([string]::IsNullOrWhiteSpace($Config.ModelTag)) {
        Write-Die "Model tag cannot be empty."
    }
}
Write-Success "Model: $($Config.ModelTag)"

# ── Brave Search ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($Colors.Cyan)Brave Search API$($Colors.Reset) — enables live web search"
Write-Host "  Free tier: 1,000 queries/month — get a key at $($Colors.Yellow)brave.com/search/api$($Colors.Reset)"
Write-Host ""
Write-Host "  $($Colors.Yellow)[Optional - can add later]$($Colors.Reset)"
Write-Host ""
if (Prompt-YesNo "Configure Brave Search now?" -Default $false) {
    $Config.BraveApiKey = Read-Host "  Brave Search API key"
    $Config.BraveApiKey = $Config.BraveApiKey.Trim()
    if ($Config.BraveApiKey) {
        Write-Success "Brave key captured"
    } else {
        Write-Warn "Blank — web search disabled"
    }
} else {
    Write-Warn "Skipped — you can add Brave Search later"
}

# ── Telegram ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($Colors.Cyan)Telegram channel$($Colors.Reset) — gives nanobot a real UI"
Write-Host "  1. Create a bot via @BotFather → copy the token"
Write-Host "  2. Get your numeric user ID via @userinfobot"
Write-Host "  $($Colors.Yellow)[Optional - requires Telegram bot setup]$($Colors.Reset)"
Write-Host ""
if (Prompt-YesNo "Configure Telegram now?" -Default $false) {
    $Config.TelegramToken = Read-Host "  Bot token"
    $Config.TelegramToken = $Config.TelegramToken.Trim()
    $Config.TelegramUserId = Read-Host "  Your numeric user ID"
    $Config.TelegramUserId = $Config.TelegramUserId.Trim()
    if ($Config.TelegramToken -and $Config.TelegramUserId) {
        Write-Success "Telegram config captured"
    } else {
        Write-Warn "Incomplete — Telegram will not be enabled"
        $Config.TelegramToken = ""
        $Config.TelegramUserId = ""
    }
} else {
    Write-Warn "Skipped — CLI mode only"
}

# ── MCP filesystem server ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($Colors.Cyan)MCP filesystem server$($Colors.Reset) — scoped file access via Model Context Protocol"
Write-Host "  $($Colors.Yellow)[Recommended for file operations]$($Colors.Reset)"
Write-Host ""
if (Prompt-YesNo "Configure MCP filesystem server?" -Default $true) {
    $defaultPath = Join-Path $env:USERPROFILE ".nanobot\workspace"
    $path = Read-Host "  Path to expose [default: $defaultPath]"
    if ([string]::IsNullOrWhiteSpace($path)) {
        $path = $defaultPath
        Write-Host "  Using default: $defaultPath"
    }
    $path = [System.IO.Path]::GetFullPath($path)

    try {
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
        $Config.McpWorkspacePath = $path
        Write-Success "MCP path: $($Config.McpWorkspacePath)"
    } catch {
        Write-Warn "Path could not be created — MCP filesystem will not be configured"
        $Config.McpWorkspacePath = ""
    }
} else {
    Write-Warn "Skipped"
}

# ── GPU Configuration ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($Colors.Cyan)GPU Acceleration$($Colors.Reset) — force Ollama to use GPU (NVIDIA/AMD/Intel)"
Write-Host "  $($Colors.Yellow)[Optional - auto-detection usually works]$($Colors.Reset)"
Write-Host ""
if (Prompt-YesNo "Configure GPU acceleration?" -Default $false) {
    Write-Host ""
    Write-Host "$($Colors.Cyan)Select your GPU type:$($Colors.Reset)"
    Write-Host "  1) NVIDIA CUDA (RTX, GTX, Tesla, L40, etc.)"
    Write-Host "  2) AMD ROCm (Radeon RX, Radeon Pro, etc.)"
    Write-Host "  3) Intel Arc"
    Write-Host "  4) CPU only (no GPU acceleration)"
    Write-Host ""

    while ($true) {
        $gpuChoice = Read-Host "Enter GPU type [1-4, default: auto-detect]"
        if ([string]::IsNullOrWhiteSpace($gpuChoice)) {
            $gpuChoice = "0"
        }
        if ($gpuChoice -match '^\d+$' -and [int]$gpuChoice -ge 0 -and [int]$gpuChoice -le 4) {
            break
        }
        Write-Warn "Invalid choice. Enter 1-4 or press Enter for auto-detect."
    }

    switch ([int]$gpuChoice) {
        1 {
            Write-Info "NVIDIA CUDA selected — will force CUDA acceleration"
            $Config.GpuType = "nvidia"
            Write-Success "NVIDIA CUDA GPU acceleration enabled"
        }
        2 {
            Write-Info "AMD ROCm selected — will force AMD acceleration"
            $Config.GpuType = "amd"
            Write-Success "AMD ROCm GPU acceleration enabled"
        }
        3 {
            Write-Info "Intel Arc selected — will use Intel GPU"
            $Config.GpuType = "intel"
            Write-Success "Intel Arc GPU acceleration enabled"
        }
        4 {
            Write-Info "CPU only mode — no GPU acceleration"
            $Config.GpuType = "cpu"
            Write-Success "CPU-only mode (GPU disabled)"
        }
        default {
            Write-Info "Auto-detection enabled"
            $Config.GpuType = "auto"
        }
    }
} else {
    Write-Info "GPU auto-detection enabled (Ollama will detect automatically)"
}

# ── Windows Task Scheduler ────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($Colors.Cyan)Windows Task Scheduler$($Colors.Reset) — runs nanobot gateway on login / system startup"
Write-Host "  $($Colors.Yellow)[Recommended for always-on AI agent]$($Colors.Reset)"
Write-Host ""
if (Prompt-YesNo "Set up auto-start task?" -Default $true) {
    $Config.SetupWindowsTask = $true
    Write-Success "Auto-start task will be configured"
} else {
    Write-Warn "Skipped — you can start manually with: nanobot gateway"
}

Write-Host ""
Write-Host "$($Colors.Green)All inputs collected — starting install.$($Colors.Reset)"

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — INSTALL
# ══════════════════════════════════════════════════════════════════════════════

# ── Check Chocolatey ──────────────────────────────────────────────────────────
Write-Header "Package Manager"
if (Test-CommandExists choco) {
    Write-Success "Chocolatey already installed"
} else {
    Write-Info "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    if (-not (Test-CommandExists choco)) {
        Write-Die "Chocolatey installation failed."
    }
    Write-Success "Chocolatey installed"
}

# ── Git ───────────────────────────────────────────────────────────────────────
Write-Header "System dependencies"
if (-not (Test-CommandExists git)) {
    Invoke-Chocolatey "git"
}
if (-not (Test-CommandExists curl)) {
    Invoke-Chocolatey "curl"
}
Write-Success "git, curl OK"

# ── Python ────────────────────────────────────────────────────────────────────
Write-Header "Python 3.11+"
$Python = Get-PythonCommand
if (-not $Python) {
    Write-Warn "Python 3.11+ not found — installing via Chocolatey..."
    Invoke-Chocolatey "python"
    $Python = Get-PythonCommand
    if (-not $Python) {
        Write-Die "Python installation failed."
    }
}

$pyVer = & $Python --version 2>&1
Write-Success "Using $Python ($pyVer)"

# Verify pip
try {
    & $Python -m pip --version | Out-Null
} catch {
    Write-Info "Installing pip..."
    & $Python -m ensurepip --upgrade | Out-Null
}

# ── Node.js ───────────────────────────────────────────────────────────────────
Write-Header "Node.js 20"
if (Test-CommandExists node) {
    $nodeVer = & node --version
    $nodeMajor = [int]($nodeVer -replace 'v(\d+).*', '$1')
    if ($nodeMajor -ge 18) {
        Write-Success "Node.js $nodeVer already installed"
    } else {
        Write-Warn "Node.js $nodeVer too old (need ≥18) — upgrading..."
        Invoke-Chocolatey "nodejs"
    }
} else {
    Invoke-Chocolatey "nodejs"
}

if (-not (Test-CommandExists npx)) {
    Write-Die "npx not found after installation."
}
Write-Success "Node.js $(& node --version), npm $(& npm --version)"

# ── Ollama ────────────────────────────────────────────────────────────────────
Write-Header "Ollama"
if (Test-CommandExists ollama) {
    $ollamaVer = & ollama --version 2>$null
    Write-Success "Ollama already installed ($ollamaVer)"
} else {
    Write-Info "Downloading Ollama Windows installer..."
    $ollamaInstallerUrl = "https://ollama.com/download/OllamaSetup.exe"
    $ollamaInstaller = Join-Path $env:TEMP "OllamaSetup.exe"

    try {
        (New-Object System.Net.WebClient).DownloadFile($ollamaInstallerUrl, $ollamaInstaller)
        Write-Info "Running Ollama installer..."
        & $ollamaInstaller | Out-Null

        # Wait for Ollama to be available
        $maxRetries = 20
        $retries = 0
        while (-not (Test-CommandExists ollama) -and $retries -lt $maxRetries) {
            Start-Sleep -Seconds 2
            $retries++
        }

        if (-not (Test-CommandExists ollama)) {
            Write-Die "Ollama not found after installation. You may need to restart and re-run this script."
        }
        Write-Success "Ollama installed"

        # Clean up installer
        Remove-Item $ollamaInstaller -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Die "Failed to download or install Ollama: $_"
    }
}

# Start Ollama service (it runs as a service on Windows)
Write-Info "Ensuring Ollama service is running..."
$ollamaService = Get-Service -Name "Ollama" -ErrorAction SilentlyContinue
if ($ollamaService) {
    if ($ollamaService.Status -eq "Running") {
        Write-Success "Ollama service already running"
    } else {
        Start-Service -Name "Ollama"
        Start-Sleep -Seconds 3
        Write-Success "Ollama service started"
    }
} else {
    Write-Warn "Ollama service not found. It may start automatically on next login."
}

# Wait for Ollama API to be ready
Write-Info "Waiting for Ollama API to be ready..."
$maxRetries = 30
$retries = 0
while ($retries -lt $maxRetries) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            break
        }
    } catch { }
    Start-Sleep -Seconds 2
    $retries++
}

if ($retries -ge $maxRetries) {
    Write-Warn "Ollama API did not respond in time. Make sure Ollama is running and accessible at http://localhost:11434"
}

Write-Info "Pulling model '$($Config.ModelTag)' (this may take a while)..."
& ollama pull $Config.ModelTag
Write-Success "Model '$($Config.ModelTag)' ready"

# ── nanobot ───────────────────────────────────────────────────────────────────
Write-Header "nanobot"
$nanobotDir = Join-Path $env:USERPROFILE "nanobot"
if (Test-Path (Join-Path $nanobotDir ".git")) {
    Write-Info "Repo exists at $nanobotDir — pulling latest..."
    & git -C $nanobotDir pull --ff-only
} else {
    Write-Info "Cloning HKUDS/nanobot..."
    & git clone https://github.com/HKUDS/nanobot.git $nanobotDir
}

Write-Info "Installing nanobot package..."
& $Python -m pip install --user --upgrade $nanobotDir --quiet
if (-not (Test-CommandExists nanobot)) {
    Write-Die "nanobot command not found after installation. Check your PATH."
}
Write-Success "nanobot installed"

# ── Config ────────────────────────────────────────────────────────────────────
Write-Header "config.json"
$nanobotConfigDir = Join-Path $env:USERPROFILE ".nanobot"
$nanobotConfig = Join-Path $nanobotConfigDir "config.json"
$null = New-Item -ItemType Directory -Path $nanobotConfigDir -Force

if (Test-Path $nanobotConfig) {
    $backupPath = "$nanobotConfig.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Warn "Existing config found — backing up to $(Split-Path $backupPath -Leaf)"
    Copy-Item $nanobotConfig $backupPath
}

# Build channel block
if ($Config.TelegramToken) {
    $telegramBlock = @"
    "telegram": {
      "enabled": true,
      "token": "",
      "allowFrom": ["$($Config.TelegramUserId)"]
    }
"@
} else {
    $telegramBlock = @"
    "telegram": {
      "enabled": false,
      "token": "",
      "allowFrom": []
    }
"@
}

# Build web search block
if ($Config.BraveApiKey) {
    $webSearchInner = '"provider": "brave", "apiKey": "' + $Config.BraveApiKey + '", "maxResults": 5'
} else {
    $webSearchInner = '"provider": "duckduckgo", "apiKey": "", "maxResults": 5'
}

# Build tools block
if ($Config.McpWorkspacePath) {
    $toolsBlock = @"
  "tools": {
    "web": { "enable": true, "search": { $webSearchInner } },
    "exec": { "enable": true, "timeout": 60, "pathAppend": "" },
    "restrictToWorkspace": true,
    "mcpServers": {
      "filesystem": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "$($Config.McpWorkspacePath)"]
      }
    },
    "ssrfWhitelist": []
  }
"@
} else {
    $toolsBlock = @"
  "tools": {
    "web": { "enable": true, "search": { $webSearchInner } },
    "exec": { "enable": true, "timeout": 60, "pathAppend": "" },
    "restrictToWorkspace": true,
    "mcpServers": {},
    "ssrfWhitelist": []
  }
"@
}

$configJson = @"
{
  "providers": {
    "ollama": {
      "apiKey": "dummy",
      "apiBase": "http://localhost:11434/v1"
    }
  },
  "agents": {
    "defaults": {
      "model": "$($Config.ModelTag)",
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
$telegramBlock
  },
  "gateway": {
    "host": "127.0.0.1",
    "port": 18789
  },
$toolsBlock
}
"@

Set-Content -Path $nanobotConfig -Value $configJson -Encoding UTF8
Write-Success "Config written to $nanobotConfig"

# Store Telegram token in environment file
$gatewayEnvDir = Join-Path $env:APPDATA "nanobot"
$gatewayEnvFile = Join-Path $gatewayEnvDir "gateway.env"
$null = New-Item -ItemType Directory -Path $gatewayEnvDir -Force

if ($Config.TelegramToken) {
    $envContent = "NANOBOT_TELEGRAM_TOKEN=$($Config.TelegramToken)"
    Set-Content -Path $gatewayEnvFile -Value $envContent -Encoding UTF8
    Write-Success "Telegram token stored in $gatewayEnvFile"
}

# ── nanobot onboard ───────────────────────────────────────────────────────────
Write-Header "nanobot onboard"
Write-Info "Initializing workspace (AGENT.md, SOUL.md, memory scaffolding)..."
try {
    & nanobot onboard | Out-Null
    Write-Success "Workspace initialized"
} catch {
    Write-Warn "onboard returned non-zero — you can re-run: nanobot onboard"
}

# ── Windows Task Scheduler ────────────────────────────────────────────────────
if ($Config.SetupWindowsTask) {
    Write-Header "Windows Task Scheduler"

    $taskName = "NanobotGateway"
    $taskPath = "\Anthropic\NanobotGateway"

    # Remove existing task if present
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Info "Removing existing task..."
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Build GPU environment variable command
    $gpuCommand = ""
    switch ($Config.GpuType) {
        "nvidia" {
            $gpuCommand = "`$env:CUDA_VISIBLE_DEVICES='0'; `$env:OLLAMA_NUM_PARALLEL='4'; "
            Write-Info "GPU: NVIDIA CUDA (forcing CUDA_VISIBLE_DEVICES=0)"
        }
        "amd" {
            $gpuCommand = "`$env:OLLAMA_NUM_PARALLEL='4'; "
            Write-Info "GPU: AMD ROCm (ROCm auto-detection enabled)"
        }
        "intel" {
            $gpuCommand = "`$env:OLLAMA_NUM_PARALLEL='4'; "
            Write-Info "GPU: Intel Arc (Intel GPU support enabled)"
        }
        "cpu" {
            $gpuCommand = "`$env:OLLAMA_NUM_GPU='0'; "
            Write-Info "GPU: CPU only (GPU acceleration disabled)"
        }
        default {
            Write-Info "GPU: Auto-detection (Ollama will detect automatically)"
        }
    }

    # Create task trigger (at login and system startup)
    $triggers = @(
        (New-ScheduledTaskTrigger -AtLogon -RunAsUser $env:USERNAME),
        (New-ScheduledTaskTrigger -AtStartup)
    )

    # Create task action with GPU environment variables
    $action = New-ScheduledTaskAction `
        -Execute "PowerShell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -Command `"${gpuCommand}nanobot gateway`""

    # Create task principal (run as current user)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive

    # Create and register task
    $task = New-ScheduledTask -Action $action -Trigger $triggers -Principal $principal -Description "NanobotAI Gateway Service"
    Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null

    Write-Success "Auto-start task scheduled with GPU configuration"
}

# ── Verify ────────────────────────────────────────────────────────────────────
Write-Header "Verification"
try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Success "Ollama API reachable at localhost:11434"
    }
} catch {
    Write-Warn "Ollama API not responding — ensure Ollama is running"
}

$nanobotPath = & where.exe nanobot 2>$null
Write-Success "nanobot: $nanobotPath"
Write-Success "Node.js: $(& node --version)"
Write-Success "Python: $($Python)"

# ══════════════════════════════════════════════════════════════════════════════
# DONE
# ══════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "$($Colors.Green)$($Colors.Bold)════════════════════════════════════════$($Colors.Reset)"
Write-Host "$($Colors.Green)$($Colors.Bold)  Installation complete!$($Colors.Reset)"
Write-Host "$($Colors.Green)$($Colors.Bold)════════════════════════════════════════$($Colors.Reset)"
Write-Host ""
Write-Host "  $($Colors.Bold)Model:$($Colors.Reset)      $($Colors.Cyan)$($Config.ModelTag)$($Colors.Reset)"
Write-Host "  $($Colors.Bold)Config:$($Colors.Reset)     $($Colors.Cyan)$nanobotConfig$($Colors.Reset)"
Write-Host "  $($Colors.Bold)Source:$($Colors.Reset)     $($Colors.Cyan)$nanobotDir$($Colors.Reset)"
Write-Host "  $($Colors.Bold)Workspace:$($Colors.Reset)  $($Colors.Cyan)$(Join-Path $env:USERPROFILE '.nanobot\workspace')$($Colors.Reset)"

if ($Config.BraveApiKey) {
    Write-Host "  $($Colors.Bold)Web search:$($Colors.Reset) $($Colors.Green)enabled (Brave)$($Colors.Reset)"
} else {
    Write-Host "  $($Colors.Bold)Web search:$($Colors.Reset) $($Colors.Yellow)disabled$($Colors.Reset)"
}

if ($Config.TelegramToken) {
    Write-Host "  $($Colors.Bold)Telegram:$($Colors.Reset)   $($Colors.Green)enabled$($Colors.Reset)"
} else {
    Write-Host "  $($Colors.Bold)Telegram:$($Colors.Reset)   $($Colors.Yellow)disabled$($Colors.Reset)"
}

if ($Config.McpWorkspacePath) {
    Write-Host "  $($Colors.Bold)MCP path:$($Colors.Reset)   $($Colors.Cyan)$($Config.McpWorkspacePath)$($Colors.Reset)"
} else {
    Write-Host "  $($Colors.Bold)MCP:$($Colors.Reset)        $($Colors.Yellow)not configured$($Colors.Reset)"
}

if ($Config.SetupWindowsTask) {
    Write-Host "  $($Colors.Bold)Auto-start:$($Colors.Reset) $($Colors.Green)NanobotGateway task$($Colors.Reset)"
} else {
    Write-Host "  $($Colors.Bold)Auto-start:$($Colors.Reset) $($Colors.Yellow)not configured$($Colors.Reset)"
}

$gpuLabel = switch ($Config.GpuType) {
    "nvidia" { "$($Colors.Green)NVIDIA CUDA$($Colors.Reset)" }
    "amd" { "$($Colors.Green)AMD ROCm$($Colors.Reset)" }
    "intel" { "$($Colors.Green)Intel Arc$($Colors.Reset)" }
    "cpu" { "$($Colors.Yellow)CPU only$($Colors.Reset)" }
    default { "$($Colors.Yellow)auto-detect$($Colors.Reset)" }
}
Write-Host "  $($Colors.Bold)GPU:$($Colors.Reset)        $gpuLabel"

Write-Host ""
Write-Host "$($Colors.Bold)Commands:$($Colors.Reset)"
Write-Host "  $($Colors.Yellow)nanobot agent$($Colors.Reset)                           # interactive CLI"
Write-Host "  $($Colors.Yellow)nanobot agent -m 'hello'$($Colors.Reset)                # one-shot"
Write-Host "  $($Colors.Yellow)nanobot gateway$($Colors.Reset)                         # foreground gateway"
Write-Host "  $($Colors.Yellow)nanobot serve$($Colors.Reset)                           # local OpenAI-compatible API"

if ($Config.SetupWindowsTask) {
    Write-Host "  $($Colors.Yellow)Get-ScheduledTask -TaskName NanobotGateway$($Colors.Reset)     # check task"
    Write-Host "  $($Colors.Yellow)Start-ScheduledTask -TaskName NanobotGateway$($Colors.Reset)   # run now"
}

Write-Host "  $($Colors.Yellow)ollama serve$($Colors.Reset)                            # start Ollama if not running"
Write-Host ""

if (-not $Config.BraveApiKey) {
    Write-Host "$($Colors.Yellow)Tip:$($Colors.Reset) Add Brave Search later → edit $($Colors.Cyan)$nanobotConfig$($Colors.Reset)"
    Write-Host "  Set $($Colors.Cyan)tools.web.search.apiKey$($Colors.Reset) — free key at $($Colors.Cyan)brave.com/search/api$($Colors.Reset)"
    Write-Host ""
}

if (-not $Config.TelegramToken) {
    Write-Host "$($Colors.Yellow)Tip:$($Colors.Reset) Add Telegram later:"
    Write-Host "  1. @BotFather for token, @userinfobot for your ID"
    Write-Host "  2. Edit config → set $($Colors.Cyan)channels.telegram.enabled=true$($Colors.Reset)"
    Write-Host "  3. Add $($Colors.Cyan)NANOBOT_TELEGRAM_TOKEN=<token>$($Colors.Reset) to $($Colors.Cyan)$gatewayEnvFile$($Colors.Reset)"
    Write-Host ""
}

Write-Host "$($Colors.Yellow)Important:$($Colors.Reset) Keep Ollama running as a service. You can manage it via:"
Write-Host "  Services app (services.msc) → Ollama"
Write-Host "  Or command line: Start-Service -Name Ollama"
Write-Host ""
