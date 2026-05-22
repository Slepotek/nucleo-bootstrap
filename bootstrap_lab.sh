#!/bin/bash

# ==============================================================================
# 🚀 Nucleo Lab: The "Full Toolchain" Bootstrap
# ==============================================================================
# This script creates a self-contained, portable development environment.
# Tools: Neovim, Gemini CLI, ARM GCC, Clang/LLVM, CMake, Python Venv, Nerd Fonts.
# ==============================================================================

set -e

# --- Configuration & Defaults ---
WORKSPACE_DIR="$HOME/nucleo-lab"
INCLUDE_AGENT=true
NVIM_CONFIG_REPO="https://github.com/Slepotek/nvim_env.git"
MCU_AGENT_REPO="https://github.com/Slepotek/geminiMcuAgent.git"

usage() {
    cat <<EOF
🚀 Nucleo Lab Bootstrap Tool
Usage: bootstrap.sh [options]

This script sets up a complete, isolated development environment for 
STM32/Nucleo development.

Options:
  --workspace <path>  Set the absolute path for the lab workspace.
                      (Default: \$HOME/nucleo-lab)
  --no-agent          Skip the installation of the Gemini MCU Expert Agent.
  --help              Display this help message and exit.

Tools Installed:
  - Neovim (Latest AppImage)
  - Gemini CLI (via npm)
  - ARM GNU Toolchain (GCC, GDB)
  - LLVM/Clang (clangd, analysis tools)
  - CMake & Make
  - FiraCode Nerd Font (for consistent icons)

Environment:
  - Isolated XDG config paths (keeps your system clean).
  - Dedicated Python venv for Neovim (pyright, pynvim).
  - Pre-configured MCU Agent discovery.

EOF
    exit 0
}

# --- Parse Arguments ---
while [[ "\$#" -gt 0 ]]; do
    case \$1 in
        --workspace) WORKSPACE_DIR="\$2"; shift ;;
        --no-agent) INCLUDE_AGENT=false ;;
        --help) usage ;;
        *) echo "❌ Unknown parameter: \$1"; usage ;;
    esac
    shift
done

echo "🛠️  Initializing Complete Lab at: $WORKSPACE_DIR"

# --- 0. System Dependency Auto-Install ---
install_deps() {
    if command -v apt-get &> /dev/null; then
        echo "📦 Detected Debian/Ubuntu. Installing dependencies..."
        sudo apt-get update -qq && sudo apt-get install -y git python3-venv nodejs npm
    elif command -v dnf &> /dev/null; then
        echo "📦 Detected Fedora/RHEL. Installing dependencies..."
        sudo dnf install -y git python3 nodejs npm
    elif command -v pacman &> /dev/null; then
        echo "📦 Detected Arch Linux. Installing dependencies..."
        sudo pacman -S --noconfirm git python nodejs npm
    else
        echo "⚠️  Unknown package manager. Please ensure git, python3-venv, and nodejs are installed."
    fi
}

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🔍 Checking for system dependencies..."
    install_deps
fi

mkdir -p "$WORKSPACE_DIR"/{bin,lib,include,src,MCU_docs,.config,.gemini/agents}
cd "$WORKSPACE_DIR"

# --- 1. Core Editor & Brain ---
echo "📥 Fetching Neovim (AppImage)..."
curl -L -o bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod +x bin/nvim

echo "📥 Fetching Gemini CLI..."
if command -v npm &> /dev/null; then
    npm install --prefix . @google/gemini-cli
    ln -sf "$WORKSPACE_DIR/node_modules/.bin/gemini" bin/gemini
else
    echo "⚠️  npm not found. Gemini CLI installation skipped."
fi

# --- 2. Build Systems & Toolchains ---
echo "📥 Fetching CMake..."
CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2-linux-x86_64.tar.gz"
curl -L "$CMAKE_URL" | tar -xz -C lib/
ln -sf "$WORKSPACE_DIR"/lib/cmake-*/bin/* bin/

echo "📥 Fetching ARM GNU Toolchain (GCC)..."
ARM_URL="https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-arm-none-eabi.tar.xz"
curl -L "$ARM_URL" | tar -xJ -C lib/
ln -sf "$WORKSPACE_DIR"/lib/arm-gnu-toolchain-*/bin/* bin/

echo "📥 Fetching LLVM/Clang (for clangd & analysis)..."
LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz"
curl -L "$LLVM_URL" | tar -xJ -C lib/
ln -sf "$WORKSPACE_DIR"/lib/clang+llvm-*/bin/* bin/

# --- 3. Font Installation (FiraCode Nerd Font) ---
echo "📥 Installing FiraCode Nerd Font for icons..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
curl -L -o "$FONT_DIR/FiraCodeNerdFont-Regular.ttf" https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf
curl -L -o "$FONT_DIR/FiraCodeNerdFont-Bold.ttf" https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FiraCode/Bold/FiraCodeNerdFont-Bold.ttf
echo "🔄 Updating font cache..."
fc-cache -fv > /dev/null

# --- 4. Repository & Venv Setup ---
echo "📥 Setting up Neovim Configuration..."
NVIM_DIR="$WORKSPACE_DIR/.config/nvim"
if [ ! -d "$NVIM_DIR/.git" ]; then
    git clone "$NVIM_CONFIG_REPO" "$NVIM_DIR"
else
    (cd "$NVIM_DIR" && git pull)
fi

echo "🐍 Creating local Python environment for Neovim..."
python3 -m venv "$NVIM_DIR/venv"
source "$NVIM_DIR/venv/bin/activate"
pip install --quiet --upgrade pip pynvim pyright

if [ "$INCLUDE_AGENT" = true ]; then
    echo "🧠 Setting up MCU Expert Agent..."
    AGENT_DIR="$WORKSPACE_DIR/.gemini/agents/mcu-repo"
    if [ ! -d "$AGENT_DIR/.git" ]; then
        git clone "$MCU_AGENT_REPO" "$AGENT_DIR"
    else
        (cd "$AGENT_DIR" && git pull)
    fi
    find "$AGENT_DIR" -name "*.md" -exec ln -sf {} "$WORKSPACE_DIR/.gemini/agents/" \;
fi

# --- 5. Activation Script Generation ---
echo "📝 Generating activation script..."
cat <<EOF > activate_lab.sh
#!/bin/bash
export WORKSPACE="$WORKSPACE_DIR"
export PATH="\$WORKSPACE/bin:\$PATH"
export XDG_CONFIG_HOME="\$WORKSPACE/.config"
export XDG_DATA_HOME="\$WORKSPACE/.local/share"
export XDG_STATE_HOME="\$WORKSPACE/.local/state"

source "\$WORKSPACE/.config/nvim/venv/bin/activate"

echo "✅ Lab Environment Activated!"
echo "🛠️  Build:    cmake, make"
echo "🛠️  Compiler: arm-none-eabi-gcc, clang, clangd"
echo "🖥️  Editor:   nvim"
echo "🧠 Brain:    gemini"
echo "-------------------------------------------------------"
EOF

chmod +x activate_lab.sh

echo "=============================================================================="
echo "✨ Lab Setup Complete! Everything is isolated in $WORKSPACE_DIR"
echo "👉 IMPORTANT: Set your Terminal Font to 'FiraCode Nerd Font' to see icons."
echo ""
echo "💻 WSL USERS: You MUST also install the FiraCode Nerd Font on your WINDOWS host"
echo "   machine, as the Windows Terminal is what handles the icon rendering."
echo ""
echo "To begin: cd $WORKSPACE_DIR && source activate_lab.sh"
echo "=============================================================================="
