#!/bin/bash
set -euo pipefail

force="{{ repo_run_force }}"
main_repo="{{ repo_main_repo_dest }}"
hosts="{{ repo_dest }}/var/hosts"
env_dir="{{ repo_env_dir }}"
env_file="{{ repo_env_dir }}/{{ repo.env_file }}"
env_file_tmp="{{ repo_dest }}/var/{{ repo.env_file }}"
tmp_dir="{{ repo_dest }}/tmp"
vault="{{ repo.use_vault | ternary('--vault-id workspace@prompt', '') }}"
playbook="{{ repo.type }}.yml"
run=1

if [ "$force" != "true" ]; then
  run="$(cmp --quiet "$env_file" "$env_file_tmp" && echo 0 || echo 1)"
fi

if [ "$run" -eq 1 ]; then
  cd "$main_repo"
  ansible-playbook $vault "$playbook" -i "$hosts" \
    -e "env_file=$env_file"-e "env_dir=$env_dir" -e "env_tmp_dir=$tmp_dir" "$@"    
  cp "$env_file" "$env_file_tmp"
else
  echo 'Already up to date'
fi
