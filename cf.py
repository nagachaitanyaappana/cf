#!/usr/bin/env python3
import curses
import os
import sys

# Reduce Esc key delay in curses (default is 1000ms)
os.environ.setdefault("ESCDELAY", "25")

RECENTS_FILE = os.path.expanduser("~/.local/share/cf/recent")
MAX_RECENTS = 20


def get_directories(path):
    """Return visible directories inside path."""
    try:
        directories = sorted(
            name
            for name in os.listdir(path)
            if os.path.isdir(os.path.join(path, name))
            and not name.startswith(".")
        )
    except PermissionError:
        directories = []

    return directories


def load_recents():
    """Load recent directories."""
    if not os.path.exists(RECENTS_FILE):
        return []

    try:
        with open(RECENTS_FILE, "r") as f:
            paths = [line.strip() for line in f if line.strip()]
    except (OSError, UnicodeError):
        return []

    # Remove missing directories and duplicates
    valid = []
    seen = set()

    for path in paths:
        path = os.path.abspath(os.path.expanduser(path))

        if path not in seen and os.path.isdir(path):
            valid.append(path)
            seen.add(path)

    return valid[:MAX_RECENTS]


def save_recent(path):
    """Add a directory to recent history."""
    path = os.path.abspath(path)

    if not os.path.isdir(path):
        return

    os.makedirs(os.path.dirname(RECENTS_FILE), exist_ok=True)

    recents = load_recents()

    # Put newest first
    recents = [path] + [p for p in recents if p != path]
    recents = recents[:MAX_RECENTS]

    try:
        with open(RECENTS_FILE, "w") as f:
            for item in recents:
                f.write(item + "\n")
    except OSError:
        pass


def display_path(path):
    """Display paths using ~ for the home directory."""
    home = os.path.expanduser("~")

    if path == home:
        return "~"

    if path.startswith(home + os.sep):
        return "~" + path[len(home):]

    return path


def safe_addstr(stdscr, y, x, text, attr=0):
    """Safely print string without overflowing curses window boundary."""
    max_y, max_x = stdscr.getmaxyx()
    if 0 <= y < max_y and 0 <= x < max_x:
        max_len = max_x - x - 1
        if max_len > 0:
            try:
                stdscr.addstr(y, x, text[:max_len], attr)
            except curses.error:
                pass


def recent_picker(stdscr):
    """Show the recent folders menu with arrow navigation."""
    selected_idx = 0
    scroll_offset = 0

    while True:
        recents = load_recents()
        max_y, max_x = stdscr.getmaxyx()
        stdscr.clear()

        safe_addstr(stdscr, 0, 0, "🕘 Recent Folders", curses.A_BOLD)

        if not recents:
            safe_addstr(stdscr, 2, 0, "No recent folders yet.")
            safe_addstr(stdscr, 4, 0, "← / Backspace: Back   q: Quit")
            stdscr.refresh()

            key = stdscr.getch()
            if key in (ord("q"), ord("Q"), 27, curses.KEY_BACKSPACE, 127, 8, curses.KEY_LEFT):
                return None
            continue

        selected_idx = max(0, min(selected_idx, len(recents) - 1))

        safe_addstr(
            stdscr,
            1,
            0,
            "↑/↓: Navigate   Enter / Space: Select   ←/Backspace: Back   q: Quit",
        )

        header_lines = 3
        max_visible = max(1, max_y - header_lines - 1)

        # Keep selected item in viewport
        if selected_idx < scroll_offset:
            scroll_offset = selected_idx
        elif selected_idx >= scroll_offset + max_visible:
            scroll_offset = selected_idx - max_visible + 1

        for i in range(scroll_offset, min(len(recents), scroll_offset + max_visible)):
            path = recents[i]
            row = header_lines + (i - scroll_offset)
            is_active = (i == selected_idx)
            prefix = " > " if is_active else "   "
            item_text = f"{prefix}{display_path(path)}"
            attr = curses.A_REVERSE | curses.A_BOLD if is_active else curses.A_NORMAL
            safe_addstr(stdscr, row, 0, item_text, attr)

        stdscr.refresh()
        key = stdscr.getch()

        # Quit
        if key in (ord("q"), ord("Q"), 27):
            return None

        # Back
        elif key in (curses.KEY_BACKSPACE, 127, 8, curses.KEY_LEFT, ord("h")):
            return None

        # Move Up
        elif key in (curses.KEY_UP, ord("k")):
            if selected_idx > 0:
                selected_idx -= 1

        # Move Down
        elif key in (curses.KEY_DOWN, ord("j")):
            if selected_idx < len(recents) - 1:
                selected_idx += 1

        # Home / End
        elif key == curses.KEY_HOME:
            selected_idx = 0
        elif key == curses.KEY_END:
            selected_idx = len(recents) - 1

        # Page Up / Page Down
        elif key == curses.KEY_PPAGE:
            selected_idx = max(0, selected_idx - max_visible)
        elif key == curses.KEY_NPAGE:
            selected_idx = min(len(recents) - 1, selected_idx + max_visible)

        # Select folder
        elif key in (10, 13, curses.KEY_ENTER, ord(" ")):
            if recents:
                return recents[selected_idx]


