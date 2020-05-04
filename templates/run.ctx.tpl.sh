#!/bin/bash
set -euo pipefail

#############################################################
##################### Define Variables ######################
#############################################################

base_dir="/root/ctl"
force="{{ repo_run_force }}"
fast="{{ repo_run_fast }}"
cloud_repo="{{ repo_cloud_repo_dest }}"
repo="{{ repo_dest }}"
env_ctx="{{ repo_env_ctx | default('') }}"
var_dir="$repo/ctx/$env_ctx/var"
tmp_dir="$repo/ctx/$env_ctx/tmp"
hosts="$var_dir/hosts"
env_local_repo="{{ repo.local_repo }}"
env_dir="{{ repo_env_dir }}"
env_file="{{ repo_env_dir }}/{{ repo.env_file }}"
env_file_tmp="$var_dir/env.tmp"
vault="{{ repo_force_vault | ternary('--vault-id workspace@prompt', '') }}"
vault_file="$repo/var/vault"
env_local_data_dir="/main/data"
playbook="{{ repo_cloud_entrypoint_rel }}"
env_task_file="/root/ctl/tasks/env.yml"

if [ -f "$vault_file" ]; then
  vault="--vault-id $vault_file"
fi

#############################################################
######### Map Pod Directories for Local Development #########
#############################################################

env_local_pod_dir_list=''

{% set env_local_pod_dir_list = '' -%}

{%- if (repo.local_pod_dir | default({}) | dict2items | length) > 0 %}
{%- for local_pod_dir in repo.local_pod_dir | default({}) | dict2items | sort %}
{% set env_local_pod_dir_list = 
  env_local_pod_dir_list 
  + "-e local_pod_dir_rel_" + local_pod_dir.key 
  + "='" + local_pod_dir.value + "' "
  + "-e local_pod_dir_" + local_pod_dir.key 
  + "='" + repo_base_dir_pod + "/" + local_pod_dir.value + "' "
-%}
env_local_pod_dir_list="$env_local_pod_dir_list {{ env_local_pod_dir_list }}"
{% endfor %}
{% endif %}

#############################################################
######### Map App Directories for Local Development #########
#############################################################

env_local_app_dir_list=''

{% set env_local_app_dir_list = '' -%}

{%- if (repo.local_app_dir | default({}) | dict2items | length) > 0 %}
{%- for local_app_dir in repo.local_app_dir | default({}) | dict2items | sort %}
{% set env_local_app_dir_list = 
  env_local_app_dir_list 
  + "-e local_app_dir_rel_" + local_app_dir.key 
  + "='" + local_app_dir.value + "' "
  + "-e local_app_dir_" + local_app_dir.key 
  + "='" + repo_base_dir_app + "/" + local_app_dir.value + "' "
-%}
env_local_app_dir_list="$env_local_app_dir_list {{ env_local_app_dir_list }}"
{% endfor %}
{% endif %}

#############################################################
################### Execute the Playbook ####################
#############################################################

run=1

if [ "$force" != "true" ]; then
  run="$(cmp --quiet "$env_file" "$env_file_tmp" && echo 0 || echo 1)"
fi

if [ "$run" -eq 1 ]; then
  if [ "$fast" != "true" ]; then
    cd "$base_dir"

    ansible-playbook $vault prepare.ctx.yml \
      -e env_local_repo="$env_local_repo" \
      -e env_dir="$env_dir" \
      -e env_ctx="$env_ctx"
  fi

  cd "$cloud_repo"

  ansible-playbook $vault "$playbook" -i "$hosts" \
    -e env_task_file="$env_task_file" \
    -e env_file="$env_file" \
    -e env_dir="$env_dir" \
    -e env_ctx="$env_ctx" \
    -e env_tmp_dir="$tmp_dir" \
    -e env_local_repo="$env_local_repo" \
    -e env_local_data_dir="$env_local_data_dir" \
    $env_local_pod_dir_list $env_local_app_dir_list "${@}"    
  cp "$env_file" "$env_file_tmp"
else
  echo 'Already up to date'
fi
