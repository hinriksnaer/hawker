#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
source "$(dirname "$0")/lib.sh"
source "$(dirname "$0")/setup.sh"

echo "== hawker-theme-list =="

setup_test_env

output=$(fish "$REPO_DIR/dotfiles/scripts/.local/bin/hawker-theme-list" 2>/dev/null)

assert_contains "lists alpha" "alpha" "$output"
assert_contains "lists beta" "beta" "$output"
assert_contains "lists gamma" "gamma" "$output"

count=$(echo "$output" | wc -l)
assert_eq "exactly 3 themes" "3" "$count"

teardown_test_env
test_report
