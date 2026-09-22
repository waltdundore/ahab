#!/usr/bin/env bash
# ==============================================================================
# check-file-refs.sh — reference integrity gate (code surfaces)
# ==============================================================================
# Prevents the "broken reference" error class on the surfaces where a
# reference is a *contract*, not prose: the Makefile and the playbooks.
#
# This is the class of defect found in the 2026-09-20 audit:
#   - the Makefile's milestone-2..8 targets invoked scripts that were never
#     written (failed with "No such file or directory")
#   - playbooks/lamp.yml, webserver.yml, webserver-docker.yml pointed users at
#     a nonexistent playbooks/webservers.yml
#   - playbooks/install-prerequisites.yml documented a `make install-
#     prerequisites` target that did not exist
#
# Scope (deliberately tight — see "why not docs?"):
#   A. Every file a Makefile *recipe line* invokes must exist.
#   B. Every repo-file path a playbook references (another playbook, a role,
#      an inventory file, a script) must resolve — or to a <ref>.example
#      template, which is how inventory/generated files are checked in.
#   C. Every `make <target>` a playbook documents must be a real target.
#
# Why not docs/*.md? Prose legitimately cites sibling repos (dundore-homelab),
# past states, and hypothetical example files, so a strict "every reference
# resolves" rule there produces false positives. Whole-repo doc-truth is
# covered by the doc-truth audit (AUDIT_PLAN.md Phase 1), not this fast gate.
# This gate keeps the *code* honest.
#
# Exit 0 when every reference resolves; exit 1 and print each broken ref.
# ==============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 2

# Recognized first-class top-level directories. A path reference is only
# checked when it starts with one of these (after stripping ./ or ahab/).
TOPDIR='playbooks|scripts|roles|tests|inventory|group_vars|templates|config'
EXT='(yml|yaml|sh|py|md)'

declare -a BROKEN=()

# ----------------------------------------------------------------------------
# ref_exists <relpath>
#   0 if the referenced file exists, or a <relpath>.example template exists
#   (inventory/generated files are committed as *.example, copied at use time).
# ----------------------------------------------------------------------------
ref_exists() {
  local p="$1"
  p="${p#./}"
  p="${p#ahab/}"
  [ -e "$p" ] && return 0
  [ -e "$p.example" ] && return 0
  return 1
}

# Extract candidate repo-file path references from a line/file.
# Prints normalized paths (leading ./ and ahab/ stripped), one per line.
extract_refs() {
  grep -oE "(^|[^A-Za-z0-9_])(\./|ahab/)?(${TOPDIR})/[A-Za-z0-9_./-]+\.${EXT}" "$@" 2>/dev/null \
    | grep -oE "(${TOPDIR})/[A-Za-z0-9_./-]+\.${EXT}" \
    | sed -e 's#^\./##' -e 's#^ahab/##'
}

# ============================================================================
# CHECK A — Makefile recipe lines must only invoke existing files
# ============================================================================
check_makefile() {
  local line path
  while IFS= read -r line; do
    while IFS= read -r path; do
      # Skip shell noise: unexpanded vars, globs, flags.
      [[ "$path" == *'$'* || "$path" == *'*'* || "$path" == -* ]] && continue
      if ! ref_exists "$path"; then
        BROKEN+=("Makefile recipe invokes missing file: $path")
      fi
    done < <(extract_refs <<<"$line")
  done < <(grep -E '^[[:space:]]+[^#]' Makefile 2>/dev/null)
}

# ============================================================================
# CHECK B — playbook path references must resolve
# ============================================================================
check_playbook_refs() {
  local src path
  for src in playbooks/*.yml; do
    [ -f "$src" ] || continue
    while IFS= read -r path; do
      if ! ref_exists "$path"; then
        BROKEN+=("$src: references missing file: $path")
      fi
    done < <(extract_refs "$src")
  done
}

# ============================================================================
# CHECK C — `make <target>` documented in playbooks must be a real target
# ============================================================================
check_playbook_make_targets() {
  local src tgt targets
  targets="$(grep -oE '^[A-Za-z0-9_.-]+:' Makefile 2>/dev/null | tr -d ':' | sort -u)"
  for src in playbooks/*.yml; do
    [ -f "$src" ] || continue
    # `make <target>` docs live in comment lines ("# Called by: make X", "# Usage:").
    # We scan comments only: runtime msg strings can contain English like
    # "make sure ..." and would false-positive. Option words (leading -) skip.
    while IFS= read -r tgt; do
      [[ "$tgt" == -* || -z "$tgt" ]] && continue
      if ! grep -qxF "$tgt" <<<"$targets"; then
        BROKEN+=("$src: documents missing make target: make $tgt")
      fi
    done < <(grep -E '^[[:space:]]*#' "$src" 2>/dev/null \
             | grep -oE 'make +[a-z][a-z0-9_-]*' \
             | grep -oE '[a-z][a-z0-9_-]*$')
  done
}

# ============================================================================
# main
# ============================================================================
check_makefile
check_playbook_refs
check_playbook_make_targets

if [ "${#BROKEN[@]}" -gt 0 ]; then
  echo "❌ check-file-refs: broken reference(s) in code surfaces"
  echo "------------------------------------------------------------"
  printf '%s\n' "${BROKEN[@]}" | sort -u | sed 's/^/  /'
  echo "------------------------------------------------------------"
  echo "Create the missing file/target, or fix the reference."
  exit 1
fi

echo "✅ check-file-refs: Makefile + playbook references all resolve"
exit 0
