#!/usr/bin/env bash
#
# promote-to-prod.sh — the sole mechanism for moving a source ref onto prod.
# Doctrine: docs/standards/gitops-2026-09-10.md rule "10. Promotion".
#
# Fast-forward only. Tagged. Append-only ledger. Never merges, never rebases,
# never forces. Dry-run is the default and mutates nothing.
#
# Gate 5 allowlists the AUTHOR and COMMITTER of every commit in <target>..<source>,
# not the identity running the script: `merge --ff-only` creates no commit, so
# `git config user.email` at push time says nothing about what reaches prod. The
# guard stops agent-authored commits from riding into prod from now on; it cannot
# undo the four already in homelab prod history (pm@dundore.net x2,
# ahab-pm@dundore.net x2).
#
# Usage: promote-to-prod.sh --source <ref> [--push] [--repo <path>]
#   --source  ref to promote (required; missing => usage, exit 2)
#   --push    actually promote: switch, ff-merge, tag, append + commit the ledger, one push
#
# Rollback is the RANGE revert, not revert-to-tag. A fast-forward promotion creates no merge
# commit, so `git revert -m 1 <tag>` reverts the tag's own commit only: measured 2026-09-28, a
# 3-commit promotion left 2 of 3 commits in place and still exited 0. The ledger therefore stores
# `git revert --no-commit <prod-before>..<prod-after> && git commit`, and the tag is an identifier.
#   --repo    repo to operate on (default: the repo containing this script)
#   PROMOTE_ALLOWED_EMAILS   space-separated allowlist, overrides the default
#
# Exit codes
#   0  dry-run completed, or --push completed
#   2  usage / in-progress operation / unreachable origin / unresolvable ref /
#      dirty tree when --push was asked for
#   3  source is not a fast-forward of prod
#   4  submodule pin on prod would move backwards
#   5  a commit in <target>..<source> has a non-allowlisted author or committer
#   6  --push failed (merge, tag, ledger write/commit, or push)
set -euo pipefail

TARGET_BRANCH="prod"
DEFAULT_ALLOWED="walt@dundore.org walt@dundore.net wdundore@d701.dundore.net wdundore@localhost.localdomain"
ALLOWLIST="${PROMOTE_ALLOWED_EMAILS:-$DEFAULT_ALLOWED}"

usage() {
  printf 'usage: %s --source <ref> [--push] [--repo <path>]\n' "${0##*/}" >&2
  printf '       dry-run by default; --push is required to mutate anything\n' >&2
}

die() { # die <exit-code> <gate-label> <line> [<line>...]
  local code="$1" gate="$2" line
  shift 2
  printf 'GATE %s — %s\n' "$gate" "$1" >&2
  shift
  for line in "$@"; do printf '  %s\n' "$line" >&2; done
  exit "$code"
}

note() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*"; }
count_lines() { printf '%s\n' "$1" | grep -c . || true; }

# ---------------------------------------------------------------- arguments
source_ref=""
do_push=0
repo=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --source)
      if [ "$#" -lt 2 ] || [ -z "${2#-}" ]; then usage; exit 2; fi
      source_ref="$2"; shift 2 ;;
    --source=*) source_ref="${1#*=}"; shift ;;
    --push)     do_push=1; shift ;;
    --repo)
      if [ "$#" -lt 2 ] || [ -z "${2#-}" ]; then usage; exit 2; fi
      repo="$2"; shift 2 ;;
    --repo=*)   repo="${1#*=}"; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage; exit 2 ;;
  esac
done
if [ -z "$source_ref" ]; then usage; exit 2; fi

if [ -z "$repo" ]; then
  script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
  repo="$script_dir"
fi

# ------------------------------------------------- gate 1: safe starting point
root="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$root" ]; then
  die 2 "1" "not a git repository: $repo" "next: pass --repo <path> to a git work tree"
fi

gitdir="$(git -C "$root" rev-parse --absolute-git-dir)"
for marker in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG; do
  if [ -e "$gitdir/$marker" ]; then
    die 2 "1" "a $marker operation is in progress" "next: finish or abort it, then re-run"
  fi
