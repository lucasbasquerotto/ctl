# Installation and usage

## 1. Setup

Download the main environment repository, install docker and build the images.

```bash
./run setup
```

## 2. Enter the container with ansible installed

```bash
./run main
```

(For development run `./run dev`)

## 3. Run the playbook to pull and update environment repositories

In the first run it will store the vault password for the private key(s) to download the private repositories.

```bash
# This step should be executed inside the container with Ansible
./run run
```

## 4. Run the playbook for the specific environment repository

The recommended commands are shown after running `./run run`. Example:

```bash
# This step should be executed inside the container with Ansible
/root/r/w/client2-forum/upgrade
```

## 5. Destroy droplets and buckets (dev)

The following should be executed only in a development environment:

```bash
# This step should be executed inside the container with Ansible
/root/r/w/client2-forum/run --tags destroy
```

# Encrypt with Ansible

## 1. Generate a ssh key pair and encrypt the private key

```bash
cd ~
ssh-keygen -t rsa -C "some-name"
[location in '$HOME/id_rsa']
ansible-vault encrypt id_rsa
```

(Add the public key to the repository, so that you can access it through ssh)

## 2. Encrypt strings (for variables, to put in the environment repositories)

```bash
# The VAR_NAME is the name of the variable that will be created
# E.g.: if the variable is called db_pass, use it instead of VAR_NAME
ansible-vault encrypt_string --vault-id workspace@prompt --stdin-name 'VAR_NAME'
[enter the vault password twice]
[enter the value to be encripted and press Ctrl+d twice]
```

## 3. Encrypt files to put in the environment repositories

```bash
ansible-vault encrypt --vault-id workspace@prompt `/path/to/file`
[enter the vault password twice]
[enter the value to be encripted and press Ctrl+d twice]
```

```
#TODO: Generate base image of discourse
#TODO: Add current controller ip to firewall
#TODO: Create snapshot of droplet image
```