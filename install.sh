#!/usr/bin/env bash
set -euo pipefail

VERSION=1.0

# Verify jq and curl are installed
if ! command -v curl > /dev/null; then
    echo -e "\033[31mYou must have curl installed\033[0m"
    exit 1
fi
if ! command -v jq > /dev/null; then
    echo -e "\033[31mYou must have jq installed\033[0m"
    exit 1
fi

# Validate repo path to add hook to
if (( $# != 1 )); then
    echo -e "\033[31mExpected repo path, like \"./install.sh /path/to/repo.git\"\033[0m"
    exit 1
fi
REPO="${1%/}" # strip trailing slash that autocomplete can add
if [[ $REPO != /* ]]; then
    echo -e "\033[31mGit repository must be an absolute path\033[0m"
    exit 1
fi
if [[ $(GIT_DIR="$REPO" git rev-parse --is-bare-repository 2>/dev/null) != "true" ]]; then
    echo -e "\033[31mSpecified path is not a bare Git repository\033[0m"
    exit 1
fi

# Create install directory and config
: "${DESTINATION:="$HOME/.mandarin-duck"}"
if [[ -d "$DESTINATION" ]]; then
    echo "Updating existing config at $DESTINATION/mandarin-duck.cfg"
    mv "$DESTINATION/mandarin-duck.cfg" "$DESTINATION/mandarin-duck.cfg.backup"
    jq "
        .projects[\"$REPO\"].buildkite_pipeline_slug = (.projects[\"$REPO\"].buildkite_pipeline_slug // \"\")
    " < "$DESTINATION/mandarin-duck.cfg.backup" > "$DESTINATION/mandarin-duck.cfg"
else
    echo "Creating config at $DESTINATION/mandarin-duck.cfg"
    mkdir -p "$DESTINATION"
    jq --null-input "
        .version = \"$VERSION\" |
        .buildkite_api_token = \"\" |
        .buildkite_organization_slug = \"\" |
        .projects[\"$REPO\"].buildkite_pipeline_slug = \"\"
    " > "$DESTINATION/mandarin-duck.cfg"
fi
chmod 600 "$DESTINATION/mandarin-duck.cfg"

# All post-receive hooks call a shared script in the install directory
echo "Copying trigger handling script"
cp post-receive.sh "$DESTINATION/"
chmod +x "$DESTINATION/post-receive.sh"

# Ensure post-receive hook exists in target repo
if [[ -a "$REPO/hooks/post-receive" ]]; then
    echo "Updating trigger for $REPO"
    sed -i "/# mandarin-duck v[.0-9]*/d" "$REPO/hooks/post-receive"
else
    echo "Creating trigger for $REPO"
    echo "#!/bin/sh" > "$REPO/hooks/post-receive"
    chmod +x "$REPO/hooks/post-receive"
fi
echo "$DESTINATION/post-receive.sh # mandarin-duck v$VERSION" >> "$REPO/hooks/post-receive"

echo -e "\033[32mSuccessfully installed mandarin-duck v$VERSION!\033[0m"

# TODO: ASCII art of a duck? Would be kinda cute :)
