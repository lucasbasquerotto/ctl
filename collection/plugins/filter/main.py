#!/usr/bin/python

# pylint: disable=missing-module-docstring
# pylint: disable=missing-class-docstring
# pylint: disable=missing-function-docstring
# pylint: disable=import-error

from __future__ import absolute_import, division, print_function

from ansible_collections.lrd.ctl.plugins.module_utils.lrd_utils import error_text
from ansible_collections.lrd.ctl.plugins.module_utils.prepare import (
    prepare as prepare_ctl
)

from ansible.errors import AnsibleError
from ansible.module_utils._text import to_text


class FilterModule(object):
  def filters(self):
    return {
        'prepare': self.prepare,
    }

  def prepare(self, env_vars, args):
    info = prepare_ctl(env_vars, args)

    result = info.get('result')
    error_msgs = info.get('error_msgs')

    if error_msgs:
      raise AnsibleError(to_text(error_text(error_msgs, 'prepare_ctl')))

    return result
