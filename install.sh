#!/usr/bin/env bash
set -euo pipefail

VERSION=1.0

if ! command -v curl > /dev/null; then
    echo -e "\033[31mYou must have curl installed\033[0m"
    exit 1
fi
if ! command -v jq > /dev/null; then
    echo -e "\033[31mYou must have jq installed\033[0m"
    exit 1
fi

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


echo "--- Setting up install directory"
DESTINATION="$HOME/.mandarin-duck"
if [[ -d "$DESTINATION" ]]; then
    echo "Found existing installation at $DESTINATION"
    mv "$DESTINATION/mandarin-duck.cfg" "$DESTINATION/mandarin-duck.cfg.backup"
    jq "
        .projects[\"$REPO\"].buildkite_pipeline_slug = .projects[\"$REPO\"].buildkite_pipeline_slug? // \"\"
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
echo "Make sure to update your config file with your API token and organization/pipeline name!"
echo "Copying post-receive.sh script"
cp post-receive.sh "$DESTINATION/"
chmod +x "$DESTINATION/post-receive.sh"


echo "--- Creating trigger for $REPO"
if [[ -a "$REPO/hooks/post-receive" ]]; then
    echo -e "\033[33mUpdating existing command\033[0m"
    sed -i "/# mandarin-duck v[.0-9]*/d" "$REPO/hooks/post-receive"
else
    echo "Creating post-receive hook"
    echo "#!/bin/sh" > "$REPO/hooks/post-receive"
    chmod +x "$REPO/hooks/post-receive"
fi
echo "$DESTINATION/post-receive.sh # mandarin-duck v$VERSION" >> "$REPO/hooks/post-receive"

# TODO: ASCII art of a duck? Would be kinda cute :)
