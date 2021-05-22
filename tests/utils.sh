#!/bin/bash

function update_config {
    set +x
    TEMP=$(mktemp)
    jq "$2" "$1" > "$TEMP"
    mv "$TEMP" "$1"
    set -x
}

