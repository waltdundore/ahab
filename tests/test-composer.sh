#!/usr/bin/env bash
# =============================================================================
# test-composer.sh — the M1 plug-in socket's own test
# =============================================================================
# Owner: ahab (tier-1 machinery). Consumes: scripts/ahab-compose.sh and the
#   three fixture manifests in tests/fixtures/.
# Proves the resolver contract (SPEC §4, D-39 loud-fail standard):
#   1. a valid manifest resolves  -> rc 0, names the site + every enabled
#      module in human words, and writes an ansible.cfg;
#   2. an unknown module          -> rc non-zero, refusal NAMES the module;
#   3. a missing dependency       -> rc non-zero, refusal NAMES the dependency.
# Exits non-zero if ANY check misbehaves (a wrong refusal is as bad as a
# missing one). Run via `make socket-test`.
# =============================================================================
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."

COMPOSE=./scripts/ahab-compose.sh
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0

report() { # report <name> <ok|FAIL> <detail...>
    local name="$1" verdict="$2"; shift 2
    if [ "$verdict" = ok ]; then
        echo "PASS  $name"
    else
        echo "FAIL  $name"
        printf '        %s\n' "$@"
        fail=1
    fi
}

# --- check 1: valid manifest resolves cleanly -------------------------------
out="$TMP/valid.out"; err="$TMP/valid.err"
if "$COMPOSE" tests/fixtures/site-valid.yml --out "$TMP/valid" >"$out" 2>"$err"; then rc=0; else rc=$?; fi
bad=""
[ "$rc" -eq 0 ]                        || bad="$bad rc=$rc (want 0)"
grep -q "example.org" "$out"           || bad="$bad output does not name the site"
for m in bootstrap docker platform; do
    grep -q "$m" "$out"                || bad="$bad output does not name enabled module '$m'"
done
[ -f "$TMP/valid/ansible.cfg" ]        || bad="$bad ansible.cfg was not written"
grep -q "modules/platform/roles" "$TMP/valid/ansible.cfg" 2>/dev/null \
                                       || bad="$bad ansible.cfg roles_path lacks modules/platform/roles"
grep -q "roles_path" "$TMP/valid/ansible.cfg" 2>/dev/null \
                                       || bad="$bad ansible.cfg has no roles_path"
if [ -z "$bad" ]; then report "valid manifest resolves (rc=0, site+modules named, cfg written)" ok
else report "valid manifest resolves" FAIL "problems:$bad"; echo "  --- stdout ---"; cat "$out"; echo "  --- stderr ---"; cat "$err"; fi

# --- check 2: unknown module is refused by name ------------------------------
err="$TMP/unknown.err"
if "$COMPOSE" tests/fixtures/site-unknown-module.yml --out "$TMP/unknown" >/dev/null 2>"$err"; then rc=0; else rc=$?; fi
bad=""
[ "$rc" -ne 0 ]                   || bad="$bad rc=0 (want non-zero: a permissive resolver is the D-39 lie surface)"
grep -qi "teleport" "$err"        || bad="$bad stderr does not NAME the unknown module 'teleport'"
[ -e "$TMP/unknown/ansible.cfg" ] && bad="$bad wrote an ansible.cfg despite the refusal"
if [ -z "$bad" ]; then report "unknown module refused by name (rc=$rc)" ok
else report "unknown module refused" FAIL "problems:$bad"; echo "  --- stderr ---"; cat "$err"; fi

# --- check 3: missing dependency is refused by name --------------------------
err="$TMP/dep.err"
if "$COMPOSE" tests/fixtures/site-missing-dep.yml --out "$TMP/dep" >/dev/null 2>"$err"; then rc=0; else rc=$?; fi
bad=""
[ "$rc" -ne 0 ]               || bad="$bad rc=0 (want non-zero: dependency-less enable is the exact failure SPEC §3.1 refuses)"
grep -qi "docker" "$err"      || bad="$bad stderr does not NAME the missing dependency 'docker'"
grep -qi "platform" "$err"    || bad="$bad stderr does not name the requiring module 'platform'"
[ -e "$TMP/dep/ansible.cfg" ] && bad="$bad wrote an ansible.cfg despite the refusal"
if [ -z "$bad" ]; then report "missing dependency refused, naming 'docker' (rc=$rc)" ok
else report "missing dependency refused" FAIL "problems:$bad"; echo "  --- stderr ---"; cat "$err"; fi

# --- verdict -----------------------------------------------------------------
if [ "$fail" -eq 0 ]; then
    echo "socket-test: all checks passed — the plug-in socket behaves (resolves when honest, refuses when not)."
fi
exit "$fail"
