#!/bin/bash
set -euo pipefail

main_dir="{{ params.main_dir }}"
pod_local_name="$1"

shift;

cd "$main_dir"
./run deploy-pod "${@}"