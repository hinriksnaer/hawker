# Hawker environment setup
# Sets HAWKER_PATH for theme-manager and scripts to find themes and resources

if test -z "$HAWKER_PATH"
    set -gx HAWKER_PATH "$HOME/.local/share/hawker"
end
