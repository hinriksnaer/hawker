#!/usr/bin/env bash
# hawker-setup -- set up project workspaces
#
# Runs project setup scripts in build order for all enabled projects.
# Creates the shared workspace structure and virtualenv.
#
# Usage:
#   hawker-setup                  # set up all enabled projects
#   hawker-setup helion           # set up just helion
set -euo pipefail

HAWKER_ROOT="${HAWKER_ROOT:-$HOME/workspace/hawker}"

if [ ! -d "$HAWKER_ROOT/.git" ]; then
    if [ -d "$HOME/hawker/.git" ]; then
        HAWKER_ROOT="$HOME/hawker"
    else
        echo "Error: hawker repo not found" >&2
        exit 1
    fi
fi

REPOS="${HAWKER_REPOS:-$HOME/workspace/repos}"

export HAWKER_ROOT REPOS

# Create repos directory
mkdir -p "$REPOS"

# Project build order
PROJECT_ORDER=(pytorch helion vllm)

# If a specific project is requested, only set up that one
if [ $# -ge 1 ]; then
    PROJECT_ORDER=("$@")
fi

for project in "${PROJECT_ORDER[@]}"; do
    setup_script="$HAWKER_ROOT/projects/$project/setup.sh"
    if [ ! -f "$setup_script" ]; then
        echo "Warning: no setup script for '$project', skipping"
        continue
    fi

    echo "==> Setting up $project..."
    bash "$setup_script"
done

echo "==> All projects set up"
