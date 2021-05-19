#!/usr/bin/env bash
set -euo pipefail

# TODO: Revoke Buildkite API token

DESTINATION="$HOME/.mandarin-duck"

REPOS=$(jq --raw-output ".projects | keys | .[]" "$DESTINATION/mandarin-duck.cfg")
DESTROY_COUNT=$(wc -l <<<"$REPOS" | tr -d " ")
echo "You are about to uninstall mandarin-duck"
echo " * $DESTINATION will be deleted"
echo -e " * The post-receive hook will be deleted in \033[33m$DESTROY_COUNT\033[0m repositories"
echo
read -rp "Confirm the number of repositories to proceed > " DESTROY_COUNT_INPUT

if [[ "$DESTROY_COUNT_INPUT" != "$DESTROY_COUNT" ]]; then
    echo "Input did not match the expected amount, aborting..."
    exit 1
fi


echo "Uninstalling mandarin-duck..."
while read -r REPO;do
    sed -i "/# mandarin-duck v[.0-9]*/d" "$REPO/hooks/post-receive"
done <<<"$REPOS"; 
rm -rf "$DESTINATION"
