#!/usr/bin/env bash
set -eu

echo "Remove all build folders"

rm -rf thorin/build/ impala/build/ runtime/build_vh/ runtime/build_ve/ stincilla/build_vh stincilla/build_ve
