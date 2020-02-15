#!/bin/bash
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

start="$(date '+%F %X')"

echo -e "${CYAN}$start [start] running all contexts ({{ repo_dir }}/{{ repo_file }})${NC}"

{% if (repo_env_ctxs | default([]) | length) > 0 %}
{% for ctx in repo_env_ctxs %}
{{ repo_dir }}/{{ repo_file }}.{{ ctx }}.sh "${@}"
{% endfor %}
{% endif %}

end="$(date '+%F %X')"

echo -e "${CYAN}$end [end] running all contexts ({{ repo_dir }}/{{ repo_file }})${NC}"

echo -e "${GREEN}[summary] running all contexts - $start to $end ${NC}"
