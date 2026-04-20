# Apply Home Manager configuration from the hawker repo.
# Works on both desktop (via NixOS integration) and inside containers (standalone).

FLAKE_REF="${HAWKER_FLAKE:-$HOME/hawker}"
USERNAME="${HAWKER_USER:-$USER}"

echo "==> Applying Home Manager config..."
nix run "${FLAKE_REF}#homeConfigurations.${USERNAME}.activationPackage" \
    --extra-experimental-features "nix-command flakes"
echo "==> Done."
