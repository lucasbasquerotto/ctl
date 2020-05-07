#!/bin/bash
set -euo pipefail

{% if repos | default([]) | list | length > 0 %}
{% for repo in repos | list %}./run prepare "{{ repo.local_repo | quote }}" ${@}
{% endfor %}
{% endif %}
