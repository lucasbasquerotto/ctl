#!/bin/bash
set -euo pipefail

repo_env_dest={{ repo_env_dest | quote }}
env_local_repo={{ repo.local_repo | quote }}
vault={{ repo_env_repo_vault.force | ternary('--vault-id workspace@prompt', '') | quote }}
vault_file={{ repo_dest | quote }}/var/vault

if [ -f "$vault_file" ]; then
  vault="--vault-id $vault_file"
fi

ansible-playbook $vault prepare.yml \
  -e env_local_repo="$env_local_repo" \
  -e repo_env_dest="$repo_env_dest" \
  ${@}