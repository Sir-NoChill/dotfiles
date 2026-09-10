#!/usr/bin/env python3
"""Single-line active-window pill for Waybar (Hyprland).

Prints "<app>  <title>" (amber app name, parchment title) and falls back to
a dim "Desktop" when nothing is focused. Streams updates off the Hyprland
event socket, so it repaints the instant focus changes.
"""
import os
import re
import sys
import html
import json
import socket
import subprocess

MAX_TITLE_LEN = 40

# Ember palette
ACCENT = "#c9752b"   # amber   — app / class
TEXT   = "#e7d3b1"   # parchment — title
MUTED  = "#6b4a2f"   # smoke   — idle / desktop


def hypr(command):
    try:
        return json.loads(subprocess.check_output(["hyprctl", command, "-j"], text=True))
    except Exception:
        return {}


def print_status():
    window = hypr("activewindow")

    if window and window.get("address"):
        app = (window.get("class") or "Unknown").strip() or "Unknown"
        title = (window.get("title") or "").strip()

        low = app.lower()
        if "discord" in low or "vesktop" in low:
            title = re.sub(r"^\(\d+\)\s*", "", title)       # drop "(209) " unread counter
            title = re.sub(r"^Discord\s*\|\s*", "", title)

        if len(title) > MAX_TITLE_LEN:
            title = title[:MAX_TITLE_LEN - 1].rstrip() + "…"

        app_e, title_e = html.escape(app), html.escape(title)
        if title_e:
            text = (f"<span foreground='{ACCENT}'>{app_e}</span>"
                    f"  <span foreground='{TEXT}'>{title_e}</span>")
        else:
            text = f"<span foreground='{ACCENT}'>{app_e}</span>"
        tooltip = f"{app}: {title}" if title else app
    else:
        text = f"<span foreground='{MUTED}'>Desktop</span>"
        tooltip = "Desktop"

    print(json.dumps({"text": text, "class": "custom-windowpill", "tooltip": tooltip}), flush=True)


def main():
    print_status()

    sig = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        return  # not on Hyprland — show the initial state and stop

    # Hyprland >= 0.40 moved the socket under XDG_RUNTIME_DIR; keep /tmp as a fallback.
    xdg = os.getenv("XDG_RUNTIME_DIR", "")
    candidates = [
        os.path.join(xdg, "hypr", sig, ".socket2.sock") if xdg else "",
        f"/tmp/hypr/{sig}/.socket2.sock",
    ]
    socket_path = next((p for p in candidates if p and os.path.exists(p)), None)
    if not socket_path:
        return

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(socket_path)
        buf = ""
        while True:
            chunk = client.recv(4096).decode("utf-8", errors="ignore")
            if not chunk:
                break
            buf += chunk
            if any(ev in buf for ev in ("activewindow>>", "workspace>>", "closewindow>>", "openwindow>>")):
                print_status()
                buf = ""


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
