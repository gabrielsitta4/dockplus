#!/bin/sh
set -e
hyprctl plugin list | grep -q "^Plugin dockplus-minimize " && exit 0
out="${XDG_CACHE_HOME:-$HOME/.cache}/dockplus"
mkdir -p "$out"
make -s -C "$(dirname "$0")" OUT="$out/dockplus-minimize.so"
hyprctl plugin load "$out/dockplus-minimize.so"
