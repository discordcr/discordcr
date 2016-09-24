#!/bin/bash
set -euo pipefail

# First arg is the release name
RELEASE="${1:-}"

# Save current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# If not on master
if [ "$CURRENT_BRANCH" != "master" ]; then
    # Error out
    echo "Cannot release from outside master!"
    exit 1
fi

# If there are unstaged changes
if ! git diff-index --quiet HEAD; then
    # Error out
    echo "Cannot continue with unstaged changes"
    exit 1
fi

# If there are unstaged changes
u="$(git ls-files --others)"
if ! [ -z "$u" ]; then
    # Error out
    echo "Cannot continue with untracked changes"
    exit 1
fi

# Generate docs
crystal doc

# Copy docs to temp dir
TEMPDIR=$(mktemp -d)
cp -a doc/. "$TEMPDIR"

# Remove docs
rm -Rf doc

# Change to github pages branch
git checkout gh-pages

# Make sure doc dir exists
mkdir doc || true

# Remove old master docs
rm -Rf doc/master

# Copy docs as master
cp -a $TEMPDIR/. doc/master

# If this is a release, copy docs to release dir
if [ -n "$RELEASE" ]; then
    rm -Rf "doc/$RELEASE"
    cp -a $TEMPDIR/. "doc/$RELEASE"
fi

# Make git commit
git add -A
git commit -am "Update docs"

# Push commit
git push

# Switch back to previous branch
git checkout "$CURRENT_BRANCH"
