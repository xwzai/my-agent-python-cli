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

echo -e "${GREEN}🚀 My Agent Python CLI Installer${NC}\n"

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
    echo -e "${RED}❌ Unsupported platform: ${OS}${NC}"
    exit 1
fi

# Check Python
echo -e "\n🔍 Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo -e "${RED}❌ Python is not installed. Please install Python 3.7+ first.${NC}"
    echo "   Download from: https://www.python.org/downloads/"
    exit 1
fi

PYTHON_VERSION=$(${PYTHON_CMD} --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
echo "   Found Python ${PYTHON_VERSION}"

# Check pip
echo -e "\n🔍 Checking pip..."
if ! ${PYTHON_CMD} -m pip --version &> /dev/null; then
    echo -e "${RED}❌ pip is not installed. Installing pip...${NC}"
    ${PYTHON_CMD} -m ensurepip --upgrade || {
        echo -e "${RED}❌ Failed to install pip. Please install pip manually.${NC}"
        exit 1
    }
fi
echo "   pip is available"

# Uninstall existing version
echo -e "\n🧹 Checking for existing installation..."
if ${PYTHON_CMD} -m pip show my-agent-python-cli &> /dev/null; then
    echo "   Found existing installation, removing..."
    ${PYTHON_CMD} -m pip uninstall my-agent-python-cli -y || true
fi

# Get pip user install directory
echo -e "\n🔍 Checking pip user install directory..."
USER_BASE=$(${PYTHON_CMD} -m site --user-base)
if [ "${PLATFORM}" = "Windows" ]; then
    BIN_DIR="${USER_BASE}/Scripts"
else
    BIN_DIR="${USER_BASE}/bin"
fi
echo "   Bin directory: ${BIN_DIR}"

# Create temp directory
echo -e "\n📥 Downloading package..."
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

WHL_URL="https://github.com/${REPO}/releases/download/${VERSION}/${PACKAGE_NAME}"

echo "   URL: ${WHL_URL}"

# Download with curl or wget
if command -v curl &> /dev/null; then
    curl -fsSL "${WHL_URL}" -o "${TEMP_DIR}/${PACKAGE_NAME}" || {
        echo -e "${RED}❌ Download failed. Please check your internet connection.${NC}"
        exit 1
    }
elif command -v wget &> /dev/null; then
    wget -q "${WHL_URL}" -O "${TEMP_DIR}/${PACKAGE_NAME}" || {
        echo -e "${RED}❌ Download failed. Please check your internet connection.${NC}"
        exit 1
    }
else
    echo -e "${RED}❌ Neither curl nor wget is installed.${NC}"
    exit 1
fi

echo -e "${GREEN}   ✓ Downloaded successfully${NC}"

# Install
echo -e "\n📦 Installing..."
${PYTHON_CMD} -m pip install "${TEMP_DIR}/${PACKAGE_NAME}" --user --force-reinstall || {
    echo -e "\n${YELLOW}⚠️  User install failed, trying system install...${NC}"
    ${PYTHON_CMD} -m pip install "${TEMP_DIR}/${PACKAGE_NAME}" --force-reinstall || {
        echo -e "${RED}❌ Installation failed${NC}"
        exit 1
    }
    BIN_DIR=""  # System install, no need to add to PATH
}

echo -e "${GREEN}   ✓ Installation complete${NC}"

# Check if command is available
echo -e "\n🔍 Verifying installation..."
if command -v my-agent-py &> /dev/null; then
    echo -e "${GREEN}   ✓ Command 'my-agent-py' is available${NC}"
    my-agent-py --version
else
    # Need to add to PATH
    echo -e "${YELLOW}⚠️  Command not found in PATH${NC}"
    
    if [ -n "${BIN_DIR}" ]; then
        echo -e "\n${BLUE}📝 Adding to PATH...${NC}"
        
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
            echo -e "${YELLOW}   ${BIN_DIR} is already in PATH${NC}"
            echo -e "${YELLOW}   Please restart your terminal or run: source ${SHELL_CONFIG}${NC}"
        else
            # Add to shell config
            echo -e "\n# My Agent Python CLI\nexport PATH=\"${BIN_DIR}:\$PATH\"" >> "${SHELL_CONFIG}"
            echo -e "${GREEN}   ✓ Added ${BIN_DIR} to PATH in ${SHELL_CONFIG}${NC}"
            echo -e "\n${YELLOW}💡 Please run the following command to use 'my-agent-py':${NC}"
            echo -e "   ${BLUE}source ${SHELL_CONFIG}${NC}"
            echo ""
            echo -e "   Or restart your terminal."
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}Meanwhile, you can use:${NC}"
    echo "   ${PYTHON_CMD} -m my_agent_python_cli"
fi

echo -e "\n${GREEN}✅ My Agent Python CLI installed successfully!${NC}\n"
echo "📚 Quick start:"
echo "   my-agent-py --help"
echo "   my-agent-py status"

# Check if command is in PATH for Windows Git Bash
if [ "${PLATFORM}" = "Windows" ]; then
    echo -e "\n${YELLOW}💡 Windows users:${NC}"
    echo "   If 'my-agent-py' command is not found after restarting, try:"
    echo "   1. Close and reopen Git Bash/Terminal"
    echo "   2. Add to PATH manually: ${BIN_DIR}"
    echo "   3. Or use: python -m my_agent_python_cli"
fi

echo ""
