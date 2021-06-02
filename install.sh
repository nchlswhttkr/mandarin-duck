#!/usr/bin/env bash
set -euo pipefail

VERSION=1.1

# Verify jq and curl are installed
if ! command -v curl > /dev/null; then
    echo -e "\033[31mYou must have curl installed\033[0m"
    exit 1
fi
if ! command -v jq > /dev/null; then
    echo -e "\033[31mYou must have jq installed\033[0m"
    exit 1
fi

# Create install directory and config
: "${DESTINATION:="$HOME/.mandarin-duck"}"
if [[ ! -d "$DESTINATION" ]]; then
    echo "Creating config at $DESTINATION/mandarin-duck.cfg"
    mkdir -p "$DESTINATION"
    jq --null-input "
        .version = \"$VERSION\" |
        .buildkite_api_token = \"\" |
        .buildkite_organization_slug = \"\" |
        .projects = {}
    " > "$DESTINATION/mandarin-duck.cfg"
fi
chmod 600 "$DESTINATION/mandarin-duck.cfg"

# All post-receive hooks call a shared script in the install directory
echo "Updating trigger script"
cp post-receive.sh "$DESTINATION/"
chmod +x "$DESTINATION/post-receive.sh"


# Upgrade existing setup if coming from v1.0
OLD_V1_HOOK_SCRIPT="#!/bin/sh
$DESTINATION/post-receive.sh # mandarin-duck v1.0"
FOUND_VERSION=$(jq --raw-output ".version" "$DESTINATION/mandarin-duck.cfg")
if [[ "$FOUND_VERSION" == "1.0" ]]; then
    echo "Found v1.0 config, creating a backup before upgrading"
    cp "$DESTINATION/mandarin-duck.cfg" "$DESTINATION/mandarin-duck.cfg.backup"
    echo "Updating v1.0 projects"
    jq --raw-output ".projects | keys | .[]" "$DESTINATION/mandarin-duck.cfg" | while read -r EXISTING_REPO; do

        # If the project has been touched manually, skip to avoid trouble
        if ! diff - "$EXISTING_REPO/hooks/post-receive" > /dev/null <<<"$OLD_V1_HOOK_SCRIPT"; then
            echo -e "\033[33mSkipping custom post-receive hook in $EXISTING_REPO\033[0m"
            continue
        fi

        # Replace the existing hook
        rm "$EXISTING_REPO/hooks/post-receive"
        ln -s "$DESTINATION/post-receive.sh" "$EXISTING_REPO/hooks/post-receive"
        chmod +x "$EXISTING_REPO/hooks/post-receive" # TODO: Is this needed?
    done

    # Upgrade the config version from v1.0
    TEMP=$(mktemp)
    chmod 600 "$TEMP"
    jq ".version = \"$VERSION\"" "$DESTINATION/mandarin-duck.cfg" > "$TEMP"
    mv "$TEMP" "$DESTINATION/mandarin-duck.cfg"
fi

# If a repo is provided, add a hook for it
if (( $# == 1 )); then

    # Validate the provided repo path
    REPO="${1%/}" # strip trailing slash that autocomplete can add
    if [[ $REPO != /* ]]; then
        echo -e "\033[31mGit repository must be an absolute path\033[0m"
        exit 1
    fi
    if [[ ! -d $REPO ]]; then
        echo -e "\033[31mSpecified path does not exist (or isn't a directory)\033[0m"
        exit 1
    fi
    if [[ $(GIT_DIR="$REPO" git rev-parse --is-bare-repository 2>/dev/null) != "true" ]]; then
        echo -e "\033[31mSpecified path is not a bare Git repository\033[0m"
        exit 1
    fi

    # Create trigger for the given repo and it to config
    echo "Creating trigger for $REPO"
    if [[ ! -a "$REPO/hooks/post-receive" ]]; then
        ln -s "$DESTINATION/post-receive.sh" "$REPO/hooks/post-receive"
        chmod +x "$REPO/hooks/post-receive" # TODO: Is this needed?
    fi # TODO: Warn if hook already exists
    TEMP=$(mktemp)
    chmod 600 "$TEMP"
    jq ".projects[\"$REPO\"].buildkite_pipeline_slug = (.projects[\"$REPO\"].buildkite_pipeline_slug // \"\")" "$DESTINATION/mandarin-duck.cfg" > "$TEMP"
    mv "$TEMP" "$DESTINATION/mandarin-duck.cfg"
fi

echo -e "\033[32mSuccessfully installed mandarin-duck v$VERSION!\033[0m"

# TODO: ASCII art of a duck? Would be kinda cute :)
