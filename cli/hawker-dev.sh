# hawker-dev -- CLI for managing the hawker development environment.
# Must be run inside the nix develop shell.
#
# Build logic lives in dev/projects/<name>/setup.sh -- this CLI
# just orchestrates them in the correct order.

REPOS="$HOME/workspace/repos"
VENV="$REPOS/.venv"

# ── Guard: refuse to run outside the dev shell ──
if [[ -z "${HAWKER_ENABLED_PROJECTS:-}" && -z "${CUDA_HOME:-}" ]]; then
  echo "error: hawker-dev must be run inside the nix develop shell." >&2
  echo "  run: nix develop ~/hawker" >&2
  exit 1
fi

# ── Helpers ──
info()  { echo ":: $*"; }
warn()  { echo "!! $*" >&2; }
error() { echo "error: $*" >&2; exit 1; }

get_repo()   { local v="${1^^}_REPO";   echo "${!v:-}"; }
get_branch() { local v="${1^^}_BRANCH"; echo "${!v:-}"; }

enabled_projects() {
  echo "${HAWKER_ENABLED_PROJECTS:-}" | tr ' ' '\n' | grep -v '^$'
}

resolve_projects() {
  # If specific projects given, validate and return in build order.
  # Otherwise return all enabled (already in build order from Nix).
  if [[ $# -gt 0 ]]; then
    local ordered=""
    for p in $(enabled_projects); do
      for req in "$@"; do
        if [[ "$p" == "$req" ]]; then
          ordered+="$p"$'\n'
        fi
      done
    done
    # Validate all requested projects were found
    for req in "$@"; do
      if ! echo "$ordered" | grep -qx "$req"; then
        error "project '$req' is not enabled. Enabled: ${HAWKER_ENABLED_PROJECTS:-none}"
      fi
    done
    echo "$ordered" | grep -v '^$'
  else
    enabled_projects
  fi
}

# ── Commands ──

cmd_build() {
  local projects
  projects=$(resolve_projects "$@")

  for project in $projects; do
    local setup="$HAWKER_ROOT/dev/projects/${project}/setup.sh"

    if [[ ! -f "$setup" ]]; then
      error "$project: no setup script found at $setup"
    fi

    info "$project: running setup"
    bash "$setup"
  done
}

cmd_update() {
  local projects
  projects=$(resolve_projects "$@")

  for project in $projects; do
    local dir="$REPOS/$project"
    local branch
    branch=$(get_branch "$project")

    if [[ ! -d "$dir" ]]; then
      warn "$project: not cloned, skipping (run 'hawker-dev build' first)"
      continue
    fi

    info "$project: pulling latest ($branch)"
    git -C "$dir" fetch origin
    git -C "$dir" checkout "$branch"
    git -C "$dir" pull --ff-only
    git -C "$dir" submodule update --init --recursive
  done
}

cmd_status() {
  local all_projects="pytorch helion vllm"

  printf "%-12s %-8s %-8s %-10s %s\n" "PROJECT" "ENABLED" "BUILT" "BRANCH" "REPO"
  printf "%-12s %-8s %-8s %-10s %s\n" "-------" "-------" "-----" "------" "----"

  for project in $all_projects; do
    local enabled="no" built="no" branch repo dir marker
    repo=$(get_repo "$project")
    branch=$(get_branch "$project")
    dir="$REPOS/$project"
    marker="$REPOS/.${project}-setup-done"

    if enabled_projects | grep -qx "$project" 2>/dev/null; then
      enabled="yes"
    fi
    if [[ -f "$marker" ]]; then
      built="yes"
      branch=$(git -C "$dir" branch --show-current 2>/dev/null || echo "$branch")
    elif [[ -d "$dir/.git" ]]; then
      built="cloned"
      branch=$(git -C "$dir" branch --show-current 2>/dev/null || echo "$branch")
    fi

    printf "%-12s %-8s %-8s %-10s %s\n" "$project" "$enabled" "$built" "${branch:-—}" "${repo:-—}"
  done

  echo ""
  if [[ -d "$VENV" ]]; then
    info "venv: $VENV"
  else
    info "venv: not created (run 'hawker-dev build')"
  fi
}

cmd_clean() {
  local projects
  projects=$(resolve_projects "$@")

  for project in $projects; do
    local dir="$REPOS/$project"
    local marker="$REPOS/.${project}-setup-done"

    if [[ -d "$dir" ]]; then
      info "$project: removing $dir"
      rm -rf "$dir"
    fi
    if [[ -f "$marker" ]]; then
      rm -f "$marker"
    fi

    if [[ ! -d "$dir" && ! -f "$marker" ]]; then
      info "$project: nothing to clean"
    fi
  done

  # Clean venv only if no specific projects given (full clean)
  if [[ $# -eq 0 && -d "$VENV" ]]; then
    info "removing shared venv at $VENV"
    rm -rf "$VENV"
  fi
}

usage() {
  cat <<EOF
Usage: hawker-dev <command> [projects...]

Commands:
  build   Clone, build, and install projects from source (idempotent)
  status  Show state of all projects (enabled, built, branch)
  update  Pull latest changes for project repos
  clean   Remove project repos and build markers (and venv if no projects specified)

Projects are built in dependency order (pytorch first, then downstream).
If no projects are specified, all enabled projects are built/updated/cleaned.
Enabled projects: ${HAWKER_ENABLED_PROJECTS:-none}

Examples:
  hawker-dev build                 # build all enabled projects from source
  hawker-dev build pytorch         # build only pytorch
  hawker-dev status                # show project state
  hawker-dev update helion         # pull latest for helion
  hawker-dev clean                 # remove everything (repos + markers + venv)
  hawker-dev clean pytorch         # remove only pytorch repo + marker
EOF
}

# ── Main ──
case "${1:-}" in
  build)  shift; cmd_build "$@" ;;
  status) shift; cmd_status "$@" ;;
  update) shift; cmd_update "$@" ;;
  clean)  shift; cmd_clean "$@" ;;
  help|--help|-h) usage ;;
  "") usage ;;
  *) error "unknown command: $1 (try 'hawker-dev help')" ;;
esac
