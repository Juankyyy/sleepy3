#!/usr/bin/env bash
#
# Computes the tag and Android version code for a manual stable release.
#
# Usage:
#   BUMP=minor|patch|exact GITHUB_REF_NAME=main GITHUB_SHA=<sha> \
#     [VERSION=X.Y.Z] bash .github/scripts/compute-release-version.sh
#
# Environment:
#   BUMP             Required. "minor" bumps v0.X.0; "patch" bumps v0.X.Y;
#                    "exact" publishes VERSION as-is.
#   VERSION          Required when BUMP=exact. The X.Y.Z version to publish.
#   GITHUB_REF_NAME  Required. Must be "main"; releases only run from main.
#   GITHUB_SHA       Required. Commit that will be tagged.
#   GITHUB_OUTPUT    Optional. When set, tag/version/code/previous are appended.
#
# The repository must be checked out with its tags (fetch-depth: 0).
#
# Re-running a dispatch is idempotent: when a tag of the requested kind already
# points at GITHUB_SHA, that tag is reused instead of bumping again.

set -euo pipefail

bump="${BUMP:-}"
ref="${GITHUB_REF_NAME:-}"
sha="${GITHUB_SHA:-}"

if [[ "$ref" != "main" ]]; then
  echo "::error::Releases only run from main (got '${ref:-<unset>}')."
  exit 1
fi

case "$bump" in
  minor | patch | exact) ;;
  *)
    echo "::error::Invalid bump '${bump:-<unset>}'. Expected 'minor', 'patch' or 'exact'."
    exit 1
    ;;
esac

if [[ -z "$sha" ]]; then
  echo "::error::GITHUB_SHA is required."
  exit 1
fi

semver='^v[0-9]+\.[0-9]+\.[0-9]+$'
latest="$(git tag --list 'v*' | grep -E "$semver" | sort -V | tail -n 1 || true)"

# Old development pre-releases (v0.0.x) can share a commit with the first stable
# release. Only tags at or above the first stable minor (the lowest vX.Y.0) are
# reused; anything below it is historical and must not become stable again.
baseline="$(git tag --list 'v*' | grep -E '^v[0-9]+\.[0-9]+\.0$' | sort -V | head -n 1 || true)"

version_ge() {
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" == "$2" ]]
}

if [[ "$bump" == "exact" ]]; then
  # Publish the version the maintainer names instead of the next one. The tag
  # still comes from the workflow, and a re-run reuses it when it already
  # points at this commit.
  version="${VERSION:-}"
  if [[ ! "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    echo "::error::VERSION must be X.Y.Z for bump=exact (got '${version:-<unset>}')."
    exit 1
  fi
  tag="v${version}"

  if [[ -n "$latest" ]] && ! version_ge "$latest" "$tag"; then
    echo "::error::Version $tag must be greater than the latest tag $latest."
    exit 1
  fi

  existing="$(git rev-list -n 1 "refs/tags/$tag" 2>/dev/null || true)"
  if [[ -n "$existing" && "$existing" != "$sha" ]]; then
    echo "::error::Tag $tag already exists at $existing, not at $sha."
    exit 1
  fi
  if [[ -n "$existing" ]]; then
    echo "Reusing $tag: it already points at $sha."
  fi
else
  # Reuse a tag of the requested kind that already points at this commit. This
  # keeps re-runs (including old runs) from publishing a second version.
  tag=""
  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    if [[ -n "$baseline" ]] && ! version_ge "$baseline" "$candidate"; then
      continue
    fi
    candidate_patch=$((10#${candidate##*.}))
    if [[ "$bump" == "minor" && $candidate_patch -eq 0 ]] ||
      [[ "$bump" == "patch" && $candidate_patch -gt 0 ]]; then
      tag="$candidate"
    fi
  done < <(git tag --points-at "$sha" | grep -E "$semver" | sort -V)

  if [[ -n "$tag" ]]; then
    echo "Reusing $tag: it already points at $sha."
  else
    if [[ -n "$latest" ]]; then
      IFS=. read -r major minor patch <<<"${latest#v}"
    else
      major=0
      minor=0
      patch=0
    fi

    if [[ "$bump" == "minor" ]]; then
      minor=$((10#$minor + 1))
      patch=0
    else
      patch=$((10#$patch + 1))
    fi
    tag="v${major}.${minor}.${patch}"

    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
      echo "::error::Tag $tag already exists."
      exit 1
    fi
  fi
fi

version="${tag#v}"
IFS=. read -r major minor patch <<<"$version"
if ((10#$minor > 999 || 10#$patch > 999)); then
  echo "::error::Minor and patch must be <= 999 for the version code formula."
  exit 1
fi
code=$((10#$major * 1000000 + 10#$minor * 1000 + 10#$patch))

# The generated notes cover everything since the previous release. When a tag
# is reused, stop at it so the range excludes the release being re-published.
previous=""
while IFS= read -r candidate; do
  [[ -n "$candidate" ]] || continue
  [[ "$candidate" == "$tag" ]] && break
  previous="$candidate"
done < <(git tag --list 'v*' | grep -E "$semver" | sort -V)

{
  echo "tag=$tag"
  echo "version=$version"
  echo "code=$code"
  echo "previous=$previous"
} >>"${GITHUB_OUTPUT:-/dev/null}"

echo "Releasing $tag from main (versionCode $code, previous tag '${previous:-none}')."
