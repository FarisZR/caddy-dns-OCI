#!/bin/bash
# $1=git link $2 = local hash file $3 remote/file that contains the hash in the repo $4 output name
git ls-remote $1 HEAD > $2

local="$2"
remote="$3"
# if the files match, then it means the build is up-to-date, so no need to rebuild.
if cmp -s "$local" "$remote"; then
    echo "{$4}={false}" >> $GITHUB_OUTPUT
else
    echo "{$4}={true}" >> $GITHUB_OUTPUT
fi