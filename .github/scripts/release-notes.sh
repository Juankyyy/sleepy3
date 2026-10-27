#!/usr/bin/env bash
#
# Prints the generated release notes for a commit range, grouped by the
# conventional commit type. Used by .github/workflows/release.yml.
#
# Usage:
#   release-notes.sh <from-ref> <to-ref> <new-tag>
#
#   from-ref  Previous tag, or an empty string for the first release.
#   to-ref    Last commit to include (usually HEAD).
#   new-tag   Tag that will name the release; used for the changelog link.
#
# The repository is read from GITHUB_REPOSITORY and GITHUB_SERVER_URL when
# running in Actions, or inferred from the origin remote otherwise.

set -euo pipefail

from_ref="${1:-}"
to_ref="${2:-HEAD}"
new_tag="${3:-}"

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  GITHUB_REPOSITORY="$(git remote get-url origin |
    sed -E 's#^git@github.com:##; s#^https://github.com/##; s#\.git$##')"
fi
server="${GITHUB_SERVER_URL:-https://github.com}"

if [[ -n "$from_ref" ]]; then
  range="${from_ref}..${to_ref}"
else
  range="$to_ref"
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

features="$workdir/features"
fixes="$workdir/fixes"
performance="$workdir/performance"
maintenance="$workdir/maintenance"
: >"$features"
: >"$fixes"
: >"$performance"
: >"$maintenance"

# feat(ui): add history summary
# fix(data)!: drop the legacy table
commit_re='^([a-zA-Z]+)(\(([^)]+)\))?!?:[[:space:]]+(.+)$'

while IFS=$'\t' read -r sha subject; do
  [[ -n "$sha" ]] || continue

  if [[ ! "$subject" =~ $commit_re ]]; then
    continue
  fi

  type="${BASH_REMATCH[1],,}"
  scope="${BASH_REMATCH[3]}"
  description="${BASH_REMATCH[4]}"

  case "$type" in
    feat) target="$features" ;;
    fix) target="$fixes" ;;
    perf) target="$performance" ;;
    *) target="$maintenance" ;;
  esac

  line="- "
  if [[ -n "$scope" ]]; then
    line+="**${scope}**: "
  fi
  line+="${description} ([${sha:0:7}](${server}/${GITHUB_REPOSITORY}/commit/${sha}))"
  printf '%s\n' "$line" >>"$target"
done < <(git log "$range" --no-merges --pretty=tformat:'%H%x09%s')

emit_section() {
  local heading="$1"
  local file="$2"
  if [[ -s "$file" ]]; then
    printf '## %s\n\n' "$heading"
    cat "$file"
    printf '\n'
  fi
}

emit_section "✨ Features" "$features"
emit_section "🐛 Fixes" "$fixes"
emit_section "⚡ Performance" "$performance"
emit_section "🔧 Maintenance" "$maintenance"

if [[ ! -s "$features" && ! -s "$fixes" && ! -s "$performance" && ! -s "$maintenance" ]]; then
  printf 'No user-facing changes recorded in this release.\n\n'
fi

if [[ -n "$from_ref" && -n "$new_tag" ]]; then
  printf '**Full changelog**: %s/%s/compare/%s...%s\n' \
    "$server" "$GITHUB_REPOSITORY" "$from_ref" "$new_tag"
fi
