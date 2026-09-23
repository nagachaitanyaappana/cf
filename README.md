# cf (Choose Folder)

**`cf`** is an interactive, curses-based terminal directory browser and quick-switcher. It lets you explore and jump across directory trees effortlessly using arrow-key navigation.

---

## Features

- **Arrow-Key Navigation:** Browse directories using intuitive `↑`, `↓`, `←`, `→` and `Enter`.
- **Fast Directory Jumping:** Changes your current active shell session directory upon selection.
- **Recent Folders History:** Automatically tracks recently visited directories (`r` key) with quick jump access.
- **Smooth Viewport Scrolling:** Handles large directories with dozens or hundreds of folders without display glitching.
- **Smart Backtracking:** Returning up to a parent folder automatically preserves cursor position on the folder you just left.
- **Zero Heavy Dependencies:** Written entirely in pure Python using standard library `curses` and `os`.

---

## Keybindings & Controls

### Main Folder Picker
| Key | Action |
| :--- | :--- |
| **`↑` / `↓`** (or `k` / `j`) | Move the selection highlight up / down |
| **`Enter`** or **`→`** (or `l`) | Open the highlighted directory (drill down) |
| **`Space`** | Select current directory and `cd` into it *(or `Enter` if directory is empty)* |
| **`←`** or **`Backspace`** (or `h`) | Step back up to parent directory |
| **`Home`** / **`End`** | Jump to start / end of list |
| **`Page Up`** / **`Page Down`** | Scroll one page up / down |
| **`r`** | Open Recent Folders picker |
| **`q`** or **`Esc`** | Cancel and quit without changing directory |

### Recent Folders Picker (`r`)
| Key | Action |
| :--- | :--- |
| **`↑` / `↓`** (or `k` / `j`) | Navigate recent folders |
| **`Enter`** or **`Space`** | Select and `cd` into highlighted recent folder |
| **`←`** or **`Backspace`** | Return back to folder view |
| **`q`** or **`Esc`** | Cancel and quit |

---

## Installation & Setup

### 1. Run the Installer
```bash
cd ~/Projects/cf
chmod +x install.sh
./install.sh
```

The installer symlinks `cf.py` to `~/.local/bin/cf/cf.py` and registers the `cf()` function in your `~/.bashrc` (or `~/.zshrc`).

### 2. Manual Shell Integration
If you prefer manual setup, add this function to your `~/.bashrc` or `~/.zshrc`:

```bash
cf() {
    local dir
    dir=$(python3 ~/.local/bin/cf/cf.py)

    if [[ -n "$dir" ]]; then
        cd "$dir"
    fi
}
```

Then reload your shell:
```bash
source ~/.bashrc
```

---

## How It Works

Because a child process (like Python) cannot directly change the working directory of its parent shell, `cf` uses a two-stage approach:
1. `cf.py` redirects its interactive `curses` UI directly to `/dev/tty`.
2. When you confirm a directory, `cf.py` outputs only the chosen path string to standard output.
3. The shell wrapper captures this path (`dir=$(python3 ...)`) and executes `cd "$dir"`.
