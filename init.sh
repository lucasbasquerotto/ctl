#!/bin/bash
set -eou pipefail

ctl_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "$(dirname "$ctl_dir")" && pwd)"

dev="false"

if [ "${1:-}" = "--dev" ] || [ "${1:-}" = "-d" ]; then
	dev="true"
	shift;
fi

project="${1:-}"

if [ -z "$project" ]; then
	echo "[error] enter the project name"
	exit 2
fi

shift;

cd "$ctl_dir"
sudo docker-compose up -d ctl-dev
sudo docker-compose exec ctl-dev \
	ansible-playbook \
	--extra-vars "env_project_key=$project" \
	--extra-vars "env_root_dir=$root_dir" \
	--extra-vars "env_dev=${dev:-}" \
	init.yml