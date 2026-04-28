# hawker-switch - rebuild and activate the NixOS configuration for this host
#
# Maps the machine hostname to the matching flake output and runs
# nixos-rebuild switch.  Extra arguments are forwarded to nixos-rebuild.
#
# Usage:
#   hawker-switch                       rebuild & switch this host
#   hawker-switch --show-trace          same, with full error traces

FLAKE="${HOME}/hawker"
HOST=$(hostname)

# Map hostname -> flake configuration name
case "${HOST}" in
    hawker)        CONF="desktop" ;;
    hawker-laptop) CONF="laptop"  ;;
    *)
        echo "Error: unknown host '${HOST}'" >&2
        echo "Add a mapping in hawker-switch.sh" >&2
        exit 1
        ;;
esac

echo "==> Switching ${HOST} (${CONF}) to latest configuration..."
sudo nixos-rebuild switch --flake "${FLAKE}#${CONF}" "$@"
