#!/bin/bash
set -euo pipefail

main_dir="{{ params.main_dir }}"

cd "$main_dir"
./run deploy-pod "${@}"