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

# Find hawker root (the directory containing this script's parent)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HAWKER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE="$HAWKER_ROOT/workspace"
REPOS="$WORKSPACE/repos"

export HAWKER_ROOT WORKSPACE REPOS

# Create workspace structure
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

    # Check if project is referenced (setup script handles its own enable/marker logic)
    echo "==> Setting up $project..."
    bash "$setup_script"
done

echo "==> All projects set up"
