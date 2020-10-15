#!/bin/bash
set -eou pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function error {
	msg="$(date '+%F %T') - ${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}"
	>&2 echo -e "${RED}${msg}${NC}"
	exit 2
}

args=()
debug=()

# shellcheck disable=SC2214
while getopts ':dfp-:' OPT; do
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		d|dev ) dev="true";;
		f|fast ) fast="true"; args+=( "--fast" );;
		p|prepare ) prepare="true"; args+=( "--prepare" );;
		debug ) debug=( "-vvvvv" ); args+=( "--debug" );;
		no-vault ) no_vault="true";;
		??* ) break;;
		\? )  break;;
	esac
done
shift $((OPTIND-1))

project="${1:-}"
msg_aux=""

if [ "${dev:-}" = "true" ]; then
	msg_aux=" [dev mode]"
fi

start="$(date '+%F %T')"
echo -e "${CYAN}$start [start]$msg_aux running the project ($project)${NC}"

ctl_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "$(dirname "$ctl_dir")" && pwd)"

if [ -z "$project" ]; then
	echo "[error] enter the project name"
	exit 2
fi

shift;

secrets_dir_rel="secrets/projects/$project"
secrets_dir="$root_dir/$secrets_dir_rel"
secrets_dir_container="/main/$secrets_dir_rel"

vault=()

if [ "${no_vault:-}" != "true" ]; then
	mkdir -p "$secrets_dir"

	vault_file="$secrets_dir/vault"

	if [ ! -f "$vault_file" ]; then
		echo -n "Enter the main vault pass (to decrypt the ssh keys of the environment repositories): "
		read -r -s vault_pass
		echo

		touch "$vault_file"
		chmod 600 "$vault_file"
		echo "$vault_pass" > "$vault_file"
	fi

	vault=( '--vault-id' "$secrets_dir_container/vault" )
fi

# shellcheck source=SCRIPTDIR/env-main/env.sh
# shellcheck disable=SC1091
source "${ctl_dir}/env-main/env.sh"

# shellcheck disable=SC2154
var_container="$container"
var_container_type="${container_type:-}"
var_root="${root:-}"

if [ "$var_container_type" = "" ]; then
	var_container_type="docker"
fi

if [ "$var_container_type" != 'docker' ]; then
    echo "[error] unsupported container type: $var_container_type"
    exit 2
fi

cmd=( "$var_container_type" )

if [ "$var_root" = 'true' ]; then
    cmd=( sudo "$var_container_type" )
fi

if [ "${fast:-}" = 'true' ]; then
	echo "[ctl] skipping init project (fast)..."
else
    prepare_args=()

    if [ "${prepare:-}" = 'true' ]; then
        prepare_args=( "${@}" )
    fi

	"${cmd[@]}" run --rm -it \
		--name="local-ctl-init-$project" \
		--workdir "/main/ctl" \
		-v "${ctl_dir}:/main/ctl:ro" \
		-v "${root_dir}/secrets:/main/secrets" \
		-v "${root_dir}/projects:/main/projects" \
		"$var_container" \
		ansible-playbook \
		${prepare_args[@]+"${prepare_args[@]}"} \
		${vault[@]+"${vault[@]}"} \
		${debug[@]+"${debug[@]}"} \
		--extra-vars "env_project_key=$project" \
		--extra-vars "env_root_dir=$root_dir" \
		--extra-vars "env_dev=${dev:-}" \
		init.yml \
		|| error "[error] project $project - init"
fi

bash "${root_dir}/projects/$project/files/ctl/run" \
	${args[@]+"${args[@]}"} "${@}" \
	|| error "[error] project $project - run"

end="$(date '+%F %T')"
echo -e "${CYAN}$end [end]$msg_aux running the project ($project)${NC}"

echo -e "${GREEN} [project - $project] [run$msg_aux] summary - $start to $end ${NC}"
