#!/bin/bash
set -euo pipefail

force="{{ repo_run_force }}"
cloud_repo="{{ repo_cloud_repo_dest }}"
repo="{{ repo_dest }}"
hosts="$repo/var/hosts"
env_local_repo="{{ repo.local_repo }}"
env_dir="{{ repo_env_dir }}"
env_file="{{ repo_env_dir }}/{{ repo.env_file }}"
env_file_tmp="$repo/var/{{ repo.env_file }}"
tmp_dir="$repo/tmp"
vault="{{ repo_force_vault | ternary('--vault-id workspace@prompt', '') }}"
vault_file="$repo/var/vault"
playbook="{{ repo.type }}.yml"

if [ -f "$vault_file" ]; then
  vault="--vault-id $vault_file"
fi

{% set env_local_pod_dir = 
  (repo.local_pod_dir is defined) 
  | ternary(
  '-e local_pod_dir_rel="' + (repo.local_pod_dir | default('')) + '" ' +
  '-e local_pod_dir="' + repo_base_dir_pod + '/' + (repo.local_pod_dir | default('')) + '"'
  , '') 
  | default('') 
-%}

env_local_pod_dir='{{ env_local_pod_dir }}'
env_local_app_dir_list=''

{% set env_local_app_dir_list = '' -%}

{%- if repo.local_app_dir_list is defined %}
{%- for local_app_dir in repo.local_app_dir_list %}
{% set env_local_app_dir_list = 
  env_local_app_dir_list 
  + '-e local_app_dir_rel_' + local_app_dir.name 
  + '="' + local_app_dir.dir + '" ' 
  + '-e local_app_dir_' + local_app_dir.name 
  + '="' + repo_base_dir_app + '/' + local_app_dir.dir + '"' 
-%}
env_local_app_dir_list='{{ env_local_app_dir_list }}'
{% endfor %}
{% endif %}

run=1

if [ "$force" != "true" ]; then
  run="$(cmp --quiet "$env_file" "$env_file_tmp" && echo 0 || echo 1)"
fi

if [ "$run" -eq 1 ]; then
  cd "$cloud_repo"

  printf 'Arg: %s\n' ansible-playbook $vault "$playbook" -i "$hosts" \
    -e "env_file=$env_file" -e "env_dir=$env_dir" -e "env_tmp_dir=$tmp_dir" \
    -e env_local_repo="$env_local_repo" $env_local_pod_dir $env_local_app_dir_list "${@}"    


  ansible-playbook $vault "$playbook" -i "$hosts" \
    -e "env_file=$env_file" -e "env_dir=$env_dir" -e "env_tmp_dir=$tmp_dir" \
    -e env_local_repo="$env_local_repo" $env_local_pod_dir $env_local_app_dir_list "${@}"    
  cp "$env_file" "$env_file_tmp"
else
  echo 'Already up to date'
fi