done
for redir in rebase-merge rebase-apply; do
  if [ -d "$gitdir/$redir" ]; then
    die 2 "1" "an interactive operation is in progress ($redir)" \
      "next: finish or abort it, then re-run"
  fi
done

dirty="$(git -C "$root" status --porcelain)"
if [ -n "$dirty" ]; then
  if [ "$do_push" -eq 1 ]; then
    die 2 "1" "working tree is not clean; --push refuses to switch branches over it" \
      "dirty entries: $(count_lines "$dirty")" \
      "next: commit or stash them, then re-run"
  fi
  warn "working tree is not clean ($(count_lines "$dirty") entries) — dry-run reads only, but --push would stop here"
fi

if ! git -C "$root" remote get-url origin >/dev/null 2>&1; then
  die 2 "1" "no origin remote" "next: git -C $root remote add origin <url>"
fi
if ! git -C "$root" ls-remote origin >/dev/null 2>&1; then
  die 2 "1" "origin is not reachable: $(git -C "$root" remote get-url origin)" \
    "next: restore access to origin, then re-run (this script never fetches)"
fi

# ------------------------------------------------------ gate 2: refs resolve
source_sha="$(git -C "$root" rev-parse --verify --quiet "${source_ref}^{commit}" || true)"
if [ -z "$source_sha" ]; then
  die 2 "2" "source ref does not resolve to a commit: $source_ref" \
    "next: git -C $root rev-parse --verify $source_ref; fetching is yours to run"
fi

target_sha="$(git -C "$root" rev-parse --verify --quiet "refs/heads/${TARGET_BRANCH}^{commit}" || true)"
if [ -z "$target_sha" ]; then
  die 2 "2" "local branch ${TARGET_BRANCH} does not exist" \
    "next: git -C $root branch ${TARGET_BRANCH} origin/${TARGET_BRANCH}"
fi

repo_name="$(basename "$root")"
origin_target="$(git -C "$root" rev-parse --verify --quiet "refs/remotes/origin/${TARGET_BRANCH}" || true)"

# ------------------------------------------- gate 3: fast-forward only, never merge
if ! git -C "$root" merge-base --is-ancestor "$target_sha" "$source_sha"; then
  if git -C "$root" merge-base --is-ancestor "$source_sha" "$target_sha"; then
    die 3 "3" "${source_ref} is already contained in ${TARGET_BRANCH} — nothing to promote" \
      "source: $(git -C "$root" log -1 --format='%h %ad %s' --date=short "$source_sha")"
  fi
  printf 'GATE 3 — %s is not a fast-forward of %s; this script never merges, rebases or forces\n' \
    "$source_ref" "$TARGET_BRANCH" >&2
  gain_total="$(git -C "$root" rev-list --count "${target_sha}..${source_sha}")"
  behind_total="$(git -C "$root" rev-list --count "${source_sha}..${target_sha}")"
  printf '  to gain (%s..%s): %s total\n' "$TARGET_BRANCH" "$source_ref" "$gain_total" >&2
  git -C "$root" log --oneline "${target_sha}..${source_sha}" | head -20 >&2 || true
  if [ "$gain_total" -gt 20 ]; then
    printf '  (sample: 20 of %s)\n' "$gain_total" >&2
  fi
  printf '  %s holds that %s lacks (%s..%s): %s total\n' \
    "$TARGET_BRANCH" "$source_ref" "$source_ref" "$TARGET_BRANCH" "$behind_total" >&2
  git -C "$root" log --oneline "${source_sha}..${target_sha}" | head -20 >&2 || true
  if [ "$behind_total" -gt 20 ]; then
    printf '  (sample: 20 of %s)\n' "$behind_total" >&2
  fi
  printf '  next: rebase %s onto %s, or promote another ref. Divergence is the operator call.\n' \
    "$source_ref" "$TARGET_BRANCH" >&2
  exit 3
