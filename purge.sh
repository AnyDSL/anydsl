#!/usr/bin/env bash
set -eu

echo "Remove all build folders"

rm -rf thorin/build/ impala/build/ runtime/build/ stincilla/build
