# cf (Choose Folder)

**`cf`** is a minimalist, keyboard-driven terminal directory navigator and instant shell directory switcher. Built with Python and `curses`, it brings visual arrow-key exploration to your command line across **Linux**, **macOS**, and **Windows** with zero heavy dependencies.

---

## 🚀 Installation

### 🐧 Linux & 🍎 macOS

#### Option 1: Quick Install (One-Liner)
Install instantly via curl without cloning the repo:

```bash
curl -fsSL https://raw.githubusercontent.com/nagachaitanyaappana/cf/main/install.sh | bash
```

Reload your shell configuration:
```bash
source ~/.bashrc   # or: source ~/.zshrc
```

#### Option 2: Clone & Install
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

### 🪟 Windows

`cf` works on Windows inside **PowerShell**, **Command Prompt (CMD)**, **Windows Terminal**, and **Git Bash / WSL**.

#### Option 1: PowerShell Quick Install (One-Liner)
Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/nagachaitanyaappana/cf/main/install.ps1 | iex
```

Reload your PowerShell profile:
```powershell
. $PROFILE
```

#### Option 2: Clone & Install
```powershell
git clone https://github.com/nagachaitanyaappana/cf.git
cd cf
.\install.ps1
```

*(Note: On Windows, the installer automatically installs the lightweight `windows-curses` package if needed and sets up both PowerShell and CMD wrappers).*

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

The installer automatically detects and integrates with:
- **Bash** (`~/.bashrc`)
- **Zsh** (`~/.zshrc`)
- **Fish** (`~/.config/fish/functions/cf.fish`)
- **PowerShell** (`$PROFILE`)
- **Command Prompt (CMD)** (`%USERPROFILE%\.local\bin\cf\cf.cmd`)

### Manual Shell Integration
If you prefer manual configuration without running an installer:

#### Bash / Zsh
Add to `~/.bashrc` or `~/.zshrc`:
```bash
cf() {
    local dir
    dir=$(python3 ~/.local/bin/cf/cf.py)

    if [[ -n "$dir" ]]; then
        cd "$dir"
    fi
}
```

#### Fish
Add to `~/.config/fish/functions/cf.fish`:
```fish
function cf --description "Choose Folder interactive directory switcher"
    set -l dir (python3 ~/.local/bin/cf/cf.py)
    if test -n "$dir"
        cd "$dir"
    end
end
```

#### PowerShell
Add to your `$PROFILE`:
```powershell
function cf {
    $dir = python "$HOME\.local\bin\cf\cf.py"
    if ($dir -and (Test-Path $dir)) {
        Set-Location $dir
    }
}
```

---

## 💡 How It Works

Because a child process (like a Python script) runs in its own subshell and cannot directly modify the working directory of the parent shell, `cf` uses a two-stage design:
1. `cf.py` redirects its interactive `curses` UI directly to the terminal console device (`/dev/tty` on Unix, `CONOUT$` on Windows).
2. When a directory is chosen, `cf.py` prints only the final path to standard output.
3. The shell wrapper intercepts stdout (`dir=$(python3 ...)`) and executes `cd "$dir"` inside your active terminal session.

---

## 🗑️ Uninstallation

### Linux / macOS
```bash
curl -fsSL https://raw.githubusercontent.com/nagachaitanyaappana/cf/main/uninstall.sh | bash
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/nagachaitanyaappana/cf/main/uninstall.ps1 | iex
```
