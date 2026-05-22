# 🚀 Nucleo Lab Toolbox

A "one-touch" bootstrap script to set up a portable, isolated development environment for bare-metal STM32/Nucleo development.

## ✨ Features

- **Isolated Environment:** Installs all tools into a central `~/.nucleo-toolbox` directory. Does not mess with your system `/usr/bin`.
- **Pre-configured Editor:** Automatically clones your [Neovim configuration](https://github.com/Slepotek/nvim_env) and sets up LSPs (Clangd, Pyright).
- **The Scientific Brain:** Includes the [Gemini MCU Expert Agent](https://github.com/Slepotek/geminiMcuAgent) for documentation-backed guidance.
- **Full Toolchain:**
  - **Neovim** (Latest AppImage)
  - **Gemini CLI** (Node v22 managed)
  - **ARM GNU Toolchain** (GCC, GDB)
  - **LLVM/Clang** (clangd, analysis)
  - **CMake & Make**
  - **FiraCode Nerd Font**

## 🚀 Quick Start

Run this command in your terminal to set up the environment:

```bash
curl -sSL https://raw.githubusercontent.com/Slepotek/nucleo-bootstrap/main/bootstrap_lab.sh | bash
```

## 🛠️ Usage

Once the installation is complete, you can "enter the lab" in any directory:

```bash
# Go to your project folder
cd ~/my-stm32-project

# Activate the toolbox
source ~/.nucleo-toolbox/activate_lab.sh

# Start coding
nvim .

# Consult the brain (in a separate terminal)
gemini
```

## 💻 WSL / Windows Terminal Users

To see the icons in the Neovim statusline, you **must** manually install the **FiraCode Nerd Font** on your Windows host machine.

1. Download from [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip).
2. Install the `.ttf` files in Windows.
3. In Windows Terminal Settings, set the font for your WSL profile to `FiraCode NF`.

## ⚠️ Caveats

- **Linux Only:** Currently tested on Debian/Ubuntu, Fedora, and Arch.
- **Node.js:** The script requires Node v20+. If your system version is too old, it will download a portable Node v22 binary automatically.
- **Sudo:** The script uses `sudo apt-get` (or equivalent) only once at the beginning to install core system dependencies (`git`, `python3-venv`, `curl`).

---
*Created by Slepotek for the Nucleo Skill Recovery Journey.*
