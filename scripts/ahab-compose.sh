#!/usr/bin/env bash
# =============================================================================
# ahab-compose.sh — the site-manifest resolver (SPEC.md §4)
# =============================================================================
# Owner: ahab (tier-1 machinery). Consumes: MODULE_REGISTRY.yml, the site's
#   ahab-site.yml manifest, modules/<name>/module.yml manifests.
# Affects: writes a generated ansible.cfg (roles_path from the enabled
#   modules + the site's local_roles), a group-layout skeleton, and a tag
#   list — into an output dir (default: a fresh temp dir, printed on exit).
#
# Contract (SPEC §4 + §5.5 step 4): nothing runs without a manifest, and
# every refusal NAMES its cause in human words and exits non-zero. The exit
# code is 2 — the estate loud-fail standard (BLUEPRINT D-39: a surface where
# an unimplemented thing can look successful is a lie waiting to happen).
#
# Usage:  scripts/ahab-compose.sh <site-manifest.yml> [--out <dir>]
#
# YAML note: python3 + PyYAML is required and was probed importable on the
# control node (PyYAML 6.0.2, 2026-09-12); no stdlib fallback is provided —
# if the import fails this script says so and exits non-zero (brief rule:
# documented stop beats a silent-substitute parser).
# =============================================================================
set -euo pipefail

usage() {
    echo "usage: $(basename "$0") <site-manifest.yml> [--out <dir>]" >&2
    echo "  <site-manifest.yml>  your site repo's ahab-site.yml (SPEC §4)" >&2
    echo "  --out <dir>          where to write the generated files" >&2
    echo "                       (default: a fresh temp dir; its path is printed)" >&2
}

MANIFEST=""
OUT_DIR=""
while [ $# -gt 0 ]; do
    case "$1" in
        --out)
            [ $# -ge 2 ] || { echo "ahab-compose: --out needs a directory argument" >&2; exit 2; }
            OUT_DIR="$2"; shift 2 ;;
        -h|--help)
            usage; exit 0 ;;
        -*)
            echo "ahab-compose: unknown option '$1'" >&2; usage; exit 2 ;;
        *)
            [ -z "$MANIFEST" ] || { echo "ahab-compose: more than one manifest given ('$MANIFEST', then '$1')" >&2; exit 2; }
            MANIFEST="$1"; shift ;;
    esac
done

if [ -z "$MANIFEST" ]; then
    echo "ahab-compose: no site manifest given — ahab refuses to run anything without one (SPEC §4)." >&2
    usage
    exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -z "$OUT_DIR" ]; then
    OUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ahab-compose.XXXXXX")"
else
    mkdir -p "$OUT_DIR"
fi
# Absolute, canonicalized: the generated ansible.cfg must work from any cwd.
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

if ! python3 -c 'import yaml' 2>/dev/null; then
    echo "ahab-compose: python3 with PyYAML is required to read YAML manifests and is not importable here. Install it from your distro repo (e.g. the python3-pyyaml package) and run again — this script will not guess-parse your manifests." >&2
    exit 2
fi

export AHAB_ROOT="$REPO_ROOT"
export AHAB_MANIFEST="$MANIFEST"
export AHAB_OUT="$OUT_DIR"

python3 - <<'PY'
"""Resolve registry + site manifest -> generated ansible.cfg/groups/tags.

Refusal policy: every refusal prints one human-readable sentence naming its
cause to stderr and exits 2 (estate loud-fail standard, D-39). No partial
output is ever written on a refusal.
"""
import os
import sys

import yaml

ROOT = os.environ["AHAB_ROOT"]
MANIFEST = os.environ["AHAB_MANIFEST"]
OUT = os.environ["AHAB_OUT"]
REFUSE = 2  # estate loud-fail standard (make catch-all, D-39)


def refuse(cause):
    print(f"ahab-compose: {cause}", file=sys.stderr)
    sys.exit(REFUSE)


def human_list(items):
    return ", ".join(f"'{i}'" for i in items)


