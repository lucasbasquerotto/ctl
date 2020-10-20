#!/bin/bash
#shellcheck disable=SC2214
set -euo pipefail

CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GRAY='\033[0;90m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function info {
	msg="$(date '+%F %T') - ${1:-}"
	>&2 echo -e "${GRAY}${msg}${NC}"
}

function error {
	msg="$(date '+%F %T') - ${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${1:-}"
	>&2 echo -e "${RED}${msg}${NC}"
	exit 2
}

args=("$@")

while getopts ':c:n:i:-:' OPT; do
	if [ "$OPT" = "-" ]; then    # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"      # extract long option name
		OPTARG="${OPTARG#$OPT}"  # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"     # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		c|ctx ) arg_ctx="${OPTARG:-}";;
		n|node ) arg_node="${OPTARG:-}";;
		i|idx ) arg_idx="${OPTARG:-}";;
		??* ) ;; # bad long option
		\? )  ;; # bad short option (error reported via getopts)
	esac
done
shift $((OPTIND-1))
{% if (repo_ssh_default_ctx | default('')) != '' %}
    {% if not (repo_ssh_default_ctx in (repo_env_ctxs | default([]))) %}
        {% set error = {} %}
        {{ error['error.invalid_ctx.' + repo_ssh_default_ctx] }}
    {% endif %}
    {% set ssh_default_ctx = repo_ssh_default_ctx %}
{% else %}
    {% if (repo_env_ctxs | default([]) | length) == 1 %}
        {% set ssh_default_ctx = repo_env_ctxs[0] %}
    {% endif %}
{% endif %}
{% if (repo_ssh_default_node | default('')) != '' %}
    {% if not (repo_ssh_default_node in (repo_env_nodes | default([]))) %}
        {% set error = {} %}
        {{ error['error.invalid_node.' + repo_ssh_default_node] }}
    {% endif %}
    {% set ssh_default_node = repo_ssh_default_node %}
{% else %}
    {% if (repo_env_nodes | default([]) | length) == 1 %}
        {% set ssh_default_node = repo_env_nodes[0] %}
    {% endif %}
{% endif %}

repo_dir={{ repo_dir | quote }}
ssh_default_ctx={{ ssh_default_ctx | default('') | quote }}
ssh_default_node={{ ssh_default_node | default('') | quote }}

ctx_name="${arg_ctx:-$ssh_default_ctx}"
node_name="${arg_node:-$ssh_default_node}"
instance_index="${arg_idx:-1}"

if [ -z "$ctx_name" ]; then
    error "ctx not defined for ssh (use parameter --ctx or define a default context)"
fi

if [ -z "$node_name" ]; then
    error "node not defined for ssh (use parameter --node or define a default node)"
fi

ctx_dir="$repo_dir/ctx/$ctx_name"
hosts_file="$ctx_dir/var/hosts"

hosts_file_content="$(cat "$hosts_file" || error "error when accessing the file $hosts_file")"

line="$(echo "$hosts_file_content" \
    | grep "instance_type=$node_name " \
    | grep "instance_index=$instance_index " | tail -n 1 || :)"

if [ -z "$line" ]; then
    msg="No line in the hosts file ($hosts_file) of the type '$node_name'"

	if [[ "$instance_index" -gt 1 ]]; then
    	msg="$msg in the index $instance_index (starting in 1)"
	fi
	
    echo -e "${RED}${msg}${NC}"
    exit 1
fi

user=$(echo "$line" | sed -n -e 's/^.*ansible_user=//p' | awk '{ print $1 }')
host=$(echo "$line" | sed -n -e 's/^.*ansible_host=//p' | awk '{ print $1 }')
key_file=$(echo "$line" | sed -n -e 's/^.*ansible_ssh_private_key_file=//p' | awk '{ print $1 }')

if [ -z "$key_file" ]; then
    echo "ssh $user@$host"
    ssh "$user@$host"
else
    echo "ssh -i $key_file $user@$host"
    ssh -i "$key_file" "$user@$host"
fi
