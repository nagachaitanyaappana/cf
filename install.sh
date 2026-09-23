#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin/cf"
DATA_DIR="$HOME/.local/share/cf"

echo "Installing cf (Choose Folder)..."

# Ensure directories exist
mkdir -p "$BIN_DIR"
mkdir -p "$DATA_DIR"

# Make script executable
chmod +x "$SCRIPT_DIR/cf.py"

# Symlink cf.py to ~/.local/bin/cf/cf.py
ln -sf "$SCRIPT_DIR/cf.py" "$BIN_DIR/cf.py"
echo "✓ Linked $SCRIPT_DIR/cf.py -> $BIN_DIR/cf.py"

# Check shell rc files
SHELL_SNIPPET='cf() {
    local dir
    dir=$(python3 ~/.local/bin/cf/cf.py)

    if [[ -n "$dir" ]]; then
        cd "$dir"
    fi
}'

add_to_rc() {
    local rc_file="$1"
    if [ -f "$rc_file" ]; then
        if grep -q "cf()" "$rc_file"; then
            echo "✓ cf() function already exists in $rc_file"
        else
            echo "" >> "$rc_file"
            echo "# cf (Choose Folder)" >> "$rc_file"
            echo "$SHELL_SNIPPET" >> "$rc_file"
            echo "✓ Added cf() function to $rc_file"
        fi
    fi
}

add_to_rc "$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && add_to_rc "$HOME/.zshrc"

echo ""
echo "Installation complete! Restart your shell or run:"
echo "  source ~/.bashrc"
