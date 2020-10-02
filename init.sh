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

echo "project=$project"
echo "dev=${dev:-}"
echo "no_vault=${no_vault:-}"

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

cd "$ctl_dir"
sudo docker-compose up -d ctl-dev
sudo docker-compose exec ctl-dev \
	ansible-playbook \
	${vault[@]+"${vault[@]}"} \
	--extra-vars "env_project_key=$project" \
	--extra-vars "env_root_dir=$root_dir" \
	--extra-vars "env_dev=${dev:-}" \
	init.yml