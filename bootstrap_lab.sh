#!/bin/bash

# ==============================================================================
# 🚀 Nucleo Lab: Portable Environment Toolbox
# ==============================================================================
set -e

TOOLBOX_DIR="$HOME/.nucleo-toolbox"
INCLUDE_AGENT=true
NVIM_CONFIG_REPO="https://github.com/Slepotek/nvim_env.git"
MCU_AGENT_REPO="https://github.com/Slepotek/geminiMcuAgent.git"

usage() {
    cat <<EOF
🚀 Nucleo Lab Toolbox Bootstrap
Usage: bootstrap.sh [options]
EOF
    exit 0
}

while [ $# -ne 0 ]; do
    case "$1" in
        --path) TOOLBOX_DIR="$2"; shift ;;
        --no-agent) INCLUDE_AGENT=false ;;
        --help) usage ;;
    esac
    shift
done

echo "🛠️  Initializing Lab Toolbox at: $TOOLBOX_DIR"

# --- 0. System Dependency Auto-Install ---
install_deps() {
    if command -v apt-get &> /dev/null; then
        echo "📦 Detected Debian/Ubuntu. Installing dependencies..."
        sudo apt-get update -qq && sudo apt-get install -y git python3-venv curl xz-utils file
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y git python3 nodejs npm xz file
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm git python nodejs npm xz file
    fi
}

mkdir -p "$TOOLBOX_DIR"/{bin,lib,include,.config,.gemini/agents}
[[ "$OSTYPE" == "linux-gnu"* ]] && install_deps

cd "$TOOLBOX_DIR"

# --- Helper: Safe Download & Extract ---
safe_download_extract() {
    local url=$1
    local dest=$2
    local strip=$3
    echo "📥 Downloading from: $url"
    local tmp_file=$(mktemp)
    curl -fsSL -o "$tmp_file" "$url"
    if ! file "$tmp_file" | grep -E "archive|compressed|data" > /dev/null; then
        echo "❌ Error: Invalid archive from $url"
        rm -f "$tmp_file"; exit 1
    fi
    mkdir -p "$dest"
    if [[ "$url" == *.tar.gz ]]; then
        tar -xz -f "$tmp_file" -C "$dest" --strip-components="$strip"
    else
        tar -xJ -f "$tmp_file" -C "$dest" --strip-components="$strip"
    fi
    rm -f "$tmp_file"
}

# --- 1. Tool Acquisition ---
echo "📥 Fetching Neovim..."
curl -fsSL -o bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod +x bin/nvim

# Handle Node.js (Corrected URL for linux-x64)
if ! command -v node &> /dev/null || [ $(node -v | cut -d. -f1 | tr -d 'v') -lt 20 ]; then
    echo "⚠️  System Node.js too old. Installing local Node v22..."
    safe_download_extract "https://nodejs.org/dist/v22.1.0/node-v22.1.0-linux-x64.tar.xz" "$TOOLBOX_DIR/lib/node" 1
    ln -sf "$TOOLBOX_DIR/lib/node/bin/"* "$TOOLBOX_DIR/bin/"
fi

echo "📥 Fetching Gemini CLI..."
export PATH="$TOOLBOX_DIR/bin:$PATH"
npm install --prefix "$TOOLBOX_DIR" @google/gemini-cli
ln -sf "$TOOLBOX_DIR/node_modules/.bin/gemini" bin/gemini

echo "📥 Fetching CMake..."
safe_download_extract "https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2-linux-x86_64.tar.gz" "$TOOLBOX_DIR/lib/cmake" 1
ln -sf "$TOOLBOX_DIR"/lib/cmake/bin/* bin/

echo "📥 Fetching ARM Toolchain..."
safe_download_extract "https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-x86_64-arm-none-eabi.tar.xz" "$TOOLBOX_DIR/lib/arm-gcc" 1
ln -sf "$TOOLBOX_DIR"/lib/arm-gcc/bin/* bin/

echo "📥 Fetching LLVM/Clang..."
safe_download_extract "https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz" "$TOOLBOX_DIR/lib/llvm" 1
ln -sf "$TOOLBOX_DIR"/lib/llvm/bin/* bin/

# --- 2. Fonts & Config ---
echo "📥 Installing FiraCode Nerd Font..."
mkdir -p "$HOME/.local/share/fonts"
curl -fsSL -o "$HOME/.local/share/fonts/FiraCodeNerdFont-Regular.ttf" https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf
fc-cache -fv > /dev/null

echo "📥 Cloning Configuration..."
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

# --- 3. Activation ---
cat <<EOF > activate_lab.sh
#!/bin/bash
export LAB_TOOLBOX="$TOOLBOX_DIR"
export PATH="\$LAB_TOOLBOX/bin:\$PATH"
export XDG_CONFIG_HOME="\$LAB_TOOLBOX/.config"
export XDG_DATA_HOME="\$LAB_TOOLBOX/.local/share"
export XDG_STATE_HOME="\$LAB_TOOLBOX/.local/state"
source "\$LAB_TOOLBOX/.config/nvim/venv/bin/activate"
echo "✅ Lab Activated!"
EOF
chmod +x activate_lab.sh

echo "=============================================================================="
echo "✨ Toolbox Ready! Run: source $TOOLBOX_DIR/activate_lab.sh"
echo "=============================================================================="
