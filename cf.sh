# Shell function for cf (Choose Folder)
# Add this to your ~/.bashrc or ~/.zshrc

cf() {
    local dir
    dir=$(python3 ~/.local/bin/cf/cf.py)

    if [[ -n "$dir" ]]; then
        cd "$dir"
    fi
}
