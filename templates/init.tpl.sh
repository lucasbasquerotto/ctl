#!/bin/bash
set -eou pipefail

key='{{ params.key }}'
dev='{{ params.dev | default(false, true) }}'
root_dir='{{ params.root_dir }}'
project_dir_rel='{{ params.project_dir_rel }}'
container='{{ params.container }}'
container_type='{{ params.container_type }}'
root='{{ params.root | bool | ternary("true", "false") }}'

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

volumes=()

if [ "$dev" = 'true' ]; then
    volumes+=( -v "${project_dir}/init:/main/init" )
    volumes+=( -v "${project_dir}/data:/main/data" )
    volumes+=( -v "${root_dir}/envs:/main/envs" )
    volumes+=( -v "${root_dir}/clouds:/main/clouds" )
    volumes+=( -v "${root_dir}/pods:/main/pods" )
    volumes+=( -v "${root_dir}/apps:/main/apps" )
else
    volumes+=( -v "${project_dir}:/main" )
fi

"${cmd[@]}" run --rm --name="local-ctl-init-$key" "${volumes[@]}" "$container"