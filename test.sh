#!/bin/bash
set -uo pipefail

rm -rf /tmp/mandarin-duck

# Show last command for test output diffs
git config diff.trace.xfuncname "^\+ .*$"

find tests -name "*.test" | while read -r TEST; do
    # Each test should use a namespaced area for its files
    export WORKSPACE="/tmp/mandarin-duck/$TEST"
    mkdir -p "$WORKSPACE"

    # By default, install directory should always be within workspace
    export DESTINATION="$WORKSPACE/mandarin-duck"
    export SKIP_BUILDKITE_API_CALLS_BECAUSE_TESTING=true

    "./$TEST" 2>&1 | perl -pe 's/\x1b\[[0-9;]*[mG]//g' > "${TEST%.test}.trace"
    if git diff --exit-code "${TEST%.test}.trace" >/dev/null; then
        echo -e "--- \033[32m$TEST\033[0m"
    else
        echo -e "--- \033[31m$TEST\033[0m"
        # Re-run diff for pretty output
        git diff -U0 --src-prefix=expected/ --dst-prefix=actual/ "${TEST%.test}.trace"
    fi
done
