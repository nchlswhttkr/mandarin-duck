#!/usr/bin/env bash
set -euo pipefail

# TODO: Verify jq and curl are installed

if (( $# != 1 )); then
    echo -e "\033[31mExpected repo path, like \"./install.sh /path/to/repo.git\"\033[0m"
    exit 1
fi
REPO="${1%/}" # strip trailing slash that autocomplete can add
if [[ $REPO != /* ]]; then
    echo -e "\033[31mGit repository must be an absolute path\033[0m"
    exit 1
fi
# TODO: Verify path exists and is a Git repo


echo "--- Creating config file"
CONFIG=~/.mandarin-duck/mandarin-duck.cfg
# TODO: Allow values to populate from environment variables
# TODO: Use Buildkite API token to get organization/pipeline name
# TODO: Add option to create a new pipeline for this repo
if [[ -d "$HOME/.mandarin-duck" ]]; then
    echo "Updating existing config $CONFIG"
    mv $CONFIG $CONFIG.backup
    jq "
        .projects[\"$REPO\"].buildkite_pipeline_slug = .projects[\"$REPO\"].buildkite_pipeline_slug? // \"\"
    " < $CONFIG.backup > $CONFIG
else
    echo "Creating config at $CONFIG"
    mkdir ~/.mandarin-duck
    jq --null-input "
        .version = \"1.0\" |
        .buildkite_api_token = \"\" |
        .buildkite_organization_slug = \"\" |
        .projects[\"$REPO\"].buildkite_pipeline_slug = \"\"
    " > $CONFIG
fi
chmod 600 $CONFIG
echo "Make sure to update your config file with your API token and organization/pipeline name!"


echo "--- Creating post-receive hook"
if [[ -a "$REPO/hooks/post-receive" ]]; then
    mv "$REPO/hooks/post-receive" "$REPO/hooks/post-receive.backup"
    echo -e "\033[33mMoved existing post-receive hook to $REPO/hooks/post-receive.backup\033[0m"
fi
cp ./post-receive.sh "$REPO/hooks/post-receive"
chmod +x "$REPO/hooks/post-receive"
