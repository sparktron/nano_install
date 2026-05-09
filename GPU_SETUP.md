# GPU Acceleration Guide

Both installers now include GPU configuration options to force specific GPU acceleration or disable it completely.

## 🎯 Quick Reference

| GPU Type | Command | Use Case |
|----------|---------|----------|
| **Auto-detect** | (default) | Ollama detects GPU automatically — recommended for most users |
| **NVIDIA CUDA** | Force CUDA | RTX, GTX, Tesla, L40, H100, A100 — NVIDIA GPUs |
| **AMD ROCm** | Force AMD GPU | Radeon RX, Radeon Pro, MI series — AMD GPUs |
| **Intel Arc** | Force Intel GPU | Arc A-series — Intel Arc GPUs |
| **CPU Only** | Disable GPU | Force CPU-only inference (slow, useful for testing) |

## 📋 Installation Prompts

During installation, you'll be asked:

```
[?] Configure GPU acceleration? [y/N]: 
```

### Default: Skip (Auto-Detect)
- Press **Enter** or type `n` → Ollama auto-detects your GPU
- Recommended for most users — works 95% of the time

### Force Specific GPU
- Type `y` → Choose from NVIDIA, AMD, Intel Arc, or CPU-only
- Use this if auto-detection fails

---

## 🖥️ NVIDIA CUDA Setup

### Prerequisites
- **NVIDIA GPU**: GeForce RTX/GTX, Tesla, A100, H100, etc.
- **NVIDIA Driver**: Installed and working (`nvidia-smi` should work)
- **CUDA 12.0+**: Usually installed with the driver

### Check NVIDIA Setup
```bash
# Linux/macOS
nvidia-smi

# Windows
nvidia-smi.exe
```

### If It Works
- During installation: Select option `1) NVIDIA CUDA` when prompted
- Or press Enter → installer auto-detects

### If Auto-Detection Fails
```bash
# Linux/macOS: Force CUDA
export OLLAMA_NUM_PARALLEL=4
ollama serve

# Windows PowerShell: Force CUDA
$env:CUDA_VISIBLE_DEVICES='0'
$env:OLLAMA_NUM_PARALLEL='4'
ollama serve
```

### Troubleshooting
Check if GPU is recognized:
```bash
ollama list
```

If model shows `size_vram: 0` (running on CPU), try:
1. Update NVIDIA driver
2. Restart Ollama: `ollama serve` (fresh terminal)
3. Check `/dev/nvidia-uvm` exists (Linux):
   ```bash
   ls -la /dev/nvidia-uvm
   ```

---

## 🔴 AMD ROCm Setup

### Prerequisites
- **AMD GPU**: Radeon RX 6000/7000 series, or Radeon Pro
- **ROCm Driver**: Installed (`rocm-smi` should work)
- **Linux Only**: ROCm is primarily Linux-focused (limited Windows support)

### Check AMD Setup (Linux)
```bash
rocm-smi
```

### During Installation
- Select option `2) AMD ROCm` when prompted
- Installer sets `OLLAMA_NUM_PARALLEL=4`

### Manual AMD Setup (Linux)
```bash
export OLLAMA_NUM_PARALLEL=4
ollama serve
```

### Troubleshooting
```bash
# Check if ROCm sees your GPU
rocm-smi

# Check HIP runtime
hipconfig --version

# Enable debug logging
export HIP_TRACE_API=1
ollama serve
```

---

## 💙 Intel Arc Setup

### Prerequisites
- **Intel Arc GPU**: A-series (A770, A750, A380, A380M)
- **Intel Graphics Driver**: Latest version installed
- **oneAPI Toolkit**: Recommended but not always required

### Check Intel Arc
```bash
# Linux
lsmod | grep i915
clinfo  # OpenCL info

# Windows
Get-PnpDevice -DriverName "*intel*" | Select Name, Status
```

### During Installation
- Select option `3) Intel Arc` when prompted
- Ollama will use Intel GPU via OpenCL

### Manual Intel Arc Setup
```bash
# Linux
export OLLAMA_NUM_PARALLEL=4
ollama serve

# Windows PowerShell
$env:OLLAMA_NUM_PARALLEL='4'
ollama serve
```

---

## 🍎 Apple Metal (macOS)

### Prerequisites
- **Mac with Apple Silicon or AMD GPU**
- **macOS 12.0+** (Apple Silicon) or **11.0+** (Intel Mac with AMD)

### Check Metal Support
```bash
# Apple Silicon automatically supports Metal
sysctl -n machdep.cpu.brand_string

# Intel Mac with AMD GPU
system_profiler SPDisplaysDataType
```

### During Installation
- Installer auto-detects Metal on macOS
- Metal GPU is automatically used

### Manual Metal Setup
```bash
# Metal is automatic on compatible Macs
ollama serve
```

---

## ⚙️ CPU-Only Mode

Use this if:
- You don't have a GPU
- GPU is not working
- You want to test CPU performance
- You need lower latency (CPU inference is often faster for small models)

### During Installation
- Select option `4) CPU only` when prompted

### Manual CPU-Only Mode

**Linux/macOS:**
```bash
export OLLAMA_NUM_GPU=0
ollama serve
```

**Windows PowerShell:**
```powershell
$env:OLLAMA_NUM_GPU='0'
ollama serve
```

---

## 🔧 Advanced GPU Configuration

### Parallel Inference
Increase number of parallel model loads (speeds up concurrent requests):

