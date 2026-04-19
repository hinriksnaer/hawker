#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
source "$(dirname "$0")/lib.sh"
source "$(dirname "$0")/setup.sh"

echo "== hawker-theme-current =="

setup_test_env

# ── Marker detection ──
cat > "$HOME/.config/hypr/active-theme.conf" <<'EOF'
# Active Hyprland Theme (runtime-generated)
# Managed by hawker-theme-set-desktop
# theme: beta

general {
    col.active_border = rgba(ff0000ee)
}
EOF

output=$(fish "$REPO_DIR/scripts/hawker-theme-current.fish" 2>/dev/null)
assert_eq "detects beta from marker" "Beta" "$output"

# ── Symlink fallback ──
echo "" > "$HOME/.config/hypr/active-theme.conf"
ln -sf "$HAWKER_PATH/themes/gamma" "$HOME/.config/hawker/current/theme"

output=$(fish "$REPO_DIR/scripts/hawker-theme-current.fish" 2>/dev/null)
assert_eq "detects gamma from symlink" "Gamma" "$output"

# ── No theme set ──
echo "" > "$HOME/.config/hypr/active-theme.conf"
rm -f "$HOME/.config/hawker/current/theme"

rc=0
fish "$REPO_DIR/scripts/hawker-theme-current.fish" 2>/dev/null || rc=$?
assert_exit_code "exits non-zero when no theme" "1" "$rc"

teardown_test_env
test_report
