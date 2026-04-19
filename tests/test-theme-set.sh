#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
source "$(dirname "$0")/lib.sh"
source "$(dirname "$0")/setup.sh"

echo "== hawker-theme-set-terminal =="

setup_test_env

fish "$REPO_DIR/dotfiles/scripts/.local/bin/hawker-theme-set-terminal" beta 2>/dev/null || true

assert_symlink "creates current theme symlink" "$HOME/.config/hawker/current/theme"

target=$(readlink "$HOME/.config/hawker/current/theme")
assert_contains "symlink points to beta" "beta" "$target"

assert_file_exists "btop theme symlinked" "$HOME/.config/btop/themes/active.theme"

teardown_test_env
test_report
