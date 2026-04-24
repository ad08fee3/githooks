#!/bin/sh
# Base Git hook template from https://github.com/rycus86/githooks
#
# It allows you to have a .githooks folder per-project that contains
# its hooks to execute on various Git triggers.

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

# Read the runner script from the local/global or system config
GITHOOKS_RUNNER=$(expand_home_refs "$(git config --get githooks.runner)")

if [ ! -x "$GITHOOKS_RUNNER" ]; then
    echo "! Githooks runner points to a non existing location" >&2
    echo "   \`$GITHOOKS_RUNNER\`" >&2
    echo " or it is not executable!" >&2
    echo " Please run the Githooks install script again to fix it." >&2
    exit 1
fi

exec "$GITHOOKS_RUNNER" "$0" "$@"
