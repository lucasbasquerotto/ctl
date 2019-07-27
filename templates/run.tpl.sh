#!/bin/bash
set -euo pipefail

force="{{ repo_run_force }}"
cloud_repo="{{ repo_cloud_repo_dest }}"
hosts="{{ repo_dest }}/var/hosts"
env_dir="{{ repo_env_dir }}"
env_file="{{ repo_env_dir }}/{{ repo.env_file }}"
env_file_tmp="{{ repo_dest }}/var/{{ repo.env_file }}"
tmp_dir="{{ repo_dest }}/tmp"
vault="{{ repo_use_vault | ternary('--vault-id workspace@prompt', '') }}"
playbook="{{ repo.type }}.yml"
env_local_pod_dir="{{ repo.local_pod_dir | default('') | ternary('-e local_pod_dir=' + repo.local_pod_dir, '') }}"

{% set env_local_app_dir_list = '' -%}

{%- for local_app_dir in repo.local_app_dir_list %}
  {% set env_local_app_dir_list = env_local_app_dir_list + '-e {{ local_app_dir.name }}={{ local_app_dir.dir }}' -%}
{% endfor %}

env_local_app_dir_list="{{ env_local_app_dir_list }}"
run=1

if [ "$force" != "true" ]; then
  run="$(cmp --quiet "$env_file" "$env_file_tmp" && echo 0 || echo 1)"
fi

if [ "$run" -eq 1 ]; then
  cd "$cloud_repo"
  ansible-playbook $vault "$playbook" -i "$hosts" \
    -e "env_file=$env_file" -e "env_dir=$env_dir" -e "env_tmp_dir=$tmp_dir" 
    $env_local_pod_dir $env_local_app_dir_list "$@"    
  cp "$env_file" "$env_file_tmp"
else
  echo 'Already up to date'
fi