def picker(stdscr, start_dir):
    """Main folder picker with arrow navigation."""
    curses.curs_set(0)

    current_dir = os.path.abspath(start_dir)
    selected_idx = 0
    scroll_offset = 0

    while True:
        directories = get_directories(current_dir)
        max_y, max_x = stdscr.getmaxyx()
        stdscr.clear()

        # Header
        safe_addstr(stdscr, 0, 0, "Choose Folder", curses.A_BOLD)
        safe_addstr(stdscr, 1, 0, display_path(current_dir))
        safe_addstr(
            stdscr,
            2,
            0,
            "↑/↓: Navigate   Enter / →: Open   Space: Select   ←/Backspace: Back   r: Recents   q: Quit",
        )

        header_lines = 4
        max_visible = max(1, max_y - header_lines - 1)

        if not directories:
            safe_addstr(
                stdscr,
                header_lines,
                0,
                "  (No subdirectories - press Space or Enter to select this folder)",
            )
        else:
            selected_idx = max(0, min(selected_idx, len(directories) - 1))

            # Keep selected item in viewport
            if selected_idx < scroll_offset:
                scroll_offset = selected_idx
            elif selected_idx >= scroll_offset + max_visible:
                scroll_offset = selected_idx - max_visible + 1

            for i in range(scroll_offset, min(len(directories), scroll_offset + max_visible)):
                dirname = directories[i]
                row = header_lines + (i - scroll_offset)
                is_active = (i == selected_idx)
                prefix = " > " if is_active else "   "
                item_text = f"{prefix}{dirname}"
                attr = curses.A_REVERSE | curses.A_BOLD if is_active else curses.A_NORMAL
                safe_addstr(stdscr, row, 0, item_text, attr)

        stdscr.refresh()
        key = stdscr.getch()

        # Quit
        if key in (ord("q"), ord("Q"), 27):
            return None

        # Recents
        elif key in (ord("r"), ord("R")):
            selected = recent_picker(stdscr)
            if selected and os.path.isdir(selected):
                return selected

        # Space = select current directory (or Enter when directory is empty)
        elif key == ord(" ") or (not directories and key in (10, 13, curses.KEY_ENTER)):
            return current_dir

        # Back / Parent directory
        elif key in (curses.KEY_BACKSPACE, 127, 8, curses.KEY_LEFT, ord("h")):
            parent = os.path.dirname(current_dir)
            if parent != current_dir:
                prev_name = os.path.basename(current_dir)
                current_dir = parent
                parent_dirs = get_directories(current_dir)
                if prev_name in parent_dirs:
                    selected_idx = parent_dirs.index(prev_name)
                else:
                    selected_idx = 0
                scroll_offset = 0

        # Move Up
        elif key in (curses.KEY_UP, ord("k")):
            if directories and selected_idx > 0:
                selected_idx -= 1

        # Move Down
        elif key in (curses.KEY_DOWN, ord("j")):
            if directories and selected_idx < len(directories) - 1:
                selected_idx += 1

        # Home / End
        elif key == curses.KEY_HOME:
            selected_idx = 0
        elif key == curses.KEY_END:
            if directories:
                selected_idx = len(directories) - 1

        # Page Up / Page Down
        elif key == curses.KEY_PPAGE:
            if directories:
                selected_idx = max(0, selected_idx - max_visible)
        elif key == curses.KEY_NPAGE:
            if directories:
                selected_idx = min(len(directories) - 1, selected_idx + max_visible)

        # Enter / Right Arrow: Open highlighted directory
        elif key in (10, 13, curses.KEY_ENTER, curses.KEY_RIGHT, ord("l")):
            if directories:
                new_dir = os.path.join(current_dir, directories[selected_idx])
                if os.path.isdir(new_dir):
                    current_dir = new_dir
                    selected_idx = 0
                    scroll_offset = 0


def main():
    start_dir = os.getcwd()

    # Save Bash's stdout.
    original_stdout = os.dup(sys.stdout.fileno())

    # Send curses UI directly to the terminal.
    tty = os.open("/dev/tty", os.O_WRONLY)
    os.dup2(tty, sys.stdout.fileno())
    os.close(tty)

    try:
        selected = curses.wrapper(picker, start_dir)
    finally:
        # Restore Bash's stdout.
        os.dup2(original_stdout, sys.stdout.fileno())
        os.close(original_stdout)

    # Save selected directory to Recents.
    if selected:
        save_recent(selected)

        # Send ONLY the selected path back to Bash.
        print(selected)


if __name__ == "__main__":
    main()
