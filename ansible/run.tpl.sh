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

RED='\033[0;31m'
NC='\033[0m' # No Color

function error {
	msg="$(date '+%F %T') - ${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}"
	>&2 echo -e "${RED}${msg}${NC}"
	exit 2
}

last_index=1

# shellcheck disable=SC2214
while getopts ':efp-:' OPT; do
	last_index="$OPTIND"
	if [ "$OPT" = "-" ]; then     # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		e|enter ) enter="true";;
		f|fast ) args+=( "--fast" );;
		p|prepare ) args+=( "--prepare" );;
		debug ) args+=( "--debug" );;
		\? ) error "[error] unknown short option: -${OPTARG:-}";;
		?* ) error "[error] unknown long option: --${OPT:-}";;
	esac
done

if [ "$last_index" != "$OPTIND" ]; then
	args+=( "--" );
fi

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