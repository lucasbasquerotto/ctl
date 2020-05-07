#!/bin/bash
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

start="$(date '+%F %T')"
echo -e "${CYAN}$start [start] running all contexts ({{ repo_dir | quote }}/{{ repo_file | quote }})${NC}"

{% if (repo_env_ctxs | default([]) | length) > 0 %}
{% for ctx in repo_env_ctxs %}
bash {{ repo_dir | quote }}/ctx/{{ ctx | quote }}/{{ repo_file | quote }} "${@}"
{% endfor %}
{% endif %}

end="$(date '+%F %T')"
echo -e "${CYAN}$end [end] running all contexts ({{ repo_dir | quote }}/{{ repo_file | quote }})${NC}"

echo -e "${GREEN} [ctl] [repo] [run] summary - $start to $end ${NC}"
