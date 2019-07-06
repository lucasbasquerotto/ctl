#!/bin/bash
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if (docker --version &> /dev/null) && (which docker-compose &> /dev/null); then 
    echo -e "${CYAN}$(date '+%F %T') Docker and Docker Compose already installed${NC}"
else
    echo -e "${CYAN}$(date '+%F %T') Installing Docker and Docker Compose...${NC}"

    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" -y
    sudo apt update
    sudo apt install -y docker-ce

    echo -e "${CYAN}$(date '+%F %T') Docker installed${NC}"

    echo -e "${CYAN}$(date '+%F %T') Installing docker compose (container)...${NC}"

    sudo curl -L --fail https://github.com/docker/compose/releases/download/1.24.0/run.sh -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    echo -e "${CYAN}$(date '+%F %T') Docker compose (container) installed${NC}"

    echo -e "${GREEN}$(date '+%F %T') Docker installed successfully"
fi