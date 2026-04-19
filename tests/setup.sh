#!/usr/bin/env bash
# Test environment setup.
# Creates an isolated $HOME with mock themes and config directories.
# Source this file after lib.sh.

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

setup_test_env() {
  export TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export HAWKER_PATH="$TEST_HOME/.local/share/hawker"

  # Mock themes
  for theme in alpha beta gamma; do
    mkdir -p "$HAWKER_PATH/themes/$theme/backgrounds"
    echo "# $theme hyprland" > "$HAWKER_PATH/themes/$theme/hyprland.conf"
    echo "# $theme btop" > "$HAWKER_PATH/themes/$theme/btop.theme"
    touch "$HAWKER_PATH/themes/$theme/backgrounds/wall1.png"
  done
  echo '# alpha waybar' > "$HAWKER_PATH/themes/alpha/waybar.css"
  echo '# beta waybar' > "$HAWKER_PATH/themes/beta/waybar.css"

  # Config directories
  mkdir -p "$HOME/.config/hypr"
  mkdir -p "$HOME/.config/hawker/current"
  mkdir -p "$HOME/.config/btop/themes"
  mkdir -p "$HOME/.config/waybar"
  touch "$HOME/.config/hypr/active-theme.conf"

  # Stub out commands that must never run during tests.
  # These create persistent processes or affect the live desktop.
  local stubs_dir="$TEST_HOME/.stubs"
  mkdir -p "$stubs_dir"
  for cmd in swaybg notify-send hyprctl pkill killall playerctl; do
    printf '#!/bin/sh\nexit 0\n' > "$stubs_dir/$cmd"
    chmod +x "$stubs_dir/$cmd"
  done

  # Stubs go FIRST in PATH so they shadow real binaries
  export PATH="$stubs_dir:$REPO_DIR/dotfiles/scripts/.local/bin:$PATH"
}

teardown_test_env() {
  rm -rf "$TEST_HOME"
}
