#!/bin/bash
set -eou pipefail

trap 'echo "[error] ${BASH_SOURCE[0]}:$LINENO" >&2; exit 3;' ERR

RED='\033[0;31m'
NC='\033[0m' # No Color

function error {
	msg="[error] $(date '+%F %T') - ${BASH_SOURCE[0]}:${BASH_LINENO[0]}: ${*}"
	>&2 echo -e "${RED}${msg}${NC}"
	exit 2
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ctl_dir="$(cd "$(dirname "$(cd "$(dirname "$script_dir")" && pwd)")" && pwd)"

command="${1:-}"

if [ -z "$command" ]; then
	error "[error] no command entered"
fi

shift;

case "$command" in
	"upgrade"|"u")
        dir="$ctl_dir/env/fluentd"
        file="$dir/fluent.conf"

        if [ -f "$file" ]; then
            chmod 755 "$dir"
            chown 100:100
        fi

        cd "$ctl_dir"
        docker-compose up
		;;
	*)
		error "invalid command: $command"
		;;
esac
