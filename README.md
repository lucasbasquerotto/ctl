# (Under Construction) Controller Layer

This repository corresponds to the controller layer and is used to deploy projects. This is the top layer and is responsible to manage and deploy projects. After setting up this layer, you can start deploying projects, according to the projects defined in the [main environment repository](#main-environment-repository).

The deployment of a specific project is done by the cloud layer, which uses the [variables](#controller-output-vars) generated in the [preparation step](#controller-preparation-step) of this layer (controller).

_A default implementation of the cloud layer is located at http://github.com/lucasbasquerotto/cloud._

## Demo

Before start using this layer, it's easier to see it in action. Below is a simple demo used to deploy a project. The demo uses pre-defined [variables generated by the controller layer](#controller-output-vars) so that this layer is not needed to execute, and then execute the [cloud layer](#http://github.com/lucasbasquerotto/cloud) directly to deploy a project.

To execute the demo more easily you will need a container engine (like `docker` or `podman`).

1. Create an empty directory somewhere in your filesystem, let's say, `/var/demo`.

2. Create 2 directories in it: `env` and `data` (the names could be different, just remember to use these directories when mapping volumes to the container).

3. Create a `demo.yml` file inside `env` with the data needed to deploy the project:

```yaml
# Enter the data here (see the demo examples)
```

4. Deploy the project:

```shell
docker run -it --rm -v /var/demo/env:/env:ro -v /var/demo/data:/lrd local/demo
```

**The above commands in a shell script:**

```shell
mkdir -p /var/demo/env /var/demo/data

cat <<'SHELL' > /var/demo/env/demo.yml
# Enter the data here (see the demo examples)
SHELL

docker run -it --rm -v /var/demo/env:/env:ro -v /var/demo/data:/lrd local/demo
```

**That's it. The project was deployed.**

🚀 You can see examples of project deployment demos [here](#TODO).

The demos are great for what they are meant to be: demos, prototypes. **They shouldn't be used for development** (bad DX if you need real time changes without having to push and pull newer versions of repositories, furthermore you are unable to clone repositories in specific locations defined by you in the project folder). **They also shouldn't be used in production environments** due to bad security (the vault value used for decryption is `123456`, and changes to the [project environment repository](#project-environment-repository) may be lost if you forget to push them).

## Root Directory

The `root` folder is the base directory in which the projects managed by the controller are defined. It's the parent of the controller repository (`ctl`) and contains:

- The `secrets` directory: has the vault files to decrypt the ssh files to clone the [projects environment repositories](#project-environment-repository)).

- The `projects` directory: has the project files, secrets and repositories.

- The `users` directory: has the users home directories (when [`use_subuser`](#main-environment-options) is `true`).

- The `data` directory: used mainly in local development environments to contain project deployment data (like logs, databases and uploaded files).

The following instructions assume that they are being run from the `<root>` folder, which will contain the data generated from all projects.

## Setup

The machine that will deploy the projects should have the following tools:

- Bash 4+

- Git

- A container engine (like [docker](https://www.docker.com/) or [podman](https://podman.io/))

To be able to deploy the projects, the controller will need to know which projects to deploy. That information is declared in the [main environment repository](#main-environment-repository). You can manually clone the repository with git at the folder `ctl/env-main` (or point a symlink located at `ctl/env-main` to another location on you machine) or run the following command that will do that for you:

```bash
./ctl/run setup
```

The above command will ask you to enter the repository which willl be cloned (`git clone <git_env_main_repository>`). An alternative is to enter the repository directly like the following:

```bash
./ctl/run setup <git_env_main_repository>
```

If you have a symlink at `ctl/env-main` pointing to an empty directory, the git repository will be cloned at that target repository.

To make things more practical, you can create a repository to become the root folder of your environment and then make an instruction that runs the entire setup step in a more straightforward way, with just a simple command like `./setup`.

This [repository](#) does that, and you can fork it and change only the `env.sh` file, defining in it the controller repository and branch, your main environment repository, and optionally the location of this repository relatively to the root directory (a symlink will be created at `ctl/env-main`).

## Main Environment Repository

The main environment repository will be a hub containing information about the projects to deploy. It will be located at `ctl/env-main` and must have the following files:

- **Main Environment Options File**: `env.sh`

File that will be sourced during [launch](#launch) to know which container engine should run the projects and also which container image it will run. It also has other useful [options](#main-environment-options) and [examples](#main-environment-options-file---examples) explained below.

- **Main Environment Vars File**: `vars.yml`

File that contains the specifications for all projects. It will be used during [launch](#launch) to deploy the project specified in the launch command. See its [structure](#main-environment-vars) and the [example](#main-environment-vars-file---example) below.

## Main Environment Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| <nobr>`container`</nobr> | | The container repository (and tag) that will run the [Controller Preparation Step](#controller-preparation-step). |
| <nobr>`container_type`</nobr> | `docker` | The container engine CLI used when running the container. The command to run the container is the value of this option. The commands accepted by the CLI are assumed to be compatible with the ones from the docker CLI. |
| <nobr>`root`</nobr> | `false` | When `true`, runs the container in the [Controller Preparation Step](#controller-preparation-step) as root (with `sudo`). |
| <nobr>`use_subuser`</nobr> | `false` | When `true`, runs the container in the [Controller Preparation Step](#controller-preparation-step), as well as the container to run the steps in the next layer, with the username `<subuser_prefix><project_name>` (the user will be created if it doesn't exists already, and the home directory will be `users/<username>`). |
| <nobr>`subuser_prefix`</nobr> | | The prefix used to create the user that will run the containers. The username will be `<subuser_prefix><project_name>`. For example, if `subuser_prefix` is `project-` and `project_name` is `my-demo`, the username will be `project-my-demo`. When `use_subuser` is `true`, this option is required and cannot be empty. |

## Main Environment Options File - Examples

An example of the file for a development environment is as follows:

```bash
export container=lucasbasquerotto/ansible:0.0.2
export container_type=podman
```

Another example:

```bash
export container=lucasbasquerotto/ansible:0.0.2
export root=true
```

_The above example will use docker as the container engine (`container_type`)._

An example of the file for a production environment is as follows:

```bash
export container=lucasbasquerotto/ansible:0.0.2
export container_type=podman
export use_subuser=true
export subuser_prefix=project-
```

## Main Environment Vars

| Option | Default | Description |
| ------ | ------- | ----------- |
| <nobr>`dev`</nobr> | `false` | When `true`, defines that the project will run in a development environment. If the value is `false`, the project can't be launched with the [`--dev`](#launch-options) option. |
| <nobr>`init`</nobr> | `{}` | Define a dictionary in which the value of each key is an object of the type specified in the [Init](#main-env-vars---init) section. |
| <nobr>`repo`</nobr> | `{}` | Define a dictionary in which the value of each key is an object of the type specified in the [Repo](#main-env-vars---repo) section. |
| <nobr>`repo_vault`</nobr> | `{}` | Define a dictionary in which the value of each key is an object of the type specified in the [Repo Vault](#main-env-vars---repo-vault) section. |
| <nobr>`env_params`</nobr> | `{}` | Define a dictionary in which the value of each key is an object of the type specified in the [Env Params](#main-env-vars---env-params) section. |
| <nobr>`path_params`</nobr> | `{}` | Define a dictionary in which the value of each key is an object of the type specified in the [Path Params](#main-env-vars---path-params) section. |
| TODO | | |

### Main Env Vars - Init

This object contains data about the container in which the step after the [Controller Preparation Step](#controller-preparation-step) will run.

| Option | Default | Description |
| ------ | ------- | ----------- |
| <nobr>`container`</nobr> | | The container repository (and tag) that will run the steps after the [Controller Preparation Step](#controller-preparation-step). |
| <nobr>`container_type`</nobr> | `docker` | The container engine CLI used when running the container. The command to run the container is the value of this option. The commands accepted by the CLI are assumed to be compatible with the ones from the docker CLI. |
| <nobr>`root`</nobr> | `false` | When `true`, runs the container as root (with `sudo`). |
| <nobr>`run_file`</nobr> | `/usr/local/bin/run` | The executable file to run inside the container after the [Controller Preparation Step](#controller-preparation-step) ends. [See details.](#cloud-layer) |

### Main Env Vars - Repo

This object contains data about the [project environment repository](#project-environment-repository).

| Option | Default | Description |
| ------ | ------- | ----------- |
| <nobr>`src`</nobr> | | The repository source (URL). |
| <nobr>`version`</nobr> | `master` | The repository branch or tag. |
| <nobr>`ssh_file`</nobr> | | (Optional) The location (relative to the [main environment repository](#main-environment-repository)) of the ssh file needed to clone the repository. The file can be in an encrypted with [ansible-vault](#encrypt-and-decrypt) (the key to decrypt the file should be in the [Main Vault File](#main-vault-file)). |

### Main Env Vars - Repo Vault

This object contains the location to the [project vault file](#project-vault-file).

| Option | Default | Description |
| ------ | ------- | ----------- |
| <nobr>`file`</nobr> | | The project vault file (relative to the [project environment repository](#project-environment-repository)). |
| <nobr>`force`</nobr> | `false` | Will ask for the vault passphrase whenever the vault value should be used. This option is only considered if `file` is empty. |

### Main Env Vars - Env Params

This object contains project specific variables. It's expected that the next layer is able to handle this option, merging the options defined here with the options defined in the [project environment file](#project-environment-file). Specifying options here can be convenient to deploy multiple similar projects without having to create a different [project environment file](#project-environment-file) for each case, achieving a more DRY approach. To make staging and production environments more predictable, it's advisable to **not** use this option for such projects.

There are no pre-established properties for this option (they are project specific).

_Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, the variables defined in this option will be accessible through the `params` object in the [project environment file](#project-environment-file)._

### Main Env Vars - Path Params

This object could be considered a special case of the [Env Params](#main-env-vars---env-params) section. It contains paths to repositories, to be mapped to different locations than they would be otherwise. The paths are relative to the root repository.

Repositories mapped this way will be cloned the first time (when the directory is empty) and ignored from then on, allowing the deployment of projects along with real-time changes to the deployment code, if the code is inside one of the mapped repositories.

Mapped repositories can be shared accross different projects as long as the mapped locations are the same.

_Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, this option will be ignored when not running in a development environment ([`dev: false`](#main-environment-vars)). In this case, it accepts the following options:_

| Option | Default | Description |
| ------ | ------- | ----------- |
| <nobr>`path_env`</nobr> | | Path in which the [project environment repository](#project-environment-repository) will be cloned. |
| <nobr>`path_env_base`</nobr> | | Path in which the environment base repository, defined in the `env` option inside [project environment file](#project-environment-file), will be cloned. |
| <nobr>`path_map_repos`</nobr> | `{}` | Dictionary with objects in the form `[repo]: string`, in which repositories defined in the [project environment file](#project-environment-file) are mapped to the specified paths. |

## Main Environment Vars File - Example

```yaml
dev: true

init:
  default:
    container: "lucasbasquerotto/cloud:1.3.6"
    root: true
  other:
    container: "lucasbasquerotto/cloud:1.3.6"
    container_type: "podman"
  other2:
    container: "lucasbasquerotto/cloud"
    container_type: "podman"
    root: true

repo:
  default:
    src: "ssh://git@github.com/lucasbasquerotto/project-env-demo.git"
    version: "master"
    ssh_file: "ssh/repo.encrypted.key"
  other:
    src: "ssh://git@github.com/lucasbasquerotto/other-project-env-demo.git"
    version: "master"
    ssh_file: "ssh/repo.encrypted.key"

repo_vault:
  default:
    file: "vault/main"
  other:
    force: true

env_params:
  local:
    pod_custom_dir_sync: true
    named_volumes: true
  custom:
    name: "my-custom-project"

path_params:
  default:
    path_env: "repos/env"
    path_env_base: "repos/env-base"
    path_map_repos:
      env_base: "repos/env-base"
      cloud: "repos/cloud"
      ext_cloud: "repos/ext-cloud"
      pod: "repos/pod"
      ext_pod: "repos/ext-pod"
      app: "repos/app"

# TODO
```

# Controller Preparation Step

This step is the first and only step executed in the controller layer to launch the project (deployment). The [main environment repository](#main-environment-repository) must be present at `ctl/env-main` so that this step can be run.

This step generates the [Controller Output Vars](#controller-output-vars), as well as the [project ssh key file](#project-ssh-key-file) and the [project vault file](#project-vault-file) to be used by the [next layer](#cloud-layer).

## Main Vault File

The main vault file for a project is located at `secrets/projects/<project_name>/vault` and contains the value to decrypt:

1) The [project ssh key file](#project-ssh-key-file) to clone the [project environment repository](#project-environment-repository).

2) The [project vault file](#project-vault-file) to decrypt the contents of the [project environment file](#project-environment-file).

## Project SSH Key File

The SSH file used to clone the [project environment repository](#project-environment-repository). This file is optional and isn't needed for public repositories, but it's very important that this ssh file is specified if the aforementioned repository has secrets in it (and the repository should be private).

## Project Vault File

The vault file used to decrypt the [project environment file](#project-environment-file) in the [project environment repository](#project-environment-repository). This file is optional, but recommended to be used if the environment file has secrets in it. It's also recommended to make the repository private. The encryption should be done with [ansible-vault](#encrypt-and-decrypt).

# Launch

The launch command deploys a project. It is executed like `ctl/launch ...` (or alternatively `ctl/run launch ...`, or even `ctl/run l ...`) and is responsible to run the [Controller Preparation Step](#controller-preparation-step) and call the command to run the subsequent steps (in the next layers). Below you can see the [options](#launch-options) that can be used with it as well as [examples](#launch-examples) of running this step.

## Launch options

Below are the options that can be used to [launch](#launch) a project:

| Option        | Description |
| ------------- | ----------- |
| <nobr>`-c`</nobr><br><nobr>`--clear`</nobr> | Clears the project directory and ends the execution (may be used to clear the directory when the mapping to the project repositories (during development) changes (with the `path_params` property), which could cause issues with symlinks). If the project was deployed with the `--dev` option, it should be cleared with this option too, like `./ctl/launch -dc <project_name>`. |
| <nobr>`-d`</nobr><br><nobr>`--dev`</nobr> | Runs the project in a development environment. It allows to map paths to repositories to share the repository across multiple projects and avoid cleaning live changes made to the repository that were still not commited (will not update the repository to the version specified, which allows to develop and test changes without the need to push those changes). |
| <nobr>`-e`</nobr><br><nobr>`--enter`</nobr> | Enters the container that runs the preparation step in the controller layer, instead of executing it. The command that would be executed can be seen by running (inside the container) `cat tmp/cmd`. This command doesn't work with the `--inside` option. |
| <nobr>`-f`</nobr><br><nobr>`--force`</nobr> | Force the execution even if the commit of the [project environment repository](#project-environment-repository) is the same as the last time it was executed. |
| <nobr>`-i`</nobr><br><nobr>`--inside`</nobr> | Considers that the current environment is already inside an environment that has the necessary stuff to run the project, without the need to run it inside a container (the environment may already be a container). See [Running Inside a Container](#) and [Running Without Containers](#) for more information. |
| <nobr>`-n`</nobr><br><nobr>`--next`</nobr> | The deployment will use parameters passed after the project name to be used by the next steps. How those parameters will be used depends on what the next step expects them to be.<br><br>_Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, this will expect the parameters specified [here](http://github.com/lucasbasquerotto/cloud#cloud-next-parameters)._ |
| <nobr>`-p`</nobr><br><nobr>`--prepare`</nobr> | Only runs the preparation step and expects that the subsequent layers accept this option so as to run only the preparation step in that layer, and forwards the option to subsequent layers, if needed.<br><br>This has a particular feature that allows to pass arguments to each step that will handle it (as long as subsequent layers handle it). For example, passing the args `-vv` after the project name would generally be used only by the last step ([Cloud Context Main Step](#cloud-context-main-step)), but in this case it will be used as args to run the [Controller Preparation Step](#controller-preparation-step) and no args to subsequent steps.<br><br>You can pass `--` to indicate the end of the arguments for a given step, so the following args `-a -b -- -c -- -d` will pass the args `-a -b` to the [Controller Preparation Step](#controller-preparation-step), and `-c -- -d` to the next step. You can use `--skip` to skip a given step (you shouldn't pass `--` in this case). For example, `--skip -c -- -d` will skip the [Controller Preparation Step](#controller-preparation-step) and pass `-c -- -d` to the next step.<br><br>_Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, this will run the steps [Controller Preparation Step](#controller-preparation-step), [Cloud Preparation Step](http://github.com/lucasbasquerotto/cloud#cloud-preparation-step) and [Cloud Context Preparation Step](http://github.com/lucasbasquerotto/cloud#cloud-context-preparation-step), but won't run the [Cloud Context Main Step](http://github.com/lucasbasquerotto/cloud#cloud-context-main-step). You will have 3 steps in this case, so if you run `ctl/run launch <project_name> -- --skip -vv`, the [Controller Preparation Step](#controller-preparation-step) will run without args, the [Cloud Preparation Step](http://github.com/lucasbasquerotto/cloud#cloud-preparation-step) will be skipped and the [Cloud Context Preparation Step](http://github.com/lucasbasquerotto/cloud#cloud-context-preparation-step) will run in [verbose mode](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html#cmdoption-ansible-playbook-v)_ |
| <nobr>`-P`</nobr><br><nobr>`--no-prompt`</nobr> | By default, the launch expects an unencrypted [vault file](#main-vault-file) at `secrets/projects/<project_name>/vault`. This vault file is used to decrypt values in the main environment repository for a specific project, like the ssh key for the project environment repository, or the vault to be used for the next steps (to decrypt values in the project environment repository). If this file is not present, there is a prompt asking to enter the vault passphrase. This option runs the [Controller Preparation Step](#controller-preparation-step) without the vault file if the file is not present (it's expected that the file was created beforehand, or that the main environment file for this project doesn't use encrypted values to be decrypted using a vault file, otherwise an error will be thrown). |
| <nobr>`-s`</nobr><br><nobr>`--fast`</nobr> | Skips the [Controller Preparation Step](#controller-preparation-step) and may skip preparation steps in subsequent layers (if those layers use this option and forwards it to the next layer).<br><br>_Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, this will skip the [Controller Preparation Step](#controller-preparation-step), [Cloud Preparation Step](http://github.com/lucasbasquerotto/cloud#cloud-preparation-step) and [Cloud Context Preparation Step](http://github.com/lucasbasquerotto/cloud#cloud-context-preparation-step), running only the [Cloud Context Main Step](http://github.com/lucasbasquerotto/cloud#cloud-context-main-step) for each context._ |
| <nobr>`-V`</nobr><br><nobr>`--no-vault`</nobr> | By default, the launch expects an unencrypted [vault file](#main-vault-file) at `secrets/projects/<project_name>/vault`. This vault file is used to decrypt values in the main environment repository for a specific project, like the ssh key for the project environment repository, or the vault to be used for the next steps (to decrypt values in the project environment repository). This option runs the [Controller Preparation Step](#controller-preparation-step) without the vault file (it's expected that the main environment file for this project doesn't use encrypted values to be decrypted using a vault file, otherwise an error will be thrown). |
| <nobr>`--ctl`</nobr> | Runs only the [Controller Preparation Step](#controller-preparation-step) and generates the [Controller Output Vars](#controller-output-vars). Usiful to generate the variables that will be used in a demo that doesn't need the controller layer, like the [official demo](#). |
| <nobr>`--debug`</nobr> | Runs in verbose mode and forwards this option to the subsequent step. |
| <nobr>`--migration`</nobr> | Runs with the project `migration` parameter set as the value specified in this parameter. This value overrides the `migration` value specified for the project in the `vars.yml` file in the [Main Environment Repository](#main-environment-repository) (when both are specified). This parameter is useful to make sure that an automated process deploy the project only if this value is the same as the one specified for the environment. This is also useful to make sure that a migration that must run manually doesn't run automatically (the automatic process would fail in the preparation step, because the migration value is different from the one specified in the environment file, then you can run manually specifying this parameter explicitly when launching the project). |
| <nobr>`-w`</nobr><br><nobr>`--new-pass`</nobr> | Clears the project secrets directory (the directory that stores the passphrase used to decrypt the project variables at the main environment repository, which is asked right after deploying the project for the first time). It can be useful when the passphrase changed or is wrong, so as to ask a new pass when deploying the project (if the `--no-vault` was not specified). It can be used together with the `--clear` option. If the project was deployed with the `--dev` option, the secrets should be cleared with this option too, like `./ctl/launch -dw <project_name>`. |

## Launch Examples

General deployment:

```bash
./ctl/launch <project_name>
```

_(Or `ctl/run launch <project_name>`, also equivalent to `ctl/run l <project_name>`)_

For development (will map repositories to specified paths and make permissions less strict by default):

```bash
./ctl/launch -d <project_name>
```

_(Commonly used with the `-f`/`--force` and `-s`/`--fast` flags)_

Fast deployment (will skip the preparation steps; avoid using it in production environments):

```bash
./ctl/run launch -s <project_name>
```

Force a run, and run only the main step, in a development environment (using `-f`/`--force`, because subsequent runs with the same commit for the environment repository defined for the project would skip the deployment without this flag, but during development, with live changes, this is probably not wanted, so this flag force the deployment):

```bash
./ctl/run launch -dfs <project_name>
```

Prepare the project environment (will not deploy the project, just prepare it to be deployed, like cloning/pulling git repositories, generating files from templates, moving files, and so on):

```bash
./ctl/launch -p <project_name>
```

_If you run `ctl/launch -ps <project_name>` all steps will be skipped, unless some step treats it as a special case. Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, this will run only some tasks of the [Cloud Context Preparation Step](http://github.com/lucasbasquerotto/cloud#cloud-context-preparation-step), tasks that don't require a network connection, so it should be pretty fast. Mainly used for schema validation during development (running with `./ctl/run launch -dps <project_name>`), in this case._

The first time you run a project, you will be asked to you enter the valt pass to decrypt files for that project, unless you choose to run with the `--no-vault` argument:

```bash
./ctl/launch --no-vault <project_name>
```

_(The generated project vault file will be at `<root>/secrets/<project_name>/vault`)_

## Controller Output Vars

The [Controller Preparation Step](#controller-preparation-step) generates 2 files with variables, 1 is to be sourced by a shell script (`vars.sh`) with the parameters needed to execute the next step, and the other is a yaml file with variables to be used by the next [step](#cloud-layer).

The yaml file has the following structure (the values may differ):

```yaml
ctxs: []
dev: 'true'
env_params:
  env_dir: common
init:
  allow_container_type: false
  container: lucasbasquerotto/cloud:1.4.9
  container_type: docker
  root: true
  run_file: /usr/local/bin/run
key: demo
lax: true
no_log: false
migration: ''
path_params:
  path_env: repos/env
project_dir_relpath: projects/demo
repo:
  env_file: common/demo.yml
  src: https://github.com/lucasbasquerotto/env-base.git
  ssh_file: ''
  version: master
repo_vault:
  file: ''
  force: false
```

| Option | Description |
| ------ | ----------- |
| <nobr>`ctxs`</nobr> | Array with the contexts defined for the project. |
| <nobr>`dev`</nobr> | Boolean (or string equivalent) to specify if the project will run in development mode. |
| <nobr>`env_params`</nobr> | Object with the parameters specified in the `vars.yml` file in the [main environment repository](#main-environment-repository). The parameters used will depend on the project and can be accessed in the [project environment file](#project-environment-file). |
| <nobr>`init.allow_container_type`</nobr> | Boolean (or string equivalent) to specify if the container engine that will deploy the project is to be allowed even if it's not one of the supported engines (docker and podman). |
| <nobr>`init.container`</nobr> | The container image that will deploy the project. |
| <nobr>`init.container_type`</nobr> | The container engine that will run the container that will deploy the project. |
| <nobr>`init.root`</nobr> | Boolean (or string equivalent) to specify if the container should be run as root. |
| <nobr>`init.run_file`</nobr> | Path to the file inside the container that will serve as an entrypoint to deploy the project. |
| <nobr>`key`</nobr> | Unique identifier of the project. |
| <nobr>`lax`</nobr> | Indicates if files and directories created and copied during the deployment will have less strict permissions (when `true`; recommended when in development). |
| <nobr>`migration`</nobr> | This will set the `migration` variable to be used to compare with the `migration` variable defined in the [project environment file](#project-environment-file), throwing an error in the preparation step, when the later value is defined and is different than the first `migration` variable. |
| <nobr>`no_log`</nobr> | When `true`, won't print the ansible plays, tasks and module arguments, as well as outputs. Use only if absolutely necessary. |
| <nobr>`path_params`</nobr> | Dictionary of repositories and paths in which the repositories should be cloned when in development mode. The exact structure of this parameter should be defined in the next steps.<br><br>_Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, The expected structure of this parameter is defined [here](http://github.com/lucasbasquerotto/cloud#cloud-input-vars)._ |
| <nobr>`project_dir_relpath`</nobr> | Path, relative to the [controller root directory](#root-directory), in which the artifacts created by this project are located. **This indicates where the project directory is located.**. |
| <nobr>`repo.env_file`</nobr> | The location of the [project environment file](#project-environment-file), inside the project environment repository. |
| <nobr>`repo.src`</nobr> | The source of the [project environment repository](#project-environment-repository). |
| <nobr>`repo.ssh_file`</nobr> | When specified (non empty), is the path in which the ssh key file to be used to clone the repository (when private) is located (the original path is relative to the [main environment repository](#main-environment-repository), but at this point the original file was already copied, and possibly decrypted, to a path inside the project directory, `project_base_dir`). |
| <nobr>`repo.version`</nobr> | The version (branch/tag) of the [project environment repository](#project-environment-repository). |
| <nobr>`repo_vault.file`</nobr> | Path to the vault file with the pass to decrypt the project encrypted values. |
| <nobr>`repo_vault.force`</nobr> | Boolean (or string equivalent) to specify if the vault pass will be prompted if a vault file is not specified (when there isn't a vault file (`repo_vault.file` is empty), and `repo_vault.force` is `false`, the project mustn't have encrypted values, or an error will be thrown, when trying to decrypt them). |

The shell file has the following structure (the values may differ):

```bash
export key=demo
export dev=true
export project_dir_relpath=projects/demo
export container=lucasbasquerotto/cloud:1.4.9
export container_type=docker
export allow_container_type=false
export root=true
export run_file=/usr/local/bin/run
export force_vault=false
```

| Option | Description |
| ------ | ----------- |
| <nobr>`key`</nobr> | Equivalent to `key` in the `vars.yml` file explained above. |
| <nobr>`dev`</nobr> | Equivalent to `dev` in the `vars.yml` file explained above. |
| <nobr>`project_dir_relpath`</nobr> | Equivalent to `project_dir_relpath` in the `vars.yml` file explained above. |
| <nobr>`container`</nobr> | Equivalent to `init.container` in the `vars.yml` file explained above. |
| <nobr>`container_type`</nobr> | Equivalent to `init.container_type` in the `vars.yml` file explained above. |
| <nobr>`allow_container_type`</nobr> | Equivalent to `init.allow_container_type` in the `vars.yml` file explained above. |
| <nobr>`root`</nobr> | Equivalent to `init.root` in the `vars.yml` file explained above. |
| <nobr>`run_file`</nobr> | Equivalent to `init.run_file` in the `vars.yml` file explained above. |
| <nobr>`force_vault`</nobr> | Equivalent to `repo_vault.force` in the `vars.yml` file explained above. |

The values of the files above are the output after running `./run launch --dev demo` with the `vars.yml` in the main environment repository being the same as the [example](#main-environment-vars-file---example) above.

# Project Environment Repository

This is the repository that contains project specific stuff, in special, the [project environment file](#project-environment-file).

## Project Environment File

The file that will act as an entrypoint to deploy the project. Contains the project specific variables.

_Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, this file will follow the structure defined [here](#http://github.com/lucasbasquerotto/cloud#environment-file)._

# Cloud Layer

After running the [Controller Preparation Step](#controller-preparation-step), the next step will run inside the [container](#main-env-vars---init) defined for the project, running the file `/usr/local/bin/run` by default (or the file defined in the `run_file` option).

This file will be executed forwarding the following [launch options](#launch-options), if specified:

- `s` / `fast`
- `p` / `prepare`
- `debug`

The above options should be handled appropriately by the cloud layer. Other than them, there's also the following option:

- `project-dir`: the project directory inside the container.

This layer should load [Controller Output Vars](#controller-output-vars) located at `<project_dir>/files/ctl/vars.yml`, clone the [project environment repository](#project-environment-repository) defined in the `repo` variable, load the file at `repo.env_file` inside the repository, decrypt the file with the key specified in the vault file defined in the `repo_vault.file` variable (or ask for the vault pass if `repo_vault.force` for `true`). Than it should include the values specified at `env_params`. **The (decrypted) value of `env_file` defines the project environment.** From then on, it's up to the Cloud Layer to define what to do with this information.

The `migration` variable should be used to compare with the `migration` variable in the project environment, if specified, so as to allow deployments only if both values are the same. The same validation should be done with `init.container`.

_Using the cloud layer defined at http://github.com/lucasbasquerotto/cloud, the executable file is already at `/usr/local/bin/run`. The details of what is done at this point are defined at the [Cloud Preparation Step](http://github.com/lucasbasquerotto/cloud#cloud-preparation-step)._

# Encrypt and Decrypt

To encrypt and decrypt values and files, use `ansible-vault` as defined below:

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
ansible-vault encrypt_string
# [enter the vault password twice]
# [enter the value to be encrypted and press Ctrl+d twice]
exit
```

Then, copy the value displayed in the terminal and paste in the file you want to use it.

When encrypting several strings with the same vault password, it might be useful to create a file with the vault password, and then using this file as the password source for more efficiency:

```bash
./ctl/run enter
# [enter the vault password as the value of <password>]
echo '<password>' > /main/tmp/pass.txt

# encrypt string...
ansible-vault encrypt_string --vault-password-file /main/tmp/pass.txt
# [enter the value to be encrypted and press Ctrl+d twice]

# new encryption...
ansible-vault encrypt_string --vault-password-file /main/tmp/pass.txt
# [enter the value to be encrypted and press Ctrl+d twice]

# and again...
ansible-vault encrypt_string --vault-password-file /main/tmp/pass.txt
# [enter the value to be encrypted and press Ctrl+d twice]

exit
```

### 2.1. Decrypt strings


```bash
./ctl/run enter
# inside the container
ansible-vault decrypt
# [enter the vault password]
# [enter the value to be decrypted (without spaces and without !vault) and press Ctrl+d twice]
exit
```

## 3. Encrypt files

```bash
# move the file(s) to the <root>/ctl/tmp folder (<root>/ctl/tmp/<file>)
./ctl/run enter
# inside the container
# replace <file> with the file name that you moved to the tmp folder
ansible-vault encrypt `<file>`
# [enter the vault password twice]
exit
```

The generated files will replace the previous files. It may be necessary to change the file owner or permission to access it from the host.

When encrypting several files, it might be useful to create a file with the vault password, and then using this file as the password source for more efficiency:

```bash
./ctl/run enter
# [enter the vault password as the value of <password>]
echo '<password>' > /main/tmp/pass.txt

# encrypt file...
ansible-vault encrypt --vault-password-file /main/tmp/pass.txt /main/tmp/my-file-1.txt

# new encryption...
ansible-vault encrypt --vault-password-file /main/tmp/pass.txt /main/tmp/my-file-2.txt

# and again...
ansible-vault encrypt --vault-password-file /main/tmp/pass.txt /main/tmp/my-file-3.txt

exit
```

### 3.1. Decrypt files

```bash
# move the file(s) to the <root>/ctl/tmp folder (<root>/ctl/tmp/<file>)
./ctl/run enter
# inside the container
# replace <file> with the file name that you moved to the tmp folder
ansible-vault decrypt `<file>`
# [enter the vault password]
exit
```

### 4. Decrypt the project environment file

To decrypt the entire project environemnt file (after applied to the project environment base file, if defined), when using the default [cloud layer](#http://github.com/lucasbasquerotto/cloud), you can run the `launch` command with the `--next` option passing `printenv` as an argument, like the following example:

```bash
./ctl/launch --next <project_name> --printenv
```

This will generate the unencrypted environment content and place it in a file at `<project_dir>/secrets/cloud/env.yml`.