```bash
# Linux/macOS
export OLLAMA_NUM_PARALLEL=8
ollama serve

# Windows PowerShell
$env:OLLAMA_NUM_PARALLEL='8'
ollama serve
```

### VRAM Limit
If your GPU doesn't have enough memory, limit model size:

```bash
# Linux/macOS: Only use first GPU, limit parallel loads
export CUDA_VISIBLE_DEVICES=0
export OLLAMA_NUM_PARALLEL=2
ollama serve

# Windows PowerShell
$env:CUDA_VISIBLE_DEVICES='0'
$env:OLLAMA_NUM_PARALLEL='2'
ollama serve
```

### Multiple GPUs
Use multiple GPUs for better parallelism (advanced):

```bash
# Linux/macOS: Use GPU 0 and GPU 1
export CUDA_VISIBLE_DEVICES=0,1
export OLLAMA_NUM_PARALLEL=8
ollama serve

# Windows PowerShell
$env:CUDA_VISIBLE_DEVICES='0,1'
$env:OLLAMA_NUM_PARALLEL='8'
ollama serve
```

---

## 📊 Performance Verification

After installation, verify GPU is being used:

### Linux/macOS
```bash
# Run health check (if set up during installation)
nanobot-health-check

# Or manually check Ollama
ollama list
# Look for "size_vram: XXXXX" (non-zero = GPU)
```

### Windows
```powershell
# Check Task Scheduler logs
Get-ScheduledTask -TaskName NanobotGateway | Get-ScheduledTaskInfo

# Or run manually to see output
nanobot gateway
```

### Manual Verification
```bash
# Any platform
curl http://localhost:11434/api/ps

# Look for "size_vram" field (non-zero = GPU active)
# If size_vram is 0, model is running on CPU
```

---

## 🚨 Troubleshooting GPU Issues

### Problem: GPU not detected (size_vram = 0)

**Linux (NVIDIA):**
```bash
# Check UVM is available
ls -la /dev/nvidia-uvm

# Reload NVIDIA kernel module
sudo modprobe -r nvidia_uvm
sudo modprobe nvidia_uvm

# Restart Ollama
sudo systemctl restart ollama
```

**Linux (AMD):**
```bash
# Check ROCm
rocm-smi --showid

# Restart Ollama
sudo systemctl restart ollama
```

**Windows:**
1. Update NVIDIA/AMD drivers
2. Restart Windows
3. Open Task Scheduler → NanobotGateway → right-click → Run

**macOS:**
1. Restart your Mac
2. Update macOS
3. Restart Ollama

### Problem: Out of VRAM

**Solution**: Use a smaller model or reduce parallelism

```bash
# Linux/macOS
export OLLAMA_NUM_PARALLEL=1
ollama serve

# Windows PowerShell
$env:OLLAMA_NUM_PARALLEL='1'
ollama serve
```

Choose a smaller model:
```bash
ollama pull mistral:7b   # Instead of llama3.1:70b
```

### Problem: GPU enabled but model still slow

1. Check if GPU is actually being used:
   ```bash
   curl http://localhost:11434/api/ps | grep size_vram
   ```
2. If `size_vram` is 0, GPU isn't working
3. Try forcing GPU again or reinstalling driver

### Problem: GPU was working, now it isn't

**Linux:**
```bash
# Check driver didn't unload
nvidia-smi

# Reload if needed
sudo modprobe -r nvidia nvidia_drm nvidia_uvm
sudo modprobe nvidia
sudo modprobe nvidia_drm
sudo modprobe nvidia_uvm
```

**Windows:**
1. Open Device Manager
2. Right-click GPU → Update Driver
3. Restart Ollama

---

## 📚 Environment Variables Reference

| Variable | Values | Purpose |
|----------|--------|---------|
| `OLLAMA_NUM_GPU` | `0` (CPU only) | Disable GPU acceleration |
| `OLLAMA_NUM_PARALLEL` | `1`-`16` | Number of concurrent model loads |
| `CUDA_VISIBLE_DEVICES` | `0` or `0,1,2` | Which GPUs to use (NVIDIA) |
| `HIP_VISIBLE_DEVICES` | `0` or `0,1,2` | Which GPUs to use (AMD) |

---

## 🔗 Resources

- **Ollama GPU Support**: [github.com/ollama/ollama](https://github.com/ollama/ollama)
- **NVIDIA CUDA**: [docs.nvidia.com/cuda](https://docs.nvidia.com/cuda)
- **AMD ROCm**: [rocmdocs.amd.com](https://rocmdocs.amd.com)
- **Intel Arc**: [github.com/oneapi-src](https://github.com/oneapi-src)

---

## 💡 Quick Start by GPU Type

### NVIDIA Users
1. Install NVIDIA driver (`nvidia-smi` should work)
2. During installation: press `y` → select `1) NVIDIA CUDA`
3. Or just press Enter → auto-detect

### AMD Users (Linux)
1. Install ROCm (`rocm-smi` should work)
2. During installation: press `y` → select `2) AMD ROCm`

### Intel Arc Users
1. Update Intel graphics driver
2. During installation: press `y` → select `3) Intel Arc`

### macOS Users
1. Apple Metal auto-detects
2. Just press Enter during GPU prompt

### No GPU / CPU Only
1. During installation: press `y` → select `4) CPU only`
2. Or press Enter → auto-detect works fine on CPU too
