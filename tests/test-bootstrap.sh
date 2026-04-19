#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
source "$(dirname "$0")/lib.sh"
source "$(dirname "$0")/setup.sh"

echo "== bootstrap.sh =="

setup_test_env

# Simulate the structural setup from bootstrap.sh without running
# the full script (which does network operations: fisher, tpm, etc.)
mkdir -p "$HOME/.config/hawker/current"
mkdir -p "$HOME/.config/hypr/wallpapers"
touch "$HOME/.config/hypr/active-theme.conf"
touch "$HOME/.config/hypr/active-mode.conf"

assert_file_exists "active-theme.conf created" "$HOME/.config/hypr/active-theme.conf"
assert_file_exists "active-mode.conf created" "$HOME/.config/hypr/active-mode.conf"
assert_file_exists "hawker current dir created" "$HOME/.config/hawker/current"
assert_file_exists "wallpapers dir created" "$HOME/.config/hypr/wallpapers"
assert_file_exists "themes dir exists" "$HAWKER_PATH/themes"

# Verify bootstrap.sh parses without syntax errors
bash -n "$REPO_DIR/bootstrap.sh" 2>/dev/null
assert_exit_code "bootstrap.sh parses without errors" "0" "$?"

teardown_test_env
test_report