fi

count="$(git -C "$root" rev-list --count "${target_sha}..${source_sha}")"
if [ "$count" -eq 0 ]; then
  die 3 "3" "${source_ref} adds nothing to ${TARGET_BRANCH} — there is nothing to promote" \
    "both are $(git -C "$root" rev-parse --short "$source_sha")"
fi

# --------------------------------------------- gate 4: submodule pins never regress
# The comparison set comes from the two REFS via ls-tree, never from the index: a dirty index must
# not decide what this gate looks at. .gitmodules is not consulted either (it can be absent/stale).
list_gitlinks() {
  git -C "$root" ls-tree -r "$1" \
    | awk -F'\t' '$1 ~ /^160000 commit / { split($1, f, " "); print $2, f[3] }'
}
prod_gitlinks="$(list_gitlinks "$target_sha")"
source_gitlinks="$(list_gitlinks "$source_sha")"
links="$(printf '%s\n' "$prod_gitlinks" | awk 'NF { print $1 }')"
regressions=""
while IFS= read -r path; do
  if [ -z "$path" ]; then continue; fi
  t_pin="$(printf '%s\n' "$prod_gitlinks" | awk -v p="$path" '$1 == p { print $2; exit }')"
  s_pin="$(printf '%s\n' "$source_gitlinks" | awk -v p="$path" '$1 == p { print $2; exit }')"
  if [ -n "$t_pin" ] && [ "$t_pin" = "$s_pin" ]; then continue; fi
  contained=0
  if [ -n "$t_pin" ] && [ -n "$s_pin" ] && [ -e "$root/$path/.git" ]; then
    if git -C "$root/$path" cat-file -e "$t_pin" 2>/dev/null \
       && git -C "$root/$path" cat-file -e "$s_pin" 2>/dev/null \
       && git -C "$root/$path" merge-base --is-ancestor "$t_pin" "$s_pin"; then
      contained=1
    fi
  fi
  if [ "$contained" -eq 0 ]; then
    regressions="${regressions}  ${path}: ${TARGET_BRANCH} pins ${t_pin:-<none>}, ${source_ref} pins ${s_pin:-<none>} (source does not contain the ${TARGET_BRANCH} pin)"$'\n'
  fi
done <<< "$links"
if [ -n "$regressions" ]; then
  printf 'GATE 4 — promoting %s would move a submodule pin backwards or off a known commit\n' "$source_ref" >&2
  printf '%s' "$regressions" >&2
  printf '  next: re-point %s at the %s gitlink (cherry-pick the pin commit), then re-run\n' "$source_ref" "$TARGET_BRANCH" >&2
  printf '  why: a dev->prod sync deleted the submodule pins once already (2133f7d, 3eb3c54)\n' >&2
  exit 4
fi

# --------------------------- gate 5: every promoted commit has an allowlisted author
bad_file="$(mktemp)"
trap 'rm -f "$bad_file"' EXIT
git -C "$root" log --format='%ae%x09%ce' "${target_sha}..${source_sha}" | sort -u \
| while IFS=$'\t' read -r a c; do
    for e in "$a" "$c"; do
      if [ -n "$e" ]; then
        case " $ALLOWLIST " in
          *" $e "*) ;;
          *) printf '%s\n' "$e" ;;
        esac
      fi
    done
  done | sort -u > "$bad_file"
if [ -s "$bad_file" ]; then
  printf 'GATE 5 — a commit in %s..%s has a non-allowlisted author or committer\n' "$TARGET_BRANCH" "$source_ref" >&2
  printf '  offending addresses:\n' >&2
  sed 's/^/    /' "$bad_file" >&2
  printf '  allowlist: %s\n' "$ALLOWLIST" >&2
  printf '  commits involved:\n' >&2
  git -C "$root" log --format='    %h %ae %ce %s' "${target_sha}..${source_sha}" \
    | grep -F -f "$bad_file" >&2 || true
  printf "  next: rewrite or drop those commits; PROMOTE_ALLOWED_EMAILS is the operator's override\n" >&2
  exit 5
