#!/bin/bash
set -euo pipefail

{% if repos | default([]) | list | length > 0 %}
{% for repo in repos | list %}./run deploy "{{ repo.local_repo }}" ${@}
{% endfor %}
{% endif %}
