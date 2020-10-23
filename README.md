# Installation and usage

The following instructions assume that they are being run from the `<root>` folder (the folder that will contain the data for all projects, the parent folder of this folder).

## 1. Setup

Download the main environment repository.

```bash
./ctl/run setup
```

## 2. Execute a specific project

General deployment:

```bash
./ctl/run launch <project_name>
```

For development (will map repositories to specified paths and make permissions less strict):

```bash
./ctl/run launch -d <project_name>
```

Fast deployment (will skip the preparation steps; avoid using it in production environments):

```bash
./ctl/run launch -f <project_name>
```

Prepare the project environment (will not deploy the project, just prepare it to be deployed, like cloning/pulling git repositories, generating files from templates, moving files, and so on):

```bash
./ctl/run launch -p <project_name>
```

_(If you run `./ctl/run launch -pf <project_name>` all steps will be skipped)_

The first time you run a project, you will be asked to you enter the valt pass to decrypt files for that project, unless you choose to run with the `--no-vault` argument:

```bash
./ctl/run launch --no-vault <project_name>
```

_(The generated project vault file will be at `<root>/secrets/<project_name>/vault`)_

# Encrypt with Ansible

## 1. Generate a ssh key pair and encrypt the private key

```bash
./ctl/run enter
# inside the container
ssh-keygen -t rsa -C "some-name" -f /main/tmp/id_rsa
# [enter the passphrase twice]
ansible-vault encrypt id_rsa
# [enter the vault password twice]
chown "$UID":"$GID" id_rsa id_rsa.pub
exit
```

The generated files will be in the `<root>/ctl/tmp` folder.

## 2. Encrypt strings

```bash
./ctl/run enter
# inside the container
# replace <file> with the name of the variable that will be created
# E.g.: if the variable is called db_pass, use it instead of <file>
ansible-vault encrypt_string --vault-id workspace@prompt --stdin-name '<file>'
# [enter the vault password twice]
# [enter the value to be encripted and press Ctrl+d twice]
exit
```

Then, copy the value displayed in the terminal and paste in the file you want to use it.

## 3. Encrypt files

```bash
# move the file(s) to the <root>/ctl/tmp folder (<root>/ctl/tmp/<file>)
./ctl/run enter
# inside the container
# replace <file> with the file name that you moved to the tmp folder
ansible-vault encrypt --vault-id workspace@prompt `<file>`
# [enter the vault password twice]
# [enter the value to be encripted and press Ctrl+d twice]
exit
```

The generated files will replace the previous files.
