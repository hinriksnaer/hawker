#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
source "$(dirname "$0")/lib.sh"
source "$(dirname "$0")/setup.sh"

echo "== hawker-theme-next/prev =="

setup_test_env

get_theme() {
  if [[ -L "$HOME/.config/hawker/current/theme" ]]; then
    basename "$(readlink "$HOME/.config/hawker/current/theme")"
  else
    grep '^# theme:' "$HOME/.config/hypr/active-theme.conf" 2>/dev/null | sed 's/^# theme: *//'
  fi
}

# ── Next: alpha -> beta ──
echo "# theme: alpha" > "$HOME/.config/hypr/active-theme.conf"
rm -f "$HOME/.config/hawker/current/theme"
fish "$REPO_DIR/scripts/hawker-theme-next.fish" 2>/dev/null || true
assert_eq "next after alpha is beta" "beta" "$(get_theme)"

# ── Next wraparound: gamma -> alpha ──
echo "# theme: gamma" > "$HOME/.config/hypr/active-theme.conf"
rm -f "$HOME/.config/hawker/current/theme"
fish "$REPO_DIR/scripts/hawker-theme-next.fish" 2>/dev/null || true
assert_eq "next after gamma wraps to alpha" "alpha" "$(get_theme)"

# ── Prev: beta -> alpha ──
echo "# theme: beta" > "$HOME/.config/hypr/active-theme.conf"
rm -f "$HOME/.config/hawker/current/theme"
fish "$REPO_DIR/scripts/hawker-theme-prev.fish" 2>/dev/null || true
assert_eq "prev before beta is alpha" "alpha" "$(get_theme)"

# ── Refresh detection ──
cat > "$HOME/.config/hypr/active-theme.conf" <<'EOF'
# Active Hyprland Theme (runtime-generated)
# Managed by hawker-theme-set-desktop
# theme: alpha
EOF

output=$(fish "$REPO_DIR/scripts/hawker-theme-refresh.fish" 2>&1 || true)
assert_contains "refresh detects alpha" "alpha" "$output"

teardown_test_env
test_report
