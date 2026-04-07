#!/bin/bash

set -e

REPO="xwzai/my-agent-python-cli"
VERSION="v1.0.0"
PACKAGE_NAME="my_agent_python_cli-1.0.0-py3-none-any.whl"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

printf "${GREEN}🚀 My Agent Python CLI Installer${NC}\n\n"

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM='Linux';;
    Darwin*)    PLATFORM='macOS';;
    CYGWIN*)    PLATFORM='Windows';;
    MINGW*)     PLATFORM='Windows';;
    MSYS*)      PLATFORM='Windows';;
    *)          PLATFORM='UNKNOWN';;
esac

echo "📦 Platform detected: ${PLATFORM}"

if [ "${PLATFORM}" = "UNKNOWN" ]; then
    printf "${RED}❌ Unsupported platform: ${OS}${NC}\n"
    exit 1
fi

# Check Python
printf "\n🔍 Checking Python...\n"
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    printf "${RED}❌ Python is not installed. Please install Python 3.7+ first.${NC}\n"
    echo "   Download from: https://www.python.org/downloads/"
    exit 1
fi

PYTHON_VERSION=$(${PYTHON_CMD} --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
echo "   Found Python ${PYTHON_VERSION}"

# Check pip
printf "\n🔍 Checking pip...\n"
if ! ${PYTHON_CMD} -m pip --version &> /dev/null; then
    printf "${RED}❌ pip is not installed. Installing pip...${NC}\n"
    ${PYTHON_CMD} -m ensurepip --upgrade || {
        printf "${RED}❌ Failed to install pip. Please install pip manually.${NC}\n"
        exit 1
    }
fi
echo "   pip is available"

# Uninstall existing version
printf "\n🧹 Checking for existing installation...\n"
if ${PYTHON_CMD} -m pip show my-agent-python-cli &> /dev/null; then
    echo "   Found existing installation, removing..."
    ${PYTHON_CMD} -m pip uninstall my-agent-python-cli -y || true
fi

# Get pip user install directory
printf "\n🔍 Checking pip user install directory...\n"
USER_BASE=$(${PYTHON_CMD} -m site --user-base)
if [ "${PLATFORM}" = "Windows" ]; then
    BIN_DIR="${USER_BASE}/Scripts"
else
    BIN_DIR="${USER_BASE}/bin"
fi
echo "   Bin directory: ${BIN_DIR}"

# Create temp directory
printf "\n📥 Downloading package...\n"
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

WHL_URL="https://github.com/${REPO}/releases/download/${VERSION}/${PACKAGE_NAME}"

echo "   URL: ${WHL_URL}"

# Download with curl or wget
if command -v curl &> /dev/null; then
    curl -fsSL "${WHL_URL}" -o "${TEMP_DIR}/${PACKAGE_NAME}" || {
        printf "${RED}❌ Download failed. Please check your internet connection.${NC}\n"
        exit 1
    }
elif command -v wget &> /dev/null; then
    wget -q "${WHL_URL}" -O "${TEMP_DIR}/${PACKAGE_NAME}" || {
        printf "${RED}❌ Download failed. Please check your internet connection.${NC}\n"
        exit 1
    }
else
    printf "${RED}❌ Neither curl nor wget is installed.${NC}\n"
    exit 1
fi

printf "${GREEN}   ✓ Downloaded successfully${NC}\n"

# Install
printf "\n📦 Installing...\n"
${PYTHON_CMD} -m pip install "${TEMP_DIR}/${PACKAGE_NAME}" --user --force-reinstall || {
    printf "\n${YELLOW}⚠️  User install failed, trying system install...${NC}\n"
    ${PYTHON_CMD} -m pip install "${TEMP_DIR}/${PACKAGE_NAME}" --force-reinstall || {
        printf "${RED}❌ Installation failed${NC}\n"
        exit 1
    }
    BIN_DIR=""  # System install, no need to add to PATH
}

printf "${GREEN}   ✓ Installation complete${NC}\n"

# Check if command is available
printf "\n🔍 Verifying installation...\n"
if command -v my-agent-py &> /dev/null; then
    printf "${GREEN}   ✓ Command 'my-agent-py' is available${NC}\n"
    my-agent-py --version
else
    # Need to add to PATH
    printf "${YELLOW}⚠️  Command not found in PATH${NC}\n"
    
    if [ -n "${BIN_DIR}" ]; then
        printf "\n${BLUE}📝 Adding to PATH...${NC}\n"
        
        # Detect shell
        if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "/bin/bash" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
            # On macOS, prefer .bash_profile
            [ -f "$HOME/.bash_profile" ] && SHELL_CONFIG="$HOME/.bash_profile"
        else
            SHELL_CONFIG="$HOME/.profile"
        fi
        
        # Check if already in PATH
        if [[ ":$PATH:" == *":${BIN_DIR}:"* ]]; then
            printf "${YELLOW}   ${BIN_DIR} is already in PATH${NC}\n"
            printf "${YELLOW}   Please restart your terminal or run: source ${SHELL_CONFIG}${NC}\n"
        else
            # Add to shell config
            printf "\n# My Agent Python CLI\nexport PATH=\"${BIN_DIR}:\$PATH\"\n" >> "${SHELL_CONFIG}"
            printf "${GREEN}   ✓ Added ${BIN_DIR} to PATH in ${SHELL_CONFIG}${NC}\n"
            
            # Export PATH for current subshell (won't affect parent, but good practice)
            export PATH="${BIN_DIR}:$PATH"
            
            echo ""
            echo "╔══════════════════════════════════════════════════════════════╗"
            echo "║                                                              ║"
            printf "║  ${YELLOW}⚠️  请执行以下命令使 PATH 生效:${NC}                           ║\n"
            printf "║  ${BLUE}source ${SHELL_CONFIG}${NC}                                     ║\n"
            echo "║                                                              ║"
            echo "║  或者重新打开终端窗口                                         ║"
            echo "╚══════════════════════════════════════════════════════════════╝"
            echo ""
        fi
    fi
    
    echo ""
    printf "${YELLOW}Meanwhile, you can use:${NC}\n"
    echo "   ${PYTHON_CMD} -m my_agent_python_cli"
fi

printf "\n${GREEN}✅ My Agent Python CLI installed successfully!${NC}\n\n"
echo "📚 Quick start:"
echo "   my-agent-py --help"
echo "   my-agent-py status"

# Check if command is in PATH for Windows Git Bash
if [ "${PLATFORM}" = "Windows" ]; then
    printf "\n${YELLOW}💡 Windows users:${NC}\n"
    echo "   If 'my-agent-py' command is not found after restarting, try:"
    echo "   1. Close and reopen Git Bash/Terminal"
    echo "   2. Add to PATH manually: ${BIN_DIR}"
    echo "   3. Or use: python -m my_agent_python_cli"
fi

echo ""
