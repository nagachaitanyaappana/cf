#!/usr/bin/env bash
set -e

REPO_RAW_URL="https://raw.githubusercontent.com/nagachaitanyaappana/cf/main/cf.py"
BIN_DIR="$HOME/.local/bin/cf"
DATA_DIR="$HOME/.local/share/cf"
TARGET_FILE="$BIN_DIR/cf.py"

echo "========================================="
echo "  Installing cf (Choose Folder)          "
echo "========================================="

# 1. Check Python 3
if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: Python 3 is required but not installed." >&2
    exit 1
fi

# 2. Ensure directories exist
mkdir -p "$BIN_DIR"
mkdir -p "$DATA_DIR"

# 3. Determine installation mode (copy, symlink, or download)
LINK_MODE=false
for arg in "$@"; do
    if [ "$arg" = "--link" ] || [ "$arg" = "-l" ]; then
        LINK_MODE=true
    fi
done

# Check if script is running from within cloned repo
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/cf.py" ]; then
    if [ "$LINK_MODE" = true ]; then
        ln -sf "$SCRIPT_DIR/cf.py" "$TARGET_FILE"
        echo "✓ Symlinked: $TARGET_FILE -> $SCRIPT_DIR/cf.py"
    else
        cp "$SCRIPT_DIR/cf.py" "$TARGET_FILE"
        chmod +x "$TARGET_FILE"
        echo "✓ Installed: $TARGET_FILE"
    fi
else
    echo "Downloading cf.py from GitHub..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_RAW_URL" -o "$TARGET_FILE"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$TARGET_FILE" "$REPO_RAW_URL"
    else
        echo "Error: curl or wget required to download cf.py" >&2
        exit 1
    fi
    chmod +x "$TARGET_FILE"
    echo "✓ Downloaded and installed: $TARGET_FILE"
fi

# 4. Configure Shell Integration
SHELL_SNIPPET='cf() {
    local dir
    dir=$(python3 ~/.local/bin/cf/cf.py)

    if [[ -n "$dir" ]]; then
        cd "$dir"
    fi
}'

add_to_rc() {
    local rc_file="$1"
    local shell_name="$2"
    if [ -f "$rc_file" ]; then
        if grep -q "cf()" "$rc_file"; then
            echo "✓ cf() function already present in $rc_file"
        else
            echo "" >> "$rc_file"
            echo "# cf (Choose Folder)" >> "$rc_file"
            echo "$SHELL_SNIPPET" >> "$rc_file"
            echo "✓ Added cf() integration to $rc_file ($shell_name)"
        fi
    fi
}

add_to_rc "$HOME/.bashrc" "Bash"
[ -f "$HOME/.zshrc" ] && add_to_rc "$HOME/.zshrc" "Zsh"

# Fish Shell support
FISH_FUNC_DIR="$HOME/.config/fish/functions"
if [ -d "$HOME/.config/fish" ] || command -v fish >/dev/null 2>&1; then
    mkdir -p "$FISH_FUNC_DIR"
    cat << 'EOF' > "$FISH_FUNC_DIR/cf.fish"
function cf --description "Choose Folder interactive directory switcher"
    set -l dir (python3 ~/.local/bin/cf/cf.py)
    if test -n "$dir"
        cd "$dir"
    end
end
EOF
    echo "✓ Added Fish function to $FISH_FUNC_DIR/cf.fish"
fi

echo ""
echo "========================================="
echo "  Installation Successful! 🎉           "
echo "========================================="
echo "To start using 'cf', restart your shell or run:"
echo "  source ~/.bashrc   # (or source ~/.zshrc)"
echo "Then simply type: cf"
