#!/bin/bash
set -eou pipefail

default_dir_path="$HOME/dev"
default_pod_dir_name="lrd-pod"
default_git_repo_ctl="https://github.com/lucasbasquerotto/ansible-manager"

CYAN='\033[0;36m'
NC='\033[0m' # No Color
    
start="$(date '+%F %T')"

read -r -e -p "Is this a development environment? [Y/n] " yn
dev=""

if [[ $yn == "y" || $yn == "Y" ]]; then
  dev=true
  echo "development"
else
  echo "non-development"
fi

read -r -e -p "Enter the directory path: " -i "$default_dir_path" dir_path
mkdir -p "$dir_path"
cd "$dir_path/"

msg="Enter the specific pod local name to create files from the templates"
msg="$msg (leave empty to create the files for all environment repos): "
read -r -e -p "$msg" -i "" pod_local_name
    
if [ "$dev" = true ]; then
  read -r -e -p "Enter the pod directory name to run at the end of the setup: " \
    -i "$default_pod_dir_name" pod_dir_name
fi

read -r -e -p "Enter the controller git repository: " -i "$default_git_repo_ctl" git_repo_ctl
git clone "$git_repo_ctl" ctl

if [ "$dev" = true ]; then
  echo -e "${CYAN}$(date '+%F %T') setup (dev) started${NC}"
  ./ctl/run setup-dev
  echo -e "${CYAN}$(date '+%F %T') setup (dev) ended${NC}"

  echo -e "${CYAN}$(date '+%F %T') pod migration started${NC}"
  ./pod/"$pod_dir_name"/run migrate
  echo -e "${CYAN}$(date '+%F %T') pod migration ended${NC}"
else
  echo -e "${CYAN}$(date '+%F %T') setup started${NC}"
  ./ctl/run setup
  echo -e "${CYAN}$(date '+%F %T') setup ended${NC}"

  echo -e "${CYAN}$(date '+%F %T') updating the environment repositories files${NC}"
  ./ctl/run main-cmd /root/ctl/run run -e env_name="$pod_local_name"
  echo -e "${CYAN}$(date '+%F %T') environment repositories files updated${NC}"

  if [ ! -z "$pod_local_name" ]; then
    echo -e "${CYAN}$(date '+%F %T') run the upgrade script ($pod_local_name)${NC}"
    ./ctl/run main-cmd "/root/w/r/$pod_local_name/upgrade"
    echo -e "${CYAN}$(date '+%F %T') upgrade script ($pod_local_name) executed${NC}"
  fi
fi

end="$(date '+%F %T')"
echo -e "${CYAN}ended - $start - $end${NC}"