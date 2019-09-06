#!/bin/bash
set -euo pipefail

main_dir="{{ params.main_dir }}"
pod_local_name="$1"

shift;

cd "$main_dir"
./run main-cmd ./run run -e env_pod="$pod_local_name"
./run main-cmd /root/r/w/"$pod_local_name"/run "${@}"

# ./run dev-cmd /root/r/w/main/run -e 'env_cmd="./remote.sh wordpress-blog-1"'