FROM ubuntu:20.04

RUN apt update \
 && apt install -y software-properties-common \
 && apt-add-repository ppa:ansible/ansible -y \
 && apt update \
 && apt install -y python3-pip \
 && pip3 install ansible hvac \
 && rm -rf /var/lib/apt/lists/*
