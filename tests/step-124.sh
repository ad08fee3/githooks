#!/bin/sh
# Test:
#   Cli tool: test listing hooks from local shared repos


#####################################################
# Expands user home directory references in a path string.
#
# Expands:
#   - Leading "~" into the user's $HOME directory
#   - All literal "$HOME" strings into the resolved $HOME
#
# Does NOT:
#   - Resolve "." or ".."
#   - Resolve symbolic links
#   - Verify path existence
#   - Perform any filesystem normalization
#
# Invocation example:
# INSTALL_DIR=$(expand_home_refs "$(git config --global --get githooks.installDir)")
#
# Parameters:
#   $1 - Raw input path string to expand
#
# Output:
#   Prints the expanded path to stdout
#
# Returns:
#   0 always (string transformation only)
#####################################################
expand_home_refs() {
    local p="$1"

    # empty input → return empty
    [ -z "$p" ] && return 0

    # expand any leading ~
    case "$p" in
        "~")   p="$HOME" ;;
        "~"/*) p="$HOME${p#?}" ;;
    esac

    # expand literal "$HOME"
    p=$(printf '%s' "$p" | sed "s|\$HOME|$HOME|g")

    printf '%s\n' "$p"
}

if ! sh /var/lib/githooks/install.sh; then
    echo "! Failed to execute the install script"
    exit 1
fi

mkdir -p /tmp/test117/shared/.githooks/pre-commit &&
    cd /tmp/test117/shared/.githooks/pre-commit &&
    touch example-01 ||
    exit 2

# generate the shared folder name (from the cli.sh)
REPO_LOCATION="ssh://git@github.com/test/repo1.git"
INSTALL_DIR=$(expand_home_refs "$(git config --global --get githooks.installDir)")
[ -n "$INSTALL_DIR" ] || INSTALL_DIR="~/.githooks"
SHA_HASH=$(echo "$REPO_LOCATION" | git hash-object --stdin 2>/dev/null)
NAME=$(echo "$REPO_LOCATION" | tail -c 48 | sed -E "s/[^a-zA-Z0-9]/-/g")
SHARED_ROOT="$INSTALL_DIR/shared/$SHA_HASH-$NAME"

mkdir -p "$SHARED_ROOT/pre-push" &&
    cd "$SHARED_ROOT" &&
    touch pre-push/example-03 &&
    git init &&
    git remote add origin "$REPO_LOCATION" &&
    git hooks shared add --global "$REPO_LOCATION" ||
    exit 3

mkdir -p /tmp/test117/repo/.githooks/commit-msg &&
    cd /tmp/test117/repo &&
    git init &&
    touch .githooks/commit-msg/example-02 &&
    git hooks shared add --global /tmp/test117/shared ||
    exit 4

cd /tmp/test117/repo || exit 5

OUTPUT=$(git hooks list 2>&1)

if ! echo "$OUTPUT" | grep 'example-01'; then
    echo "$OUTPUT" >&2
    echo "! Missing shared hook in the output" >&2
    exit 11
fi

if ! echo "$OUTPUT" | grep 'example-02'; then
    echo "$OUTPUT" >&2
    echo "! Missing local hook in the output" >&2
    exit 12
fi

if ! echo "$OUTPUT" | grep 'example-03'; then
    echo "$OUTPUT" >&2
    echo "! Missing shared hook in the output" >&2
    exit 13
fi
