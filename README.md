# cf (Choose Folder)

**`cf`** is a minimalist, keyboard-driven terminal directory navigator and instant shell directory switcher. Built with pure Python and `curses`, it brings visual arrow-key exploration to your command line with zero external dependencies.

---

## 🚀 Installation

### Option 1: Quick Install (One-Liner)
Install instantly without cloning the repo:

```bash
curl -fsSL https://raw.githubusercontent.com/nagachaitanyaappana/cf/main/install.sh | bash
```

After installation, reload your shell:
```bash
source ~/.bashrc   # or: source ~/.zshrc
```

---

### Option 2: Clone & Install

```bash
git clone https://github.com/nagachaitanyaappana/cf.git
cd cf
chmod +x install.sh
./install.sh
```

> **For Developers:** Pass `--link` to create a live symlink instead of copying:
> ```bash
> ./install.sh --link
> ```

---

## ⌨️ Keybindings & Controls

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
| **`←`** or **`Backspace`** | Return back to directory view |
| **`q`** or **`Esc`** | Cancel and quit |

---

## 🧩 Shell Compatibility

`install.sh` automatically configures shell integration for:
- **Bash** (`~/.bashrc`)
- **Zsh** (`~/.zshrc`)
- **Fish** (`~/.config/fish/functions/cf.fish`)

### Manual Setup
If you want to configure it manually, add this function to your `~/.bashrc` or `~/.zshrc`:

```bash
cf() {
    local dir
    dir=$(python3 ~/.local/bin/cf/cf.py)

    if [[ -n "$dir" ]]; then
        cd "$dir"
    fi
}
```

---

## 💡 How It Works

Because child processes (like Python) cannot modify the working directory of the parent shell, `cf` uses an elegant two-stage workflow:
1. `cf.py` redirects its interactive `curses` UI directly to `/dev/tty`.
2. When a directory is chosen, `cf.py` writes only the selected directory path string to standard output.
3. The shell wrapper intercepts stdout (`dir=$(python3 ...)`) and executes `cd "$dir"` inside your active terminal session.

---

## 🗑️ Uninstallation

Run the uninstaller script:
```bash
curl -fsSL https://raw.githubusercontent.com/nagachaitanyaappana/cf/main/uninstall.sh | bash
```
Or from a cloned directory:
```bash
./uninstall.sh
```
