#!/bin/sh
# ~/.config/hypr/scripts/can-suspend.sh — defer suspend while an SSH session is connected.
ss -tn state established '( sport = :ssh )' | grep -q . && exit 1
exit 0
