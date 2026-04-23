# hawker-build - build project sources inside the container
#
# Reads HAWKER_PROJECTS (set by Nix, sorted by buildOrder) to discover
# enabled projects. Delegates to each project's setup.sh for the actual
# clone + build logic.
#
# Usage:
#   hawker-build                        build all enabled projects
#   hawker-build helion                 build only helion
#   hawker-build pytorch helion         build specific projects (auto-sorted)
#   hawker-build --force                rebuild all (keep source, re-run install)
#   hawker-build --clean pytorch        nuke workspace + rebuild from scratch
#   hawker-build --status               show build state of all projects

REPOS="$HOME/repos"
PROJECTS_DIR="$HOME/hawker/projects"

# ── Helpers ──

usage() {
    echo "hawker-build - build project sources"
    echo ""
    echo "Usage:"
    echo "  hawker-build [project...] [--force] [--clean]"
    echo "  hawker-build --status"
    echo ""
    echo "Options:"
    echo "  --force   Remove build marker and re-run setup (keeps cloned source)"
    echo "  --clean   Remove marker + workspace, then re-clone and rebuild"
    echo "  --status  Show build state of all enabled projects"
    echo ""
    echo "Projects build in the order defined by their buildOrder option."
    echo "If no project is specified, all enabled projects are built."
    if [ -n "${HAWKER_PROJECTS:-}" ]; then
        echo ""
        echo "Enabled projects (build order): $HAWKER_PROJECTS"
    fi
}

die() {
    echo "Error: $1" >&2
    exit 1
}

# Check if a value is in the HAWKER_PROJECTS list
is_valid_project() {
    local name=$1
    local proj
    for proj in "${ALL_PROJECTS[@]}"; do
        if [ "$proj" = "$name" ]; then
            return 0
        fi
    done
    return 1
}

# Re-sort requested projects to match canonical HAWKER_PROJECTS order
sort_by_build_order() {
    local -n _requested=$1
    local -n _sorted=$2
    local proj req
    for proj in "${ALL_PROJECTS[@]}"; do
        for req in "${_requested[@]}"; do
            if [ "$proj" = "$req" ]; then
                _sorted+=("$proj")
                break
            fi
        done
    done
}

show_status() {
    echo "Projects (build order):"
    local proj marker workspace
    for proj in "${ALL_PROJECTS[@]}"; do
        marker="$REPOS/.${proj}-setup-done"
        workspace="$REPOS/$proj"
        if [ -f "$marker" ]; then
            echo "  [built]       $proj    $workspace"
        elif [ -d "$workspace" ]; then
            echo "  [cloned]      $proj    $workspace"
        else
            echo "  [pending]     $proj"
        fi
    done
}

# ── Parse arguments ──

FORCE=0
CLEAN=0
STATUS=0
REQUESTED=()

while [ $# -gt 0 ]; do
    case "$1" in
        --force)  FORCE=1 ;;
        --clean)  CLEAN=1 ;;
        --status) STATUS=1 ;;
        --help|-h) usage; exit 0 ;;
        -*)       die "Unknown option: $1" ;;
        *)        REQUESTED+=("$1") ;;
    esac
    shift
done

# ── Validate environment ──

if [ -z "${HAWKER_PROJECTS:-}" ]; then
    die "HAWKER_PROJECTS not set. Are you inside a hawker container?"
fi

read -ra ALL_PROJECTS <<< "$HAWKER_PROJECTS"

if [ ${#ALL_PROJECTS[@]} -eq 0 ]; then
    die "No projects enabled. Enable projects in settings.nix."
fi

# ── Status ──

if [ $STATUS -eq 1 ]; then
    show_status
    exit 0
fi

# ── Determine which projects to build ──

PROJECTS=()

if [ ${#REQUESTED[@]} -gt 0 ]; then
    # Validate each requested project
    for req in "${REQUESTED[@]}"; do
        if ! is_valid_project "$req"; then
            die "'$req' is not an enabled project. Available: $HAWKER_PROJECTS"
        fi
    done
    # Re-sort to canonical build order
    sort_by_build_order REQUESTED PROJECTS
else
    PROJECTS=("${ALL_PROJECTS[@]}")
fi

# ── Build ──

FAILED=()

for proj in "${PROJECTS[@]}"; do
    setup="$PROJECTS_DIR/$proj/setup.sh"
    marker="$REPOS/.${proj}-setup-done"
    workspace="$REPOS/$proj"

    if [ ! -f "$setup" ]; then
        die "Setup script not found: $setup"
    fi

    if [ $CLEAN -eq 1 ]; then
        echo "==> Cleaning $proj..."
        rm -f "$marker"
        rm -rf "$workspace"
    elif [ $FORCE -eq 1 ]; then
        echo "==> Forcing rebuild of $proj..."
        rm -f "$marker"
    fi

    if [ -f "$marker" ] && [ $FORCE -eq 0 ] && [ $CLEAN -eq 0 ]; then
        echo "==> $proj already built (use --force to rebuild)"
        continue
    fi

    echo "==> Building $proj..."
    if bash "$setup"; then
        echo "==> $proj done"
    else
        echo "==> $proj FAILED" >&2
        FAILED+=("$proj")
    fi
done

# ── Summary ──

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo "Failed projects: ${FAILED[*]}"
    exit 1
fi

echo ""
echo "All projects built successfully."
