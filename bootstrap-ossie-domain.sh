#!/usr/bin/env bash
#
# bootstrap-ossie-domain.sh — scaffold a domain semantic-model repository
# that consumes the Apache Ossie (incubating) specification.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE in the root of this repository.
#
# What it does:
#   1. Pulls `core-spec/osi-schema.json` and `validation/validate.py` from
#      apache/ossie (local clone or GitHub) and vendors them into the new repo.
#   2. Records the exact upstream ref/SHA in schema/SOURCE.md.
#   3. Stamps the template skeleton (Makefile, CI, docs, example model,
#      AGENTS.md, authoring skill) with your domain name.
#   4. Runs `git init` + an initial commit (unless --no-git).
#
# It never pushes anywhere. Creating the remote is your call.

set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$KIT_DIR/template"
SKILL_DIR="$KIT_DIR/skills/ossie-domain-model"

UPSTREAM_REPO="apache/ossie"
RAW_BASE="https://raw.githubusercontent.com/$UPSTREAM_REPO"
API_BASE="https://api.github.com/repos/$UPSTREAM_REPO"

SCHEMA_PATH_IN_UPSTREAM="core-spec/osi-schema.json"
VALIDATOR_PATH_IN_UPSTREAM="validation/validate.py"

usage() {
  cat <<'EOF'
Usage: bootstrap-ossie-domain.sh <domain> [target-dir] [options]

Arguments:
  <domain>          Domain slug, lowercase (e.g. retail, healthcare, aidt).
  [target-dir]      Where to create the repo. Default: ./<domain>-ossie

Options:
  --from-clone DIR  Use a local apache/ossie clone instead of downloading.
  --ref REF         Upstream branch/tag/SHA to pull from. Default: main.
  --no-git          Skip `git init` and the initial commit.
  --no-skill        Do not install the authoring skill into .claude/skills/.
  -h, --help        Show this help.

Examples:
  ./bootstrap-ossie-domain.sh retail
  ./bootstrap-ossie-domain.sh healthcare ~/git/healthcare-ossie --ref v0.2.0
  ./bootstrap-ossie-domain.sh aidt ../aidt-ossie --from-clone ../ossie
EOF
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
info() { printf '  %s\n' "$*"; }

DOMAIN=""
TARGET=""
FROM_CLONE=""
REF="main"
DO_GIT=1
DO_SKILL=1

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --from-clone) [ $# -ge 2 ] || die "--from-clone requires a path"; FROM_CLONE="$2"; shift 2 ;;
    --ref) [ $# -ge 2 ] || die "--ref requires a value"; REF="$2"; shift 2 ;;
    --no-git) DO_GIT=0; shift ;;
    --no-skill) DO_SKILL=0; shift ;;
    -*) die "unknown option: $1" ;;
    *)
      if [ -z "$DOMAIN" ]; then DOMAIN="$1"
      elif [ -z "$TARGET" ]; then TARGET="$1"
      else die "unexpected argument: $1"
      fi
      shift ;;
  esac
done

[ -n "$DOMAIN" ] || { usage; exit 1; }
case "$DOMAIN" in
  [a-z0-9]*) : ;;
  *) die "domain must start with a lowercase letter or digit: '$DOMAIN'" ;;
esac
case "$DOMAIN" in
  *[!a-z0-9-]*) die "domain may only contain a-z, 0-9 and '-': '$DOMAIN'" ;;
esac
case "$REF" in
  *"|"*) die "ref may not contain '|'" ;;
esac

[ -n "$TARGET" ] || TARGET="./${DOMAIN}-ossie"
[ -d "$TEMPLATE_DIR" ] || die "template/ not found next to this script"

