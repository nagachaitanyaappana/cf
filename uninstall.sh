#!/usr/bin/env bash
set -e

echo "Uninstalling cf (Choose Folder)..."

rm -rf "$HOME/.local/bin/cf"
echo "✓ Removed ~/.local/bin/cf"

remove_from_rc() {
    local rc_file="$1"
    if [ -f "$rc_file" ] && grep -q "cf()" "$rc_file"; then
        # Remove cf() block
        sed -i.bak '/# cf (Choose Folder)/,+7d' "$rc_file" 2>/dev/null || true
        rm -f "${rc_file}.bak"
        echo "✓ Removed cf integration from $rc_file"
    fi
}

remove_from_rc "$HOME/.bashrc"
remove_from_rc "$HOME/.zshrc"

if [ -f "$HOME/.config/fish/functions/cf.fish" ]; then
    rm -f "$HOME/.config/fish/functions/cf.fish"
    echo "✓ Removed ~/.config/fish/functions/cf.fish"
fi

echo ""
echo "Uninstallation complete. Note: recent history file in ~/.local/share/cf was kept."
echo "To remove recent history as well, run: rm -rf ~/.local/share/cf"