fi

# -------------------------------------------------------- gate 6: report, then maybe act
utc_human="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
tag="promote-${repo_name}-$(date -u +%Y%m%dT%H%M%SZ)"
ledger="docs/PROMOTIONS.md"
rollback_cmd="git revert --no-commit ${target_sha}..${source_sha} && git commit -m \"revert promote ${tag}\""
actor="$(git -C "$root" config user.email || echo '<unset>')"

note "repo:    $repo_name ($root)"
note "target:  $TARGET_BRANCH $(git -C "$root" rev-parse --short "$target_sha") ${target_sha}"
if [ -n "$origin_target" ]; then
  note "origin:  origin/$TARGET_BRANCH $(git -C "$root" rev-parse --short "$origin_target")"
fi
note "source:  $source_ref $(git -C "$root" rev-parse --short "$source_sha") ${source_sha}"
note "commits: $count, identities: $(git -C "$root" log --format='%ae' "${target_sha}..${source_sha}" | sort -u | tr '\n' ' ')"
note "would tag: $tag"
note "promotes:"
git -C "$root" log --oneline "${target_sha}..${source_sha}" | sed 's/^/  /' || true
note "diff:"
git -C "$root" diff --stat "${target_sha}..${source_sha}" | sed 's/^/  /' || true
note "rollback: $rollback_cmd"
note "          (a fast-forward promotion creates no merge commit; 'git revert -m 1 $tag' would undo only the tip commit of $count)"

if [ "$do_push" -eq 0 ]; then
  note ""
  note "DRY RUN — nothing was changed. Re-run with --push to promote."
  exit 0
fi

# ------------------------------------------------------------------ --push path
note ""
note "PROMOTING $repo_name: $TARGET_BRANCH $target_sha -> $source_sha"
if ! git -C "$root" switch "$TARGET_BRANCH"; then
  die 6 "6" "could not switch to $TARGET_BRANCH" "next: resolve the worktree state, then re-run"
fi
if ! git -C "$root" merge --ff-only "$source_sha"; then
  die 6 "6" "fast-forward merge failed" "next: nothing was pushed; inspect the merge output"
fi
if ! git -C "$root" tag -a "$tag" -m "promote ${repo_name} ${source_ref} ${source_sha} (rollback: ${target_sha}..${source_sha})"; then
  die 6 "6" "could not create annotated tag $tag" "next: the ff merge already happened; tag it by hand"
fi

if [ ! -f "$root/$ledger" ]; then
  die 6 "6" "ledger $ledger is missing" "next: recreate it with its header, then re-run — nothing has been pushed"
fi
promoted_sha="$(git -C "$root" rev-parse --short HEAD)"
if ! printf '%s | %s | %s %s → %s | %s (%s) | %s | rollback: %s\n' \
  "$utc_human" "$repo_name" "$source_ref" "$(git -C "$root" rev-parse --short "$source_sha")" \
  "$promoted_sha" "$actor" "$(whoami)" "$tag" "$rollback_cmd" \
  >> "$root/$ledger"; then
  die 6 "6" "could not append to $ledger" "next: append the line by hand; the promotion is local and NOT yet pushed"
fi
if ! git -C "$root" add -- "$ledger"; then
  die 6 "6" "could not stage $ledger" "next: stage and commit it by hand, then push — nothing is pushed yet"
fi
if ! git -C "$root" commit -m "promote: ${repo_name} ${tag}"; then
  die 6 "6" "could not commit the ledger line" "next: commit $ledger by hand, then push — nothing is pushed yet"
fi
if ! git -C "$root" push origin "$TARGET_BRANCH" --follow-tags; then
  die 6 "6" "push failed after local commit" "next: push once origin is reachable, or undo locally: $rollback_cmd"
fi

note "pushed $TARGET_BRANCH to origin with the ledger line and tag $tag"
note "ledger: $ledger (one line appended and committed with the promotion)"
note "rollback: $rollback_cmd"
