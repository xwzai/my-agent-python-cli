#!/bin/bash

set -e

REPO="xwzai/my-agent-python-cli"
VERSION="v1.0.0"
PACKAGE_NAME="my_agent_python_cli-1.0.0-py3-none-any.whl"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
${PYTHON_CMD} -m pip install "${TEMP_DIR}/${PACKAGE_NAME}" --user --upgrade || {
    echo -e "\n${YELLOW}⚠️  User install failed, trying system install...${NC}"
    ${PYTHON_CMD} -m pip install "${TEMP_DIR}/${PACKAGE_NAME}" --upgrade || {
        echo -e "${RED}❌ Installation failed${NC}"
        exit 1
    }
}

echo -e "${GREEN}   ✓ Installation complete${NC}"

# Verify
echo -e "\n🔍 Verifying installation..."
if command -v my-agent-py &> /dev/null; then
    echo -e "${GREEN}   ✓ Command 'my-agent-py' is available${NC}"
    my-agent-py --version
elif ${PYTHON_CMD} -m my_agent_python_cli &> /dev/null; then
    echo -e "${YELLOW}⚠️  Command not in PATH, but module is installed${NC}"
    echo "   You can run: python -m my_agent_python_cli"
else
    echo -e "${YELLOW}⚠️  Installation succeeded but command not found${NC}"
    echo "   Please restart your terminal or run:"
    if [ "${PLATFORM}" = "Windows" ]; then
        echo "   - Windows: Refresh environment variables or restart terminal"
    else
        echo "   - macOS/Linux: source ~/.bashrc or ~/.zshrc"
    fi
fi

echo -e "\n${GREEN}✅ My Agent Python CLI installed successfully!${NC}\n"
echo "📚 Quick start:"
echo "   my-agent-py --help"
echo "   my-agent-py status"

# Check if command is in PATH for Windows Git Bash
if [ "${PLATFORM}" = "Windows" ]; then
    echo -e "\n${YELLOW}💡 Windows users:${NC}"
    echo "   If 'my-agent-py' command is not found, try:"
    echo "   1. Close and reopen Git Bash/Terminal"
    echo "   2. Or run: python -m site --user-base"
    echo "   3. Add that path + '/Scripts' to your PATH"
fi

echo ""
