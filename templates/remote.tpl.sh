#!/bin/bash
set -euo pipefail

main_dir="{{ params.main_dir }}"
pod_local_name="$1"

shift;

cd "$main_dir"
./run main-cmd ./run run -e env_pod="$pod_local_name"
./run main-cmd /root/r/w/"$pod_local_name"/run ${@}