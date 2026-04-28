#!/usr/bin/env bash
# hawker-dev -- CLI for managing the hawker development environment.
# Must be run inside the nix develop shell.
set -euo pipefail

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
  # If specific projects given, validate them. Otherwise use all enabled.
  if [[ $# -gt 0 ]]; then
    for p in "$@"; do
      if ! enabled_projects | grep -qx "$p"; then
        error "project '$p' is not enabled. Enabled: ${HAWKER_ENABLED_PROJECTS:-none}"
      fi
    done
    echo "$@" | tr ' ' '\n'
  else
    enabled_projects
  fi
}

# ── Commands ──

cmd_setup() {
  local projects
  projects=$(resolve_projects "$@")

  # Create shared venv if it doesn't exist
  if [[ ! -d "$VENV" ]]; then
    info "creating shared venv at $VENV"
    python -m venv "$VENV"
  fi
  source "$VENV/bin/activate"

  for project in $projects; do
    local repo dir branch
    repo=$(get_repo "$project")
    branch=$(get_branch "$project")
    dir="$REPOS/$project"

    if [[ -z "$repo" ]]; then
      warn "no repo configured for $project, skipping"
      continue
    fi

    if [[ -d "$dir" ]]; then
      info "$project: already cloned at $dir"
    else
      info "$project: cloning $repo ($branch)"
      git clone --branch "$branch" --recurse-submodules "$repo" "$dir"
    fi
  done

  info "setup complete"
}

cmd_build() {
  local projects
  projects=$(resolve_projects "$@")

  if [[ ! -d "$VENV" ]]; then
    error "venv not found. Run 'hawker-dev setup' first."
  fi
  source "$VENV/bin/activate"

  for project in $projects; do
    local dir="$REPOS/$project"
    if [[ ! -d "$dir" ]]; then
      error "$project: not cloned. Run 'hawker-dev setup $project' first."
    fi

    info "$project: building"
    case "$project" in
      pytorch)
        info "$project: pip install (editable, from source)"
        pip install -e "$dir" 2>&1 | tail -1
        ;;
      helion)
        local torch_index="$HELION_TORCH_INDEX"
        local extras="${HELION_PIP_EXTRAS:-}"
        info "$project: installing torch from --extra-index-url https://download.pytorch.org/whl/$torch_index"
        pip install torch --extra-index-url "https://download.pytorch.org/whl/$torch_index" 2>&1 | tail -1
        info "$project: pip install (editable${extras:+, extras: $extras})"
        pip install -e "${dir}${extras}" 2>&1 | tail -1
        ;;
      vllm)
        local torch_index="$VLLM_TORCH_INDEX"
        info "$project: installing torch from --extra-index-url https://download.pytorch.org/whl/$torch_index"
        pip install torch --extra-index-url "https://download.pytorch.org/whl/$torch_index" 2>&1 | tail -1
        info "$project: pip install (editable)"
        pip install -e "$dir" 2>&1 | tail -1
        ;;
      *)
        warn "$project: no build recipe, attempting generic pip install -e"
        pip install -e "$dir" 2>&1 | tail -1
        ;;
    esac
    info "$project: done"
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
      warn "$project: not cloned, skipping (run 'hawker-dev setup' first)"
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

  printf "%-12s %-8s %-8s %-10s %s\n" "PROJECT" "ENABLED" "CLONED" "BRANCH" "REPO"
  printf "%-12s %-8s %-8s %-10s %s\n" "-------" "-------" "------" "------" "----"

  for project in $all_projects; do
    local enabled="no" cloned="no" branch repo dir
    repo=$(get_repo "$project")
    branch=$(get_branch "$project")
    dir="$REPOS/$project"

    if enabled_projects | grep -qx "$project" 2>/dev/null; then
      enabled="yes"
    fi
    if [[ -d "$dir/.git" ]]; then
      cloned="yes"
      branch=$(git -C "$dir" branch --show-current 2>/dev/null || echo "$branch")
    fi

    printf "%-12s %-8s %-8s %-10s %s\n" "$project" "$enabled" "$cloned" "${branch:-—}" "${repo:-—}"
  done

  echo ""
  if [[ -d "$VENV" ]]; then
    info "venv: $VENV"
  else
    info "venv: not created (run 'hawker-dev setup')"
  fi
}

cmd_clean() {
  local projects
  projects=$(resolve_projects "$@")

  for project in $projects; do
    local dir="$REPOS/$project"
    if [[ -d "$dir" ]]; then
      info "$project: removing $dir"
      rm -rf "$dir"
    else
      info "$project: not cloned, nothing to clean"
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
  setup   Clone repos and create shared venv for enabled projects
  build   Build and install projects into the shared venv
  status  Show state of all projects
  update  Pull latest changes for project repos
  clean   Remove project repos (and venv if no projects specified)

Projects default to all enabled projects if none are specified.
Enabled projects: ${HAWKER_ENABLED_PROJECTS:-none}

Examples:
  hawker-dev setup                 # set up all enabled projects
  hawker-dev build pytorch         # build only pytorch
  hawker-dev update helion vllm    # pull latest for helion and vllm
  hawker-dev clean                 # remove everything (repos + venv)
  hawker-dev clean pytorch         # remove only pytorch repo
EOF
}

# ── Main ──
case "${1:-}" in
  setup)  shift; cmd_setup "$@" ;;
  build)  shift; cmd_build "$@" ;;
  status) shift; cmd_status "$@" ;;
  update) shift; cmd_update "$@" ;;
  clean)  shift; cmd_clean "$@" ;;
  help|--help|-h) usage ;;
  "") usage ;;
  *) error "unknown command: $1 (try 'hawker-dev help')" ;;
esac