def load_yaml(path, what):
    try:
        with open(path, encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
    except FileNotFoundError:
        refuse(f"{what} is missing: {path}")
    except yaml.YAMLError as exc:
        refuse(f"{what} is not valid YAML ({path}): {exc}")
    return data


# --- registry -------------------------------------------------------------
registry_doc = load_yaml(
    os.path.join(ROOT, "MODULE_REGISTRY.yml"),
    "the module registry (MODULE_REGISTRY.yml at the ahab repo root)",
)
try:
    registry_modules = registry_doc["registry"]["modules"]
except (TypeError, KeyError):
    refuse(
        "MODULE_REGISTRY.yml has no `registry: modules:` mapping — the registry "
        "file itself is broken; fix it before enabling anything."
    )

# --- site manifest --------------------------------------------------------
manifest = load_yaml(MANIFEST, "your site manifest")
if not isinstance(manifest, dict):
    refuse(f"your site manifest must be a YAML mapping of keys like `site:` and `modules:` — got {MANIFEST} parsed as {type(manifest).__name__}")

site = manifest.get("site")
modules = manifest.get("modules")
local_roles = manifest.get("local_roles")

if not site or not isinstance(site, str):
    refuse(
        f"your site manifest ({MANIFEST}) must set `site:` to your site's name "
        "(e.g. `site: example.org`) — the resolver needs to know whose stack it is assembling."
    )
if not modules or not isinstance(modules, list):
    refuse(
        f"your site manifest ({MANIFEST}) must set `modules:` to a non-empty list of "
        "ahab modules to enable (e.g. `modules: [bootstrap, docker]`). "
        "Nothing runs without a manifest AND a manifest with no modules runs nothing — that is how mistakes hide."
    )

manifest_dir = os.path.dirname(os.path.abspath(MANIFEST))

# --- enablement: every module must be known, implemented, and well-formed --
enabled = []
for name in modules:
    if not isinstance(name, str) or not name.strip():
        refuse(f"site '{site}': module entries must be plain names — found {name!r} in your modules list.")
    name = name.strip()
    entry = registry_modules.get(name)
    if entry is None:
        known = ", ".join(sorted(registry_modules))
        refuse(
            f"site '{site}' asked to enable unknown module '{name}' — there is no such module in "
            f"MODULE_REGISTRY.yml. Known modules: {known}. "
            f"If '{name}' is a typo, fix it; if it is a new capability, it must be proposed as a module first."
        )
    mod_rel = entry.get("path") or os.path.join("modules", name)
    mod_dir = os.path.join(ROOT, mod_rel)
    manifest_path = os.path.join(mod_dir, "module.yml")
    if not os.path.isfile(manifest_path):
        refuse(
            f"module '{name}' is listed in the registry (status: "
            f"{entry.get('status', '?')}) but not implemented yet — there is no {mod_rel}/module.yml on disk. "
            f"Catalog intent is not code: remove '{name}' from your modules list until it lands."
        )
    mod = load_yaml(manifest_path, f"module '{name}'s manifest ({manifest_path})")
    missing = [k for k in ("name", "version", "roles", "requires", "status") if not isinstance(mod, dict) or k not in mod]
    if missing:
        refuse(
            f"module '{name}'s module.yml is malformed — missing key(s) {human_list(missing)} "
            f"(SPEC §3.1 requires them). This is a defect in the module, not in your manifest."
        )
    for role in mod["roles"] or []:
        if not os.path.isdir(os.path.join(mod_dir, "roles", role)):
            refuse(
                f"module '{name}'s manifest claims role '{role}' but {mod_rel}/roles/{role}/ does not exist. "
                f"Broken module — report it; enabling it would give you a roles_path entry that resolves to nothing."
            )
    enabled.append({"name": name, "dir": mod_dir, "requires": list(mod["requires"] or [])})

# --- dependency refusal (SPEC §3.1: ahab refuses to enable if missing) -----
enabled_names = {m["name"] for m in enabled}
for mod in enabled:
    for dep in mod["requires"]:
        if dep not in enabled_names:
            refuse(
                f"module '{mod['name']}' requires '{dep}', but site '{site}' did not enable '{dep}'. "
                f"Add '{dep}' to the modules list in {MANIFEST} — '{dep}' is a prerequisite of "
                f"'{mod['name']}', and enabling the stack out of order is exactly the failure this refusal exists to catch."
            )

# --- dependency order (stable topological pass) ----------------------------
ordered, pending = [], list(enabled)
while pending:
    progressed = False
    rest = []
    for mod in pending:
        if all(d in {m["name"] for m in ordered} for d in mod["requires"] if d in enabled_names):
            ordered.append(mod)
            progressed = True
        else:
            rest.append(mod)
    if not progressed:
        refuse(
            f"dependency cycle among modules {human_list(m['name'] for m in rest)} — "
            "each waits on another. Modules must form an order, not a circle."
        )
    pending = rest

# --- local_roles (site tier-2 roles, optional) -----------------------------
roles_paths = [os.path.join(m["dir"], "roles") for m in ordered]
if local_roles:
    lr = os.path.normpath(os.path.join(manifest_dir, str(local_roles)))
    if not os.path.isdir(lr):
        refuse(
            f"site '{site}' declares local_roles: '{local_roles}' but that directory does not exist "
            f"(looked for {lr}). Point local_roles at your service-roles directory, or drop the key."
        )
    roles_paths.append(lr)

# --- generation -------------------------------------------------------------
names_in_order = [m["name"] for m in ordered]
cfg_path = os.path.join(OUT, "ansible.cfg")
groups_path = os.path.join(OUT, "group-layout.yml")
tags_path = os.path.join(OUT, "tags")

with open(cfg_path, "w", encoding="utf-8") as fh:
    fh.write(
        "# GENERATED by ahab-compose.sh — DO NOT HAND-EDIT, DO NOT COMMIT.\n"
        f"# site: {site}\n"
        f"# modules (dependency order): {', '.join(names_in_order)}\n"
        "[defaults]\n"
        f"roles_path = {':'.join(roles_paths)}\n"
    )

with open(groups_path, "w", encoding="utf-8") as fh:
    fh.write(
        "# GENERATED by ahab-compose.sh — group layout skeleton for site " + site + ".\n"
        "# One group per enabled module (SPEC §4). Hosts are assigned by inventory\n"
        "# staging (SPEC §5): seed inventory now, NetBox SSoT at M3 — never by hand here.\n"
        "groups:\n"
    )
    for name in names_in_order:
        fh.write(f"  {name}: []\n")

with open(tags_path, "w", encoding="utf-8") as fh:
    fh.write("# GENERATED by ahab-compose.sh — one tag per enabled module (SPEC §4).\n")
    for name in names_in_order:
        fh.write(f"{name}\n")

# --- human summary (stdout) --------------------------------------------------
print(f"ahab-compose: resolved site '{site}' — the socket fits.")
print(f"  enabled modules (dependency order): {', '.join(names_in_order)}")
print(f"  roles_path entries: {len(roles_paths)} ({len(ordered)} module roles dir(s)"
      + (", plus your site's local_roles" if local_roles else "") + ")")
print(f"  group layout: {groups_path}")
print(f"  tags:         {tags_path}")
print(f"  ansible.cfg:  {cfg_path}")
print(f"next step:  ANSIBLE_CONFIG={cfg_path} ansible-playbook <your-playbook.yml>")
PY
