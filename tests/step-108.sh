#!/bin/sh
# Test:
#   Custom install prefix test


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

TEST_PREFIX_DIR="/tmp/githooks"
mkdir -p ~/.githooks/release && cp /var/lib/githooks/cli.sh ~/.githooks/release || exit 1

sh /var/lib/githooks/install.sh --prefix "$TEST_PREFIX_DIR" || exit 1

if [ ! -d "$TEST_PREFIX_DIR/.githooks" ]; then
    echo "! Expected the install directory to be in \`$TEST_PREFIX_DIR\`"
    exit 2
fi

if [ "$(expand_home_refs "$(git config --global --get githooks.installDir)")" != "$TEST_PREFIX_DIR/.githooks" ]; then
    echo "! Install directory in config \`$(git config --global --get githooks.installDir)\` is incorrect!"
    exit 3
fi

# Set a wrong install
git config --global githooks.installDir "$TEST_PREFIX_DIR/.githooks-notexisting"

if ! ~/.githooks/release/cli.sh help 2>&1 | grep -q "Githooks installation is corrupt"; then
    echo "! Expected the installation to be corrupt"
    exit 4
fi

mkdir -p /tmp/test108/.githooks/pre-commit &&
    echo 'echo "Hello"' >/tmp/test108/.githooks/pre-commit/testing &&
    cd /tmp/test108 &&
    git init ||
    exit 5

echo A >A.txt
git add A.txt
if ! git commit -a -m "Test" 2>&1 | grep -q "Githooks installation is corrupt"; then
    echo "! Expected the installation to be corrupt"
    exit 6
fi
