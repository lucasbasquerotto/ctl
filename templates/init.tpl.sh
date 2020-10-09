#!/bin/bash
set -eou pipefail

key='{{ params.key }}'
dev='{{ params.dev | bool | ternary("true", "false") }}'
root_dir='{{ params.root_dir }}'
project_dir_rel='{{ params.project_dir_rel }}'
container='{{ params.init.container }}'
container_type='{{ params.init.container_type }}'
root='{{ params.init.root | bool | ternary("true", "false") }}'
run_file='{{ params.init.run_file }}'
force_vault='{{ params.repo_vault.force | bool | ternary("true", "false") }}'

if [ -z "$root_dir" ]; then
    echo "[error] root directory not defined"
    exit 2
fi

project_dir="$root_dir/$project_dir_rel"

if [ "$container_type" != 'docker' ]; then
    echo "[error] unsupported container type: $container_type"
    exit 2
fi

cmd=( "$container_type" )

if [ "$root" = 'true' ]; then
    cmd=( sudo "$container_type" )
fi

volumes=( -v "${project_dir}:/main" )

if [ "$dev" = 'true' ]; then
    volumes+=( -v "${root_dir}:/main/shared" )
fi

"${cmd[@]}" run --rm -t \
    --name="local-ctl-run-$key" \
    -e "FORCE_VAULT=$force_vault" \
    "${volumes[@]}" \
    "$container" \
    "$run_file" \
    "${@}"