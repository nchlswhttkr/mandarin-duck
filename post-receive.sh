#!/usr/bin/env bash
set -euo pipefail

REPO="$(pwd)"
CONFIG="${DESTINATION=$HOME/.mandarin-duck}/mandarin-duck.cfg"
CONFIG_VERSION=$(jq --raw-output ".version // \"\"" "$CONFIG")
if [[ $CONFIG_VERSION != 1.* ]]; then
    echo -e "\033[31mIncompatible version of mandarin-duck\033[0m"
    exit 1
fi
BUILDKITE_API_TOKEN=$(jq --raw-output ".buildkite_api_token // \"\"" "$CONFIG")
if [[ $BUILDKITE_API_TOKEN == "" ]]; then
    echo -e "\033[31mBuildkite API token not set, check your config at $CONFIG\033[0m"
    exit 1
fi
BUILDKITE_ORGANIZATION_SLUG=$(jq --raw-output ".buildkite_organization_slug // \"\"" "$CONFIG")
if [[ $BUILDKITE_ORGANIZATION_SLUG == "" ]]; then
    echo -e "\033[31mBuildkite organization name not set, check your config at $CONFIG\033[0m"
    exit 1
fi
BUILDKITE_PIPELINE_SLUG=$(jq --raw-output ".projects[\"$REPO\"].buildkite_pipeline_slug // \"\"" "$CONFIG")
if [[ $BUILDKITE_PIPELINE_SLUG == "" ]]; then
    echo -e "\033[31mBuildkite pipeline name not set, check your config at $CONFIG\033[0m"
    exit 1
fi


# Hacky way of getting updated branch names from all updated refs
#  * Ignore deleted branches
#  * Strip commit information, only need ref name
#  * Only trigger for local heads, (no remote refs, no tags)
#  * Strip leading "refs/heads/"
grep --invert-match " 0* " | cut -d " " -f 3 | grep "refs/heads/" | cut -c 12- | while read -r BRANCH; do
    if git show "$BRANCH" --no-patch --format=%B | grep -E "\[(skip ci|ci skip)\]" >/dev/null; then
        continue
    fi
    echo -e "--- Triggering Buildkite build on \033[32m$BRANCH\033[0m"
    if [[ $SKIP_BUILDKITE_API_CALLS_BECAUSE_TESTING != "true" ]]; then
        echo -n "You can view this build at "
        curl --fail --silent -X POST "https://api.buildkite.com/v2/organizations/$BUILDKITE_ORGANIZATION_SLUG/pipelines/$BUILDKITE_PIPELINE_SLUG/builds" \
            -H "Authorization: Bearer $BUILDKITE_API_TOKEN" \
            -d "{
                \"commit\": \"HEAD\",
                \"branch\": \"$BRANCH\"
            }" | jq --raw-output ".web_url"
    else
        echo "Skipping Buildkite API call..."
    fi
done
