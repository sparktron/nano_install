# Discord Integration Guide

Complete setup guide for connecting nanobot to Discord for real-time chat and commands.

## 📋 Quick Start

1. Create a Discord bot at [discord.com/developers](https://discord.com/developers/applications)
2. Get your bot token and channel ID
3. During installation: Answer `y` when prompted "Configure Discord?"
4. Paste bot token and channel ID when asked
5. Done! Bot will be active on your Discord server

**Estimated time**: 5 minutes

---

## 🤖 Creating a Discord Bot

### Step 1: Create an Application

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click **"New Application"**
3. Give it a name (e.g., "nanobot-ai")
4. Click **"Create"**

### Step 2: Create a Bot

1. In your application, go to the **"Bot"** tab on the left
2. Click **"Add Bot"**
3. Under the **"TOKEN"** section, click **"Copy"** (this is your bot token)
   - 🔐 **SAVE THIS SECURELY** — don't share it!
   - This is what you'll paste during installation as "Bot token"

### Step 3: Set Bot Permissions

1. In the Bot section, scroll down to **"Permissions"**
2. Check these boxes:
   - ✅ `Send Messages`
   - ✅ `Read Messages/View Channels`
   - ✅ `Read Message History`
   - ✅ `Manage Messages` (optional, for cleanup)
   - ✅ `Embed Links`
   - ✅ `Attach Files`

3. Copy the generated URL at the bottom

### Step 4: Add Bot to Your Server

1. Paste the permission URL from Step 3 into your browser
2. Select your Discord server from the dropdown
3. Click **"Authorize"**
4. Verify the permissions and click **"Authorize"**
5. Your bot is now in your server!

---

## 🔗 Getting Your Channel ID

You need the ID of the Discord channel where nanobot will send messages.

### Method 1: Discord Desktop/Web (Recommended)

1. Right-click on the Discord channel in your server
2. Select **"Copy Channel ID"**
3. Paste this when asked for "Discord channel ID" during installation

### Method 2: Manual Copy

1. In Discord, enable **Developer Mode**:
   - Desktop: Settings → Advanced → Developer Mode (turn on)
   - Web: User Settings → Advanced → Developer Mode (turn on)

2. Right-click any channel
3. Look for **"Copy Channel ID"** option
4. Paste during installation

### Method 3: From URL

1. Open the channel in Discord
2. Look at the browser URL: `https://discord.com/channels/[SERVER_ID]/[CHANNEL_ID]`
3. Copy the last number (CHANNEL_ID)

---

## 🔧 Installation Configuration

### During Installation

When the installer asks:

```
[?] Configure Discord? [Y/n]:
```

- **Press Enter** or type `y` → configure Discord
- Type `n` → skip Discord (enable later)

### Providing Information

```
Bot token: [PASTE YOUR TOKEN HERE]
Discord channel ID: [PASTE YOUR CHANNEL ID HERE]
```

**Copy and paste carefully** — no spaces, exactly as shown.

---

## ✅ Verify It's Working

### Test 1: Check Configuration

After installation, verify Discord is enabled:

**Linux/macOS:**
```bash
cat ~/.nanobot/config.json | grep -A 5 discord
```

**Windows:**
```powershell
Get-Content $env:USERPROFILE\.nanobot\config.json | Select-String -Context 0,5 discord
```

You should see:
```json
"discord": {
  "enabled": true,
  "token": "",
  "channelId": "YOUR_CHANNEL_ID"
}
```

### Test 2: Check Token is Stored

**Linux/macOS:**
```bash
cat ~/.config/nanobot/gateway.env
```

**Windows:**
```powershell
Get-Content $env:APPDATA\nanobot\gateway.env
```

You should see:
```
NANOBOT_DISCORD_TOKEN=your_token_here
```

### Test 3: Start nanobot

**Linux/macOS:**
```bash
nanobot gateway
```

**Windows (PowerShell):**
```powershell
nanobot gateway
```

In Discord, you should see a message indicating the bot is online or ready.

### Test 4: Send a Command

In your Discord channel, try:
```
@nanobot hello
```

The bot should respond in Discord!

---

## 🔄 Using Discord Commands

Once connected, you can interact with nanobot directly in Discord:

### Basic Interaction

```
@nanobot What is the capital of France?
```

**Response**: Bot answers in the Discord channel

### Multi-Line Conversations

Discord conversations are tracked. The bot remembers context within a channel.

### Mentioning the Bot

Use `@nanobot` to address the bot directly:

```
@nanobot Explain machine learning
```

---

## 🔐 Security Best Practices

### Token Safety

- 🔐 **Never commit your token to GitHub or version control**
- Stored in `~/.config/nanobot/gateway.env` (Linux/macOS) or `%APPDATA%\nanobot\gateway.env` (Windows)
- File is read-only to protect the token
- If token is leaked, regenerate it in Discord Developer Portal

### Server Security

- Restrict bot to a private channel or server
- Keep bot permissions minimal (only what it needs)
- Review channel access regularly
- You can revoke the bot's access anytime by removing it from the server

### Regenerating Token (If Compromised)

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click on your application
3. Go to **Bot** tab
4. Click **"Regenerate"** under TOKEN
5. Update `.env` file with new token
6. Restart nanobot

---

## 🐛 Troubleshooting

### "Bot won't respond in Discord"

**Check 1: Bot is online in Discord**
- Go to your Discord server members list
- Look for your bot's name
- Hover over it — should show "Online" (green dot)

**Check 2: Bot has message permissions**
- Right-click the channel
- Select "Permissions"
- Find your bot in the user list
- Ensure "Send Messages" is ✅

**Check 3: Logs show an error**
- Stop and restart the bot:
  ```bash
  # Linux/macOS
  systemctl --user restart nanobot-gateway
  
  # Windows Task Scheduler
  Stop-ScheduledTask -TaskName NanobotGateway
  Start-ScheduledTask -TaskName NanobotGateway
  ```

### "Invalid token" error

- Verify token is correctly copied (no spaces, exactly as shown)
- Check `~/.config/nanobot/gateway.env` (Linux/macOS) or `%APPDATA%\nanobot\gateway.env` (Windows)
- Regenerate token if uncertain

### "Channel not found" error

- Double-check channel ID (numbers only, no symbols)
- Verify bot has access to that channel
- Ensure channel still exists and isn't archived

### Bot responds but very slowly

- Might be processing with a large model
- Try a smaller model for faster responses:
  ```bash
  ollama pull mistral:7b
  ```
- Check if GPU is being used (see GPU_SETUP.md)

### Bot not staying online

- Check if auto-start is enabled:
  - **Linux/macOS**: `systemctl --user status nanobot-gateway`
  - **Windows**: Check Task Scheduler for "NanobotGateway"
- Restart the service if needed

---

## 🔧 Adding Discord After Installation

If you skipped Discord during installation, you can add it later:

### Step 1: Edit Configuration

**Linux/macOS:**
```bash
nano ~/.nanobot/config.json
```

**Windows:**
```powershell
notepad $env:USERPROFILE\.nanobot\config.json
```

### Step 2: Enable Discord

Find the Discord section and update:

```json
"discord": {
  "enabled": true,
  "token": "",
  "channelId": "YOUR_CHANNEL_ID_HERE"
}
```

Save and close.

### Step 3: Add Token to Environment File

**Linux/macOS:**
```bash
nano ~/.config/nanobot/gateway.env
```

**Windows:**
```powershell
notepad $env:APPDATA\nanobot\gateway.env
```

Add this line:
```
NANOBOT_DISCORD_TOKEN=YOUR_BOT_TOKEN_HERE
```

Save and close.

### Step 4: Restart nanobot

**Linux/macOS:**
```bash
systemctl --user restart nanobot-gateway
```

**Windows:**
```powershell
Stop-ScheduledTask -TaskName NanobotGateway
Start-ScheduledTask -TaskName NanobotGateway
```

Discord should now be connected!

---

## 🚀 Advanced Configuration

### Multiple Channels

To monitor multiple Discord channels, you'll need to edit the config. Currently, nanobot watches one channel — contact the nanobot team for multi-channel support.

### Custom Status Messages

The bot's status is configurable in the configuration file. See nanobot documentation for status message options.

### Rate Limiting

Discord has API rate limits. The default configuration handles this automatically. If you hit rate limits:
- Reduce number of commands
- Space out requests (wait a few seconds between messages)
- Contact nanobot support if persistent

---

## 📞 Need Help?

### Check These First

1. Bot token is valid (hasn't expired)
2. Channel ID is correct (numbers only)
3. Bot has "Send Messages" permission in the channel
4. Bot is actually online in Discord (green dot)

### Common Solutions

| Problem | Solution |
|---------|----------|
| No bot response | Restart nanobot gateway |
| "Invalid token" | Regenerate token in Discord Dev Portal |
| Slow responses | Check if GPU is working (GPU_SETUP.md) |
| Bot goes offline | Check systemd/Task Scheduler status |

### Get Logs

**Linux/macOS:**
```bash
journalctl --user -u nanobot-gateway -f
```

**Windows:**
```powershell
Get-ScheduledTask -TaskName NanobotGateway | Start-ScheduledTask
```

Then check the Task Scheduler Event Viewer for errors.

---

## 🔗 Resources

- **Discord Developer Portal**: https://discord.com/developers/applications
- **Discord Docs**: https://discord.com/developers/docs
- **nanobot Repository**: https://github.com/HKUDS/nanobot
- **Create a Discord Server**: https://discord.com/servers/create

---

## 💡 Tips & Tricks

### Tip 1: Dedicated Channel
Create a channel just for nanobot (e.g., `#nanobot-ai`) to keep conversations organized.

### Tip 2: Command Hints
Pin a message with command examples in the nanobot channel so users know how to interact with it.

### Tip 3: Multiple Bots
You can create multiple bot instances for different purposes — each gets its own channel and token.

### Tip 4: Monitoring
You can see when your bot was last active in Discord's audit log.

---

**Ready to chat with nanobot in Discord?** Start the installation and select Discord when prompted! 🚀
