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

# shellcheck disable=SC2214
while getopts ':ef-:' OPT; do
	if [ "$OPT" = "-" ]; then     # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		e|enter ) enter="true";;
		f|fast ) args+=( "--fast" );;
		'') break;;
		??* ) ;;
		\? ) ;;
	esac
done
shift $((OPTIND-1))

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
    mkdir -p "${project_dir}/dev"
    ln -rsfT "${root_dir}" "${project_dir}/dev/link"
    volumes+=( -v "${root_dir}:/main/dev" )
fi

inner_cmd=( "$run_file" ${args[@]+"${args[@]}"} "${@}" )

if [ "${enter:-}" = 'true' ]; then
    mkdir -p "${project_dir}/tmp"
    echo "${inner_cmd[@]+"${inner_cmd[@]}"}" > "${project_dir}/tmp/cmd"
    inner_cmd=( /bin/bash )
fi

"${cmd[@]}" run --rm -it \
    --name="local-ctl-run-$key" \
    --workdir='/main' \
    -e "FORCE_VAULT=$force_vault" \
    "${volumes[@]}" \
    "$container" \
    ${inner_cmd[@]+"${inner_cmd[@]}"}