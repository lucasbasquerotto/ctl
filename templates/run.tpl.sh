#!/bin/bash
set -e

cd "{{ main_repo_dest }}"
ansible-playbook "{{ repo.platform }}.yml" -i "{{ repo.dest }}/external/hosts" -e "env_file={{ repo.dest }}/env/{{ repo.env_file }}" 
