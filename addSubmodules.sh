#!/usr/bin/env bash
# Clone Emacs custom-package submodules from .gitmodules URLs.
# Efficiency: Loops over fixed list to avoid parsing overhead.
# Clarity: Handles one clone/add per iteration.
# Readability: Decomposed into functions under 40 lines.

set -euo pipefail  # Exit on errors, unset vars, pipe fails.

# Docstring: Clone a repo into path if not exists, then add gitlink.
# Args:
#   url (str): SSH URL.
#   path (str): Local path.
# Returns: None. Exits on failure.
# Flow: Check existence; clone if needed; add to parent index.
add_submodule() {
    # Add a Git repository as a submodule to the parent repo.
    # Purpose: Efficiently add submodules in bulk scripts, skipping existing paths.
    # Args:
    #   url (str): SSH URL of the repository to add.
    #   path (str): Local path where the submodule will be placed.
    # Returns: 0 on success; exits on failure with error message.
    # Flow: Check if path exists; if not, use 'git submodule add' to clone and register;
    #       handle errors explicitly for resilience.
    local url="$1"
    local path="$2"
    if [ -d "$path" ]; then
        echo "Path $path exists; skipping add."  # Avoid overwrite or re-add conflicts.
        return 0
    fi
    git submodule add "$url" "$path" || { echo "Add failed for $path"; exit 1; }  # Atomic: clones, adds gitlink, updates .gitmodules.
    echo "Added $path as submodule."
}

# Main list: URLs and paths from your .gitmodules.
declare -A submodules
submodules["custom-packages/log-ts-mode"]="git@github.com:simonsjw/log-ts-mode.git"                   #
submodules["custom-packages/logging-view-mode"]="git@github.com:simonsjw/logging-view-mode.git"       #
submodules["custom-packages/memory-object-tree"]="git@github.com:simonsjw/memory-object-tree.git"     #
submodules["custom-packages/project-overview"]="git@github.com:simonsjw/project-overview.git"         #
submodules["custom-packages/q-loadbalancer"]="git@github.com:simonsjw/q-loadbalancer.git"             #
submodules["custom-packages/vega-view"]="git@github.com:simonsjw/vega-view.git"
submodules["custom-packages/window-tree"]="git@github.com:simonsjw/window-tree.git"                   #
submodules["custom-packages/combobulate"]="git@github.com:mickeynp/combobulate.git"                   #
submodules["custom-packages/org-pretty-table"]="git@github.com:Fuco1/org-pretty-table.git"
submodules["custom-packages/systemd-mode"]="git@github.com:holomorph/systemd-mode.git"
submodules["custom-packages/worg"]="git@git.sr.ht:~bzg/worg"                                          #

# Clone and add all.
for path in "${!submodules[@]}"; do
    add_submodule "${submodules[$path]}" "$path"
done

echo "All clones complete."