if [ -e "$TARGET" ]; then
  [ -d "$TARGET" ] || die "target exists and is not a directory: $TARGET"
  if [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
    die "target directory is not empty: $TARGET"
  fi
fi
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
REPO_NAME="$(basename "$TARGET")"

# Title Case for prose ("supply-chain" -> "Supply Chain").
DOMAIN_TITLE="$(printf '%s' "$DOMAIN" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"
DATE="$(date +%Y-%m-%d)"
YEAR="$(date +%Y)"

echo "==> Bootstrapping '$DOMAIN' semantic-model repo at $TARGET"

# ---------------------------------------------------------------- upstream ---
mkdir -p "$TARGET/schema" "$TARGET/scripts"

if [ -n "$FROM_CLONE" ]; then
  CLONE="$(cd "$FROM_CLONE" 2>/dev/null && pwd)" || die "no such directory: $FROM_CLONE"
  [ -f "$CLONE/$SCHEMA_PATH_IN_UPSTREAM" ] || die "not an apache/ossie clone: $CLONE ($SCHEMA_PATH_IN_UPSTREAM missing)"
  [ -f "$CLONE/$VALIDATOR_PATH_IN_UPSTREAM" ] || die "not an apache/ossie clone: $CLONE ($VALIDATOR_PATH_IN_UPSTREAM missing)"
  cp "$CLONE/$SCHEMA_PATH_IN_UPSTREAM" "$TARGET/schema/osi-schema.json"
  cp "$CLONE/$VALIDATOR_PATH_IN_UPSTREAM" "$TARGET/scripts/validate.py"
  UPSTREAM_SHA="$(git -C "$CLONE" rev-parse HEAD 2>/dev/null || echo unknown)"
  UPSTREAM_REF="$(git -C "$CLONE" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "$REF")"
  UPSTREAM_ORIGIN="local clone: $CLONE"
  info "vendored from local clone @ ${UPSTREAM_SHA:0:12}"
else
  command -v curl >/dev/null 2>&1 || die "curl is required (or pass --from-clone)"
  curl -fsSL "$RAW_BASE/$REF/$SCHEMA_PATH_IN_UPSTREAM" -o "$TARGET/schema/osi-schema.json" \
    || die "could not download $SCHEMA_PATH_IN_UPSTREAM at ref '$REF'"
  curl -fsSL "$RAW_BASE/$REF/$VALIDATOR_PATH_IN_UPSTREAM" -o "$TARGET/scripts/validate.py" \
    || die "could not download $VALIDATOR_PATH_IN_UPSTREAM at ref '$REF'"
  UPSTREAM_SHA="$(curl -fsSL -H 'Accept: application/vnd.github.sha' "$API_BASE/commits/$REF" 2>/dev/null || echo unknown)"
  UPSTREAM_REF="$REF"
  UPSTREAM_ORIGIN="https://github.com/$UPSTREAM_REPO"
  info "vendored from $UPSTREAM_REPO@$REF (${UPSTREAM_SHA:0:12})"
fi
chmod +x "$TARGET/scripts/validate.py" 2>/dev/null || true

# The spec pins `version` to a const, so the example model must match the
# schema we just vendored. Read it out rather than hardcoding.
SPEC_VERSION="$(
  python3 - "$TARGET/schema/osi-schema.json" <<'PY' 2>/dev/null || true
import json, sys
try:
    s = json.load(open(sys.argv[1]))
    v = s.get("properties", {}).get("version", {})
    print(v.get("const") or (v.get("enum") or [""])[0])
except Exception:
    pass
PY
)"
[ -n "$SPEC_VERSION" ] || die "could not read the pinned spec version out of the schema"
info "spec version: $SPEC_VERSION"

# ---------------------------------------------------------------- skeleton ---
cp -R "$TEMPLATE_DIR/." "$TARGET/"
mv "$TARGET/gitignore" "$TARGET/.gitignore"
mv "$TARGET/editorconfig" "$TARGET/.editorconfig"
mv "$TARGET/_github" "$TARGET/.github"
mv "$TARGET/models/example" "$TARGET/models/$DOMAIN"
mv "$TARGET/models/$DOMAIN/example_semantic_model.yaml" \
   "$TARGET/models/$DOMAIN/${DOMAIN}_example_model.yaml"
cp "$KIT_DIR/LICENSE" "$TARGET/LICENSE"

if [ "$DO_SKILL" -eq 1 ] && [ -d "$SKILL_DIR" ]; then
  mkdir -p "$TARGET/.claude/skills"
  cp -R "$SKILL_DIR" "$TARGET/.claude/skills/ossie-domain-model"
  info "installed skill: .claude/skills/ossie-domain-model"
fi

# --------------------------------------------------------------- stamping ---
stamp() {
  local f="$1"
  sed -i.bak \
    -e "s|{{DOMAIN}}|$DOMAIN|g" \
    -e "s|{{DOMAIN_TITLE}}|$DOMAIN_TITLE|g" \
    -e "s|{{REPO_NAME}}|$REPO_NAME|g" \
    -e "s|{{SPEC_VERSION}}|$SPEC_VERSION|g" \
    -e "s|{{UPSTREAM_REF}}|$UPSTREAM_REF|g" \
    -e "s|{{UPSTREAM_SHA}}|$UPSTREAM_SHA|g" \
    -e "s|{{UPSTREAM_ORIGIN}}|$UPSTREAM_ORIGIN|g" \
    -e "s|{{DATE}}|$DATE|g" \
    -e "s|{{YEAR}}|$YEAR|g" \
    "$f"
  rm -f "$f.bak"
}

while IFS= read -r f; do
  case "$f" in
    "$TARGET/schema/osi-schema.json"|"$TARGET/scripts/validate.py"|"$TARGET/LICENSE") continue ;;
  esac
  stamp "$f"
done < <(find "$TARGET" -type f \
           \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' \
              -o -name 'Makefile' -o -name 'NOTICE' \) \
           -not -path '*/.git/*')

# ------------------------------------------------------------------- git ----
if [ "$DO_GIT" -eq 1 ] && command -v git >/dev/null 2>&1; then
  if [ ! -d "$TARGET/.git" ]; then
    git -C "$TARGET" init -q -b main
    git -C "$TARGET" add -A
    git -C "$TARGET" -c user.useConfigOnly=false commit -q \
      -m "chore: bootstrap $DOMAIN Ossie semantic model repo

Vendored from $UPSTREAM_REPO@$UPSTREAM_REF ($UPSTREAM_SHA):
  $SCHEMA_PATH_IN_UPSTREAM  -> schema/osi-schema.json
  $VALIDATOR_PATH_IN_UPSTREAM -> scripts/validate.py

Generated by ossie-domain-kit." \
      || info "git commit skipped (configure user.name/user.email and commit manually)"
    info "git repo initialised on branch main"
  fi
fi

cat <<EOF

==> Done: $TARGET

Next steps:
  cd $TARGET
  make validate                 # the example model should PASS
  \$EDITOR models/$DOMAIN/${DOMAIN}_example_model.yaml

Then:
  - Replace the example datasets/fields/metrics with real ones.
  - Record where each field's definition came from in docs/overview.md.
  - Wire up a verification layer for your source of truth (docs/verification.md).
EOF
