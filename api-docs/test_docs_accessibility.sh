#!/usr/bin/env bash
# Copyright (c) Magnon Compute Corporation. All rights reserved.
#
# Static accessibility/status-honesty checks for api-docs/index.html, the
# local Redoc viewer for this repo's openapi.yaml.
#
# Shell-based rather than a JUnit test: this is a static HTML/YAML check
# unrelated to the Flink operator's Java build, and the repo's existing
# `e2e-tests/` directory already uses shell scripts for out-of-band checks
# (test_bluegreen_stateless.sh, test_snapshot.sh, etc.) — this follows that
# convention instead of forcing a Maven module for a file-existence check.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTML="$SCRIPT_DIR/index.html"
SPEC="$SCRIPT_DIR/../openapi.yaml"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[[ -f "$HTML" ]] || fail "index.html missing"
[[ -f "$SPEC" ]] || fail "../openapi.yaml missing"
pass "docs page exists next to spec"

grep -q '<html lang="en">' "$HTML" || fail "missing lang attribute"
pass "declares document language"

SKIP_TARGET=$(grep -oE '<a href="#[^"]+" class="magnon-docs-skip-link">' "$HTML" | sed -E 's/.*#([^"]+)".*/\1/') || true
[[ -n "$SKIP_TARGET" ]] || fail "missing skip link"
grep -q "id=\"$SKIP_TARGET\"" "$HTML" || fail "skip link targets #$SKIP_TARGET but no element declares that id"
pass "has a working skip link"

grep -Eq '<main id="magnon-docs-content"[^>]*tabindex="-1"[^>]*>' "$HTML" || fail "main landmark missing tabindex=\"-1\""
grep -q '<redoc' "$HTML" || fail "missing <redoc> element"
pass "skip target is a focusable main landmark"

grep -q '<noscript>' "$HTML" || fail "missing noscript fallback"
grep -q '../openapi.yaml' "$HTML" || fail "noscript fallback does not link to the raw spec"
pass "has noscript fallback to raw spec"

grep -q 'prefers-reduced-motion' "$HTML" || fail "missing reduced-motion safety net"
pass "respects reduced motion"

SPEC_URL=$(grep -oE 'spec-url="[^"]+"' "$HTML" | sed -E 's/spec-url="([^"]+)"/\1/')
[[ "$SPEC_URL" == "../openapi.yaml" ]] || fail "spec-url ($SPEC_URL) does not point at ../openapi.yaml"
pass "spec-url points at the real spec file"

grep -q '\[TODO: Add detailed description\]' "$SPEC" || fail \
  "openapi.yaml no longer has the [TODO] placeholder — update api-docs/index.html's banner and this test together"
grep -q 'No routes auto-discovered' "$SPEC" || fail \
  "openapi.yaml now has auto-discovered routes — update api-docs/index.html's banner and this test together"
grep -q 'Scaffold spec, not a contract' "$HTML" || fail "missing scaffold-status banner text"
pass "scaffold-status banner matches the spec's own TODO/no-routes markers"

PATH_COUNT=$(grep -cE '^  /(healthz|metrics):' "$SPEC")
[[ "$PATH_COUNT" -eq 2 ]] || fail "expected exactly /healthz and /metrics in openapi.yaml, found $PATH_COUNT matching paths"
ALL_PATHS=$(grep -E '^  /\S+:' "$SPEC" | wc -l | tr -d ' ')
[[ "$ALL_PATHS" -eq 2 ]] || fail "openapi.yaml documents $ALL_PATHS paths, expected exactly 2 (/healthz, /metrics) for this banner to remain accurate"
pass "banner does not overclaim beyond healthz/metrics"

echo "All api-docs accessibility/status-honesty checks passed."
