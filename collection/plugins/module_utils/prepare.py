#!/usr/bin/python

# (c) 2020, Lucas Basquerotto
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

# pylint: disable=missing-module-docstring
# pylint: disable=missing-function-docstring
# pylint: disable=import-error
# pylint: disable=broad-except

# pyright: reportUnusedImport=true
# pyright: reportUnusedVariable=true
# pyright: reportMissingImports=false

from __future__ import absolute_import, division, print_function
__metaclass__ = type  # pylint: disable=invalid-name

import inspect
import traceback

from ansible_collections.lrd.ctl.plugins.module_utils.lrd_utils import (
    merge_dicts, to_bool
)


def prepare(env_vars, args):
  error_msgs = []

  try:
    result = dict()

    env_vars = env_vars or dict()
    args = args or dict()

    env_dev = to_bool(args.get('env_dev'), False)
    env_project_key = args.get('env_project_key')
    env_migration = args.get('env_migration')
    env_project_dir_relpath = args.get('env_project_dir_relpath')

    allow_dev = env_vars.get('dev')

    if not env_project_key:
      error_msgs += [['msg: project not specified']]
    else:
      if not env_project_dir_relpath:
        error_msgs += [[
            'msg: relative path to the project directory not defined'
        ]]

      if env_dev and not allow_dev:
        error_msgs += [[
            'msg: trying to run in a development environment when '
            + 'dev is not true in the main environment file'
        ]]

      projects = env_vars.get('projects') or dict()
      project = projects.get(env_project_key)

      result['project'] = project

      if project is None:
        error_msgs += [[
            'project: ' + str(env_project_key),
            'msg: project not defined in the main environment file '
            + '(at the "projects" section)'
        ]]
      elif not isinstance(project, dict):
        error_msgs += [[
            'project: ' + str(env_project_key),
            'type: ' + str(type(project)),
            'msg: project not defined as a dictionary in the main environment file '
            + '(at the "projects" section)'
        ]]
      else:
        if not project.get('env_file'):
          error_msgs += [[
              'project: ' + str(env_project_key),
              'msg: environment file not defined for the project'
          ]]

        for key in ['init', 'repo']:
          if (not project.get(key)) and (not project.get('shared_' + key)):
            error_msgs += [[
                'project: ' + str(env_project_key),
                'key: ' + str(key),
                'msg: neither the key nor its shared variant is defined for the project'
            ]]

        for key in ['init', 'repo', 'repo_vault', 'path_params']:
          mapped_key = project.get('shared_' + key)
          value = project.get(key)

          if mapped_key:
            mapped_dict = env_vars.get(key) or dict()
            value = mapped_dict.get(mapped_key)

            if value is None:
              error_msgs += [[
                  'project: ' + str(env_project_key),
                  'shared key (' + str(key) + '): ' + str(mapped_key),
                  'msg: the shared key is not present at the "' + str(key)
                  + '" section in the main environment file'
              ]]
            elif not isinstance(value, dict):
              error_msgs += [[
                  'project: ' + str(env_project_key),
                  'shared key (' + str(key) + '): ' + str(mapped_key),
                  'type: ' + str(type(value)),
                  'msg: the shared key is not defined as a dictionary at '
                  + 'the "' + str(key) +
                  '" section in the main environment file'
              ]]

          result[key] = value

        env_params = project.get('env_params') or dict()
        shared_env_params = project.get('shared_env_params') or list()

        if not isinstance(shared_env_params, list):
          error_msgs += [[
              'project: ' + str(env_project_key),
              'msg: the shared_env_params project property should be a list'
          ]]
        elif not isinstance(env_params, dict):
          error_msgs += [[
              'project: ' + str(env_project_key),
              'shared key (env_params): ' + str(mapped_key),
              'type: ' + str(type(env_params)),
              'msg: env_params not defined as a dictionary for the project'
          ]]
        else:
          mapped_dict = env_vars.get('env_params') or dict()

          for mapped_key in shared_env_params:
            value = mapped_dict.get(mapped_key)

            if value is None:
              error_msgs += [[
                  'project: ' + str(env_project_key),
                  'shared key (env_params): ' + str(mapped_key),
                  'msg: env_params (shared) not defined in the main environment file'
              ]]
            elif not isinstance(value, dict):
              error_msgs += [[
                  'project: ' + str(env_project_key),
                  'shared key (env_params): ' + str(mapped_key),
                  'type: ' + str(type(value)),
                  'msg: env_params (shared) not defined as a dictionary in the '
                  + 'main environment file'
              ]]
            else:
              env_params = merge_dicts(value, env_params)

        result['env_params'] = env_params

        init_params = result.get('init') or dict()

        if not init_params.get('container'):
          error_msgs += [[
              'project: ' + str(env_project_key),
              'msg: container not specified in the project init params'
          ]]

        repo_params = result.get('repo') or dict()

        for key in ['src', 'version']:
          if not repo_params.get(key):
            error_msgs += [[
                'project: ' + str(env_project_key),
                'msg: ' + str(key) + ' not specified in the '
                + 'project repo params'
            ]]

        repo_vault_params = result.get('repo_vault') or dict()

        project_lax = to_bool(project.get('lax'), env_dev)
        project_no_log = to_bool(project.get('no_log'))
        project_repo_ssh_file = (
            'ssh.key' if repo_params.get('ssh_file') else ''
        )
        project_repo_vault_file = (
            'vault' if repo_vault_params.get('file') else ''
        )

        result['lax'] = project_lax
        result['no_log'] = project_no_log
        result['repo_ssh_file'] = project_repo_ssh_file
        result['repo_vault_file'] = project_repo_vault_file

        if not error_msgs:
          project_init_vars = dict(
              key=env_project_key,
              migration=env_migration or project.get('migration') or '',
              ctxs=project.get('ctxs') or [],
              dev=env_dev,
              lax=project_lax,
              no_log=project_no_log,
              project_dir_relpath=env_project_dir_relpath,
              init=dict(
                  container=init_params.get('container'),
                  container_type=init_params.get('container_type') or '',
                  allow_container_type=(
                      to_bool(init_params.get('allow_container_type'), False)
                  ),
                  root=to_bool(init_params.get('root'), False),
                  run_file=init_params.get('run_file') or '/usr/local/bin/run',
              ),
              repo=dict(
                  env_file=project.get('env_file'),
                  src=repo_params.get('src'),
                  version=repo_params.get('version'),
                  ssh_file=project_repo_ssh_file,
              ),
              repo_vault=dict(
                  force=to_bool(repo_vault_params.get('force'), False),
                  file=project_repo_vault_file,
              ),
              env_params=env_params,
              path_params=result.get('path_params') or dict(),
          )
          result['init_vars'] = project_init_vars

          project_init_shell_vars_content = inspect.cleandoc(
              """
              #!/bin/bash
              export key={key}
              export dev={dev}
              export project_dir_relpath={project_dir_relpath}
              export container={container}
              export container_type={container_type}
              export allow_container_type={allow_container_type}
              export container_network={container_network}
              export container_opts={container_opts}
              export root={root}
              export run_file={run_file}
              export force_vault={force_vault}
              """.format(
                  key=repr(project_init_vars.get('key')),
                  dev='true' if project_init_vars.get('dev') else 'false',
                  project_dir_relpath=repr(env_project_dir_relpath),
                  container=repr(init_params.get('container')),
                  container_type=repr(init_params.get('container_type')),
                  allow_container_type=(
                      'true' if init_params.get(
                          'allow_container_type') else 'false'
                  ),
                  container_network=repr(init_params.get('container_network')),
                  container_opts=repr(init_params.get('container_opts')),
                  root='true' if init_params.get('root') else 'false',
                  run_file=repr(project_init_vars.get('init').get('run_file')),
                  force_vault=(
                      'true' if repo_vault_params.get('force') else 'false'
                  ),
              )
          )
          result['init_shell_vars_content'] = project_init_shell_vars_content

    return dict(result=result, error_msgs=error_msgs)
  except Exception as error:
    error_msgs += [[
        'msg: error in the controller preparation step',
        'error type: ' + str(type(error)),
        'error details: ',
        traceback.format_exc().split('\n'),
    ]]
    return dict(error_msgs=error_msgs)
