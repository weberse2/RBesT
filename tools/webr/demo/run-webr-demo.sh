#!/bin/sh
# End-to-end demonstration of the wasm/webR build of RBesT: fit the AS data
# set with gMAP() inside webR, against the VFS library image produced by
# `make r-binary-webr`.
#
# Usage (from the repository root, after `make r-binary-webr`):
#
#   tools/webr/demo/run-webr-demo.sh              # fit in webR
#   tools/webr/demo/run-webr-demo.sh --native     # fit in native R
#   tools/webr/demo/run-webr-demo.sh --compare    # both, and diff the numbers
#
# or `make webr-demo` / `make webr-demo-compare`.
#
# The only prerequisites are node and network access the first time (to fetch
# the `webr` npm package matching WEBR_TAG). Everything else -- R itself, the
# whole package library, rstan, the precompiled Stan model -- comes out of the
# built image; the runner points webR's package repository at a dead address so
# nothing can be silently downloaded to paper over a gap.
#
# Environment overrides:
#   WEBR_TAG    webR release to test with; must match the tag the image was
#               built for (default: v0.6.0, same default as the Makefile).
#   WEBR_IMAGE  basename of the VFS image, without .data.gz/.js.metadata
#               (default: the newest build/RBesT-webr-library_*).
#   DEMO_SCRIPT the R script to run (default: tools/webr/demo/as-fit.R).
#   WEBR_NODE_DIR  where to keep the fetched webr npm tree
#               (default: build/webr/node).

set -eu

root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$root"

mode=webr
case "${1:-}" in
  --native)  mode=native ;;
  --compare) mode=compare ;;
  --webr|"") mode=webr ;;
  -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
esac

WEBR_TAG=${WEBR_TAG:-v0.6.0}
DEMO_SCRIPT=${DEMO_SCRIPT:-tools/webr/demo/as-fit.R}
WEBR_NODE_DIR=${WEBR_NODE_DIR:-build/webr/node}

[ -f "$DEMO_SCRIPT" ] || { echo "no such script: $DEMO_SCRIPT" >&2; exit 1; }

find_image() {
  if [ -n "${WEBR_IMAGE:-}" ]; then
    echo "$WEBR_IMAGE"
    return
  fi
  # Newest metadata file wins; strip the suffix to get the basename the
  # driver expects.
  img=$(ls -t build/*-webr-library_*.js.metadata 2>/dev/null | head -n1) || true
  [ -n "${img:-}" ] || {
    echo "no VFS image under build/ -- run 'make r-binary-webr' first," >&2
    echo "or point WEBR_IMAGE at an image basename." >&2
    exit 1
  }
  echo "${img%.js.metadata}"
}

# Fetch the `webr` npm package once, into a directory under build/. The npm
# version must match the container tag the image was built with: webR's VFS
# layout and the R build inside it are versioned together.
ensure_webr() {
  want=${WEBR_TAG#v}
  have=""
  if [ -f "$WEBR_NODE_DIR/node_modules/webr/package.json" ]; then
    have=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' \
      "$WEBR_NODE_DIR/node_modules/webr/package.json" | head -n1)
  fi
  if [ "$have" != "$want" ]; then
    echo "[demo] fetching webr@$want into $WEBR_NODE_DIR (needs network)" >&2
    mkdir -p "$WEBR_NODE_DIR"
    ( cd "$WEBR_NODE_DIR" && \
      npm install --silent --no-package-lock --no-audit --no-fund "webr@$want" )
  fi
}

run_webr() {
  command -v node >/dev/null 2>&1 || {
    echo "node is required to run webR outside a browser" >&2; exit 1; }
  command -v npm >/dev/null 2>&1 || {
    echo "npm is required to fetch the webr package" >&2; exit 1; }
  ensure_webr
  image=$(find_image)
  echo "[demo] image:  $image" >&2
  echo "[demo] webr:   $WEBR_TAG" >&2
  echo "[demo] script: $DEMO_SCRIPT" >&2
  NODE_PATH="$root/$WEBR_NODE_DIR/node_modules" \
  WEBR_VFS="$image" \
    node tools/webr/run-webr-vfs.cjs "$DEMO_SCRIPT"
}

run_native() {
  command -v Rscript >/dev/null 2>&1 || {
    echo "Rscript not found" >&2; exit 1; }
  echo "[demo] script: $DEMO_SCRIPT (native R)" >&2
  Rscript --vanilla "$DEMO_SCRIPT"
}

case "$mode" in
  webr)   run_webr ;;
  native) run_native ;;
  compare)
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    echo "########## webR ##########" >&2
    run_webr | tee "$tmp/webr.log"
    echo "########## native R ##########" >&2
    run_native | tee "$tmp/native.log"
    echo "########## comparison ##########" >&2
    Rscript --vanilla tools/webr/demo/compare-runs.R \
      "$tmp/webr.log" "$tmp/native.log"
    ;;
esac
