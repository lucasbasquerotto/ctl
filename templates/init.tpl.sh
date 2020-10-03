#!/bin/bash
set -eou pipefail

key='{{ params.key }}'
dev='{{ params.dev | bool | ternary("true", "false") }}'
root_dir='{{ params.root_dir }}'
project_dir_rel='{{ params.project_dir_rel }}'
container='{{ params.init.container }}'
container_type='{{ params.init.container_type }}'
root='{{ params.init.root | bool | ternary("true", "false") }}'

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
    volumes+=( -v "${project_dir}/secrets:/main/secrets" )
    volumes+=( -v "${project_dir}/init:/main/init" )
    volumes+=( -v "${project_dir}/data:/main/data" )
    volumes+=( -v "${root_dir}/envs:/main/envs" )
    volumes+=( -v "${root_dir}/clouds:/main/clouds" )
    volumes+=( -v "${root_dir}/pods:/main/pods" )
    volumes+=( -v "${root_dir}/apps:/main/apps" )
else
    volumes+=( -v "${project_dir}:/main" )
fi

"${cmd[@]}" run --rm -t --name="local-ctl-run-$key" "${volumes[@]}" "$container"