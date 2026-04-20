# Set up project workspaces.
# Nix provides the build environment (CUDA, compilers, env vars).
# This script clones repos and builds from source.
# Idempotent -- skips projects that are already set up.

REPOS="$HOME/repos"

# Ordered list of projects that depend on each other.
# pytorch must build before helion (helion imports torch).
ORDERED="pytorch helion"

# Get enabled projects from environment (set by NixOS sessionVariables)
PROJECTS="${HAWKER_PROJECTS:-}"

if [ -z "$PROJECTS" ]; then
    echo "No projects configured. Set hawker.container.projects in settings.nix."
    exit 0
fi

# Run ordered projects first
for p in $ORDERED; do
    echo "$PROJECTS" | tr ',' ' ' | grep -qw "$p" || continue
    script="$HOME/hawker/projects/${p}/setup.sh"
    if [ -f "$script" ]; then
        bash "$script"
    fi
done

# Run any remaining projects not in the ordered list
for p in $(echo "$PROJECTS" | tr ',' ' '); do
    echo "$ORDERED" | grep -qw "$p" && continue
    script="$HOME/hawker/projects/${p}/setup.sh"
    if [ -f "$script" ]; then
        bash "$script"
    fi
done
