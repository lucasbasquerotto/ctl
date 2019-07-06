#!/bin/bash
set -euo pipefail

FORCE="{{ repo_run_force }}"
MAIN_REPO="{{ repo_main_repo_dest }}"
HOSTS="{{ repo_dest }}/var/hosts"
ENV_FILE="{{ repo_dest }}/env/{{ repo.env_file }}"
ENV_FILE_TMP="{{ repo_dest }}/var/{{ repo.env_file }}"
VAULT="{{ repo.use_vault | ternary('--vault-id workspace@prompt', '') }}"
PLAYBOOK="{{ repo.platform }}.yml"

cmp="$(cmp --quiet "$ENV_FILE" "$ENV_FILE_TMP" && echo 0 || echo 1)"

if [ "$FORCE" = "true" ] || [ "$cmp" -eq 1 ]; then
  cd "$MAIN_REPO"
  ansible-playbook $VAULT "$PLAYBOOK" -i "$HOSTS" -e "env_file=$ENV_FILE" "$@"    
  cp "$ENV_FILE" "$ENV_FILE_TMP"
else
  echo 'Already up to date'
fi
