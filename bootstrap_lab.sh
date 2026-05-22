#!/bin/bash

# ==============================================================================
# 🚀 Nucleo Lab: Portable Environment Toolbox
# ==============================================================================
# This script installs the necessary tools (Nvim, Gemini, GCC, Clang, CMake)
# into a central 'Toolbox' directory. You can then 'source' the activation
# script to use these tools in ANY project directory.
# ==============================================================================

set -e

# --- Configuration & Defaults ---
TOOLBOX_DIR="$HOME/.nucleo-toolbox"
INCLUDE_AGENT=true
NVIM_CONFIG_REPO="https://github.com/Slepotek/nvim_env.git"
MCU_AGENT_REPO="https://github.com/Slepotek/geminiMcuAgent.git"

usage() {
    cat <<EOF
🚀 Nucleo Lab Toolbox Bootstrap
Usage: bootstrap.sh [options]

Options:
  --path <path>       Set the absolute path for the toolbox installation.
                      (Default: $HOME/.nucleo-toolbox)
  --no-agent          Skip the installation of the Gemini MCU Expert Agent.
  --help              Display this help message and exit.

Tools Installed:
  - Neovim (Latest AppImage)
  - Gemini CLI (Requires Node v20+)
  - ARM GNU Toolchain (GCC, GDB)
  - LLVM/Clang (clangd, analysis tools)
  - CMake & Make
  - FiraCode Nerd Font
EOF
    exit 0
}

# --- Parse Arguments ---
# Properly escaped for bash variable persistence
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --path) TOOLBOX_DIR="$2"; shift ;;
        --no-agent) INCLUDE_AGENT=false ;;
        --help) usage ;;
        *) echo "❌ Unknown parameter: $1"; usage ;;
    esac
    shift
done

echo "🛠️  Initializing Lab Toolbox at: $TOOLBOX_DIR"

# --- 0. System Dependency Auto-Install ---
install_deps() {
    if command -v apt-get &> /dev/null; then
        echo "📦 Detected Debian/Ubuntu. Installing dependencies..."
        sudo apt-get update -qq
        # We need a modern Node.js. Default apt version (v18) is often too old.
        # We'll install nvm or just the basics and warn.
        sudo apt-get install -y git python3-venv curl
        
        # Check Node version. If < 20, we recommend manual update or we use a binary.
        if ! command -v node &> /dev/null || [[ $(node -v | cut -d. -f1 | tr -d 'v') -lt 20 ]]; then
            echo "⚠️  System Node.js is missing or too old (< v20). Installing local Node v22..."
            mkdir -p "$TOOLBOX_DIR/lib/node"
            curl -L https://nodejs.org/dist/v22.1.0/node-v22.1.0-linux-x86_64.tar.xz | tar -xJ -C "$TOOLBOX_DIR/lib/node" --strip-components=1
            ln -sf "$TOOLBOX_DIR/lib/node/bin/"* "$TOOLBOX_DIR/bin/"
        else
            sudo apt-get install -y nodejs npm
        fi
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y git python3 nodejs npm
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm git python nodejs npm
    fi
}

mkdir -p "$TOOLBOX_DIR"/{bin,lib,include,.config,.gemini/agents}
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    install_deps
fi

cd "$TOOLBOX_DIR"

# --- 1. Tool Acquisition ---
echo "📥 Fetching Neovim..."
curl -L -o bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod +x bin/nvim

echo "📥 Fetching Gemini CLI..."
# Use the toolbox path for npm installation
export PATH="$TOOLBOX_DIR/bin:$PATH"
npm install --prefix "$TOOLBOX_DIR" @google/gemini-cli
ln -sf "$TOOLBOX_DIR/node_modules/.bin/gemini" bin/gemini

echo "📥 Fetching CMake..."
curl -L "https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2-linux-x86_64.tar.gz" | tar -xz -C lib/
ln -sf "$TOOLBOX_DIR"/lib/cmake-*/bin/* bin/

echo "📥 Fetching ARM Toolchain..."
curl -L "https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-arm-none-eabi.tar.xz" | tar -xJ -C lib/
ln -sf "$TOOLBOX_DIR"/lib/arm-gnu-toolchain-*/bin/* bin/

echo "📥 Fetching LLVM/Clang..."
curl -L "https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz" | tar -xJ -C lib/
ln -sf "$TOOLBOX_DIR"/lib/clang+llvm-*/bin/* bin/

# --- 2. Fonts ---
echo "📥 Installing FiraCode Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
curl -L -o "$FONT_DIR/FiraCodeNerdFont-Regular.ttf" https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf
fc-cache -fv > /dev/null

# --- 3. Configuration Setup ---
echo "📥 Cloning Neovim Configuration..."
NVIM_DIR="$TOOLBOX_DIR/.config/nvim"
git clone "$NVIM_CONFIG_REPO" "$NVIM_DIR"
python3 -m venv "$NVIM_DIR/venv"
"$NVIM_DIR/venv/bin/pip" install --quiet --upgrade pip pynvim pyright

if [ "$INCLUDE_AGENT" = true ]; then
    echo "🧠 Setting up MCU Expert Agent..."
    AGENT_DIR="$TOOLBOX_DIR/.gemini/agents/mcu-repo"
    git clone "$MCU_AGENT_REPO" "$AGENT_DIR"
    find "$AGENT_DIR" -name "*.md" -exec ln -sf {} "$TOOLBOX_DIR/.gemini/agents/" \;
fi

# --- 4. Global Activation Script ---
echo "📝 Generating activation script..."
cat <<EOF > activate_lab.sh
#!/bin/bash
# Nucleo Lab Activation Script
export LAB_TOOLBOX="$TOOLBOX_DIR"
export PATH="\$LAB_TOOLBOX/bin:\$PATH"
export XDG_CONFIG_HOME="\$LAB_TOOLBOX/.config"
export XDG_DATA_HOME="\$LAB_TOOLBOX/.local/share"
export XDG_STATE_HOME="\$LAB_TOOLBOX/.local/state"

source "\$LAB_TOOLBOX/.config/nvim/venv/bin/activate"

echo "✅ Nucleo Lab Toolbox Activated!"
echo "🛠️  Tools: nvim, gemini, arm-none-eabi-gcc, clangd, cmake"
EOF

chmod +x activate_lab.sh

echo "=============================================================================="
echo "✨ Toolbox Ready at: $TOOLBOX_DIR"
echo ""
echo "To use these tools in any project:"
echo "source $TOOLBOX_DIR/activate_lab.sh"
echo "=============================================================================="
