#!/bin/bash
set -euo pipefail

{% if (repo_env_ctxs | default([]) | length) > 0 %}
{% for ctx in repo_env_ctxs %}
{{ repo_dir }}/{{ repo_file }}.{{ ctx }}.sh "${@}"
{% endfor %}
{% endif %}
