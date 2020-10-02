#!/bin/bash
set -eou pipefail

ctl_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "$(dirname "$ctl_dir")" && pwd)"

# shellcheck disable=SC2214
while getopts ':-:' OPT; do
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		dev ) dev="true";;
		no-vault ) no_vault="true";;
		??* ) error "Illegal option --$OPT" ;;  # bad long option
		\? )  exit 2 ;;  # bad short option (error reported via getopts)
	esac
done
shift $((OPTIND-1))

project="${1:-}"

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

"${cmd[@]}" run --rm -t \
	--name="local-ctl-init-$project" \
	--workdir "/main/ctl" \
	-v "${ctl_dir}:/main/ctl:ro" \
	-v "${root_dir}/secrets:/main/secrets" \
	-v "${root_dir}/projects:/main/projects" \
	"$var_container" \
	ansible-playbook \
	${vault[@]+"${vault[@]}"} \
	--extra-vars "env_project_key=$project" \
	--extra-vars "env_root_dir=$root_dir" \
	--extra-vars "env_dev=${dev:-}" \
	init.yml