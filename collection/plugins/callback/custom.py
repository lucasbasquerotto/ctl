# (c) 2012-2014, Michael DeHaan <michael.dehaan@gmail.com>
# (c) 2017 Ansible Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

# pylint: disable=missing-module-docstring
# pylint: disable=missing-function-docstring
# pylint: disable=import-error
# pylint: disable=protected-access
# pylint: disable=invalid-name
# pylint: disable=unused-argument

from __future__ import (absolute_import, division, print_function)

import datetime
import json
import re
import string

import yaml

from ansible.parsing.yaml.dumper import AnsibleDumper
from ansible.module_utils._text import to_text
from ansible.utils.color import colorize, hostcolor
from ansible.plugins.callback import CallbackBase, strip_internal_keys, module_response_deepcopy
from ansible.playbook.task_include import TaskInclude
from ansible import context
from ansible import constants as C

__metaclass__ = type  # pylint: disable=invalid-name

DOCUMENTATION = '''
    callback: default
    type: stdout
    short_description: default Ansible screen output
    version_added: historical
    description:
        - This is the default output callback for ansible-playbook.
    extends_documentation_fragment:
      - default_callback
    requirements:
      - set as stdout in configuration
'''


# from http://stackoverflow.com/a/15423007/115478

def should_use_block(value):
  """Returns true if string should be in block format"""
  for char in u"\u000a\u000d\u001c\u001d\u001e\u0085\u2028\u2029":
    if char in value:
      return True
  return False


def my_represent_scalar(self, tag, value, style=None):
  """Uses block style for multi-line strings"""
  if style is None:
    if should_use_block(value):
      style = '|'
      # we care more about readable than accuracy, so...
      # ...no trailing space
      value = value.rstrip()
      # ...and non-printable characters
      value = ''.join(x for x in value if x in string.printable)
      # ...tabs prevent blocks from expanding
      value = value.expandtabs()
      # ...and odd bits of whitespace
      value = re.sub(r'[\x0b\x0c\r]', '', value)
      # ...as does trailing space
      value = re.sub(r' +\n', '\n', value)
    else:
      style = self.default_style
  node = yaml.representer.ScalarNode(tag, value, style=style)
  if self.alias_key is not None:
    self.represented_objects[self.alias_key] = node
  return node


# These values use ansible.constants for historical reasons, mostly to allow
# unmodified derivative plugins to work. However, newer options added to the
# plugin are not also added to ansible.constants, so authors of derivative
# callback plugins will eventually need to add a reference to the common docs
# fragment for the 'default' callback plugin

# these are used to provide backwards compat with old plugins that subclass from default
# but still don't use the new config system and/or fail to document the options
COMPAT_OPTIONS = (('display_skipped_hosts', C.DISPLAY_SKIPPED_HOSTS),
                  ('display_ok_hosts', True),
                  ('show_custom_stats', C.SHOW_CUSTOM_STATS),
                  ('display_failed_stderr', False),)


class CallbackModule(CallbackBase):

  '''
  This is the default callback interface, which simply prints messages
  to stdout when new callback events are received.
  '''

  CALLBACK_VERSION = 2.0
  CALLBACK_TYPE = 'stdout'
  CALLBACK_NAME = 'default'

  def __init__(self):

    self._play = None
    self._last_task_banner = None
    self._last_task_name = None
    self._task_type_cache = {}
    super(CallbackModule, self).__init__()
    yaml.representer.BaseRepresenter.represent_scalar = my_represent_scalar

  def __getattr__(self, item):
    return None

  def set_options(self, task_keys=None, var_options=None, direct=None):

    super(CallbackModule, self).set_options(
        task_keys=task_keys, var_options=var_options, direct=direct)

    # for backwards compat with plugins subclassing default, fallback to constants
    for option, constant in COMPAT_OPTIONS:
      try:
        value = self.get_option(option)
      except (AttributeError, KeyError):
        value = constant
      setattr(self, option, value)

  def v2_runner_on_failed(self, result, ignore_errors=False):

    delegated_vars = result._result.get('_ansible_delegated_vars', None)
    self._clean_results(result._result, result._task.action)

    if self._last_task_banner != result._task._uuid:
      self._print_task_banner(result._task)

    self._handle_exception(
        result._result, use_stderr=self.display_failed_stderr)
    self._handle_warnings(result._result)

    if result._task.loop and 'results' in result._result:
      self._process_items(result)

    else:
      if delegated_vars:
        self._display.display(
            "fatal: [%s -> %s]: FAILED! => %s"
            % (
                result._host.get_name(),
                delegated_vars['ansible_host'],
                self._dump_results(result._result)
            ),
            color=C.COLOR_ERROR, stderr=self.display_failed_stderr
        )
      else:
        self._display.display(
            "fatal: [%s]: FAILED! => %s"
            % (result._host.get_name(), self._dump_results(result._result)),
            color=C.COLOR_ERROR, stderr=self.display_failed_stderr
        )

    if ignore_errors:
      self._display.display("...ignoring", color=C.COLOR_SKIP)

  def v2_runner_on_ok(self, result):
    delegated_vars = result._result.get('_ansible_delegated_vars', None)

    if isinstance(result._task, TaskInclude):
      return
    elif result._result.get('changed', False):
      if self._last_task_banner != result._task._uuid:
        self._print_task_banner(result._task)

      if delegated_vars:
        msg = "changed: [%s -> %s]" % (result._host.get_name(),
                                       delegated_vars['ansible_host'])
      else:
        msg = "changed: [%s]" % result._host.get_name()
      color = C.COLOR_CHANGED
    else:
      if not self.display_ok_hosts:
        if not 'print_action' in result._task.tags:
          return

      if 'no_print' in self._task.tags:
        return

      if self._last_task_banner != result._task._uuid:
        self._print_task_banner(result._task)

      if delegated_vars:
        msg = "ok: [%s -> %s]" % (result._host.get_name(),
                                  delegated_vars['ansible_host'])
      else:
        msg = "ok: [%s]" % result._host.get_name()
      color = C.COLOR_OK

    self._handle_warnings(result._result)

    if result._task.loop and 'results' in result._result:
      self._process_items(result)
    else:
      self._clean_results(result._result, result._task.action)

      if ((self._display.verbosity > 0 or '_ansible_verbose_always' in result._result)
              and '_ansible_verbose_override' not in result._result):
        msg += " => %s" % (self._dump_results(result._result),)
      self._display.display(msg, color=color)

  def v2_runner_on_skipped(self, result):
    if 'no_print' in self._task.tags:
      return

    if 'no_print_skipped' in self._task.tags:
      return

    if self.display_skipped_hosts or ('print_skipped_action' in result._task.tags):

      self._clean_results(result._result, result._task.action)

      if self._last_task_banner != result._task._uuid:
        self._print_task_banner(result._task)

      if result._task.loop and 'results' in result._result:
        self._process_items(result)
      else:
        msg = "skipping: [%s]" % result._host.get_name()
        if ((self._display.verbosity > 0 or '_ansible_verbose_always' in result._result)
                and '_ansible_verbose_override' not in result._result):
          msg += " => %s" % self._dump_results(result._result)
        self._display.display(msg, color=C.COLOR_SKIP)

  def v2_runner_on_unreachable(self, result):
    if self._last_task_banner != result._task._uuid:
      self._print_task_banner(result._task)

    delegated_vars = result._result.get('_ansible_delegated_vars', None)
    if delegated_vars:
      msg = "fatal: [%s -> %s]: UNREACHABLE! => %s" % (result._host.get_name(
      ), delegated_vars['ansible_host'], self._dump_results(result._result))
    else:
      msg = "fatal: [%s]: UNREACHABLE! => %s" % (
          result._host.get_name(), self._dump_results(result._result))
    self._display.display(msg, color=C.COLOR_UNREACHABLE,
                          stderr=self.display_failed_stderr)

  def v2_playbook_on_no_hosts_matched(self):
    self._display.display("skipping: no hosts matched", color=C.COLOR_SKIP)

  def v2_playbook_on_no_hosts_remaining(self):
    self._display.banner("NO MORE HOSTS LEFT")

  def v2_playbook_on_task_start(self, task, is_conditional):
    self._task = task  # pylint: disable=attribute-defined-outside-init
    self._task_start(task, prefix='TASK')

  def _task_start(self, task, prefix=None):
    # Cache output prefix for task if provided
    # This is needed to properly display 'RUNNING HANDLER' and similar
    # when hiding skipped/ok task results
    if prefix is not None:
      self._task_type_cache[task._uuid] = prefix

    # Preserve task name, as all vars may not be available for templating
    # when we need it later
    if self._play.strategy == 'free':
      # Explicitly set to None for strategy 'free' to account for any cached
      # task title from a previous non-free play
      self._last_task_name = None
    else:
      self._last_task_name = task.get_name().strip()

      if 'no_print' in self._task.tags:
        return

      if 'no_print_skipped' in self._task.tags:
        return

      # Display the task banner immediately if we're not doing any filtering based on task result
      if self.display_skipped_hosts and self.display_ok_hosts:
        self._print_task_banner(task)

  def _print_task_banner(self, task):
    # args can be specified as no_log in several places: in the task or in
    # the argument spec.  We can check whether the task is no_log but the
    # argument spec can't be because that is only run on the target
    # machine and we haven't run it thereyet at this time.
    #
    # So we give people a config option to affect display of the args so
    # that they can secure this if they feel that their stdout is insecure
    # (shoulder surfing, logging stdout straight to a file, etc).
    args = ''
    if not task.no_log and C.DISPLAY_ARGS_TO_STDOUT:
      args = u', '.join(u'%s=%s' % a for a in task.args.items())
      args = u' %s' % args

    prefix = self._task_type_cache.get(task._uuid, 'TASK')

    # Use cached task name
    task_name = self._last_task_name
    if task_name is None:
      task_name = task.get_name().strip()

    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    self._display.banner(u"%s [%s - %s%s]" % (prefix, now, task_name, args))
    if self._display.verbosity >= 2:
      path = task.get_path()
      if path:
        self._display.display(u"task path: %s" % path, color=C.COLOR_DEBUG)

    self._last_task_banner = task._uuid

  def v2_playbook_on_cleanup_task_start(self, task):
    self._task_start(task, prefix='CLEANUP TASK')

  def v2_playbook_on_handler_task_start(self, task):
    self._task_start(task, prefix='RUNNING HANDLER')

  def v2_playbook_on_play_start(self, play):
    name = play.get_name().strip()
    if not name:
      msg = u"PLAY"
    else:
      msg = u"PLAY [%s]" % name

    self._play = play

    self._display.banner(msg)

  def v2_on_file_diff(self, result):
    if result._task.loop and 'results' in result._result:
      for res in result._result['results']:
        if 'diff' in res and res['diff'] and res.get('changed', False):
          diff = self._get_diff(res['diff'])
          if diff:
            if self._last_task_banner != result._task._uuid:
              self._print_task_banner(result._task)
            self._display.display(diff)
    elif ('diff' in result._result and result._result['diff']
          and result._result.get('changed', False)):
      diff = self._get_diff(result._result['diff'])
      if diff:
        if self._last_task_banner != result._task._uuid:
          self._print_task_banner(result._task)
        self._display.display(diff)

  def v2_runner_item_on_ok(self, result):
    delegated_vars = result._result.get('_ansible_delegated_vars', None)
    self._clean_results(result._result, result._task.action)

    if isinstance(result._task, TaskInclude):
      return
    elif result._result.get('changed', False):
      if self._last_task_banner != result._task._uuid:
        self._print_task_banner(result._task)

      msg = 'changed'
      color = C.COLOR_CHANGED
    else:
      if not self.display_ok_hosts:
        if not 'print_action' in result._task.tags:
          return

      if 'no_print' in self._task.tags:
        return

      if self._last_task_banner != result._task._uuid:
        self._print_task_banner(result._task)

      msg = 'ok'
      color = C.COLOR_OK

    if delegated_vars:
      msg += ": [%s -> %s]" % (result._host.get_name(),
                               delegated_vars['ansible_host'])
    else:
      msg += ": [%s]" % result._host.get_name()

    msg += " => (item=%s)" % (self._get_item_label(result._result),)

    if ((self._display.verbosity > 0 or '_ansible_verbose_always' in result._result)
            and '_ansible_verbose_override' not in result._result):
      msg += " => %s" % self._dump_results(result._result)
    self._display.display(msg, color=color)

  def v2_runner_item_on_failed(self, result):
    if self._last_task_banner != result._task._uuid:
      self._print_task_banner(result._task)

    delegated_vars = result._result.get('_ansible_delegated_vars', None)
    self._clean_results(result._result, result._task.action)
    self._handle_exception(result._result)

    msg = "failed: "
    if delegated_vars:
      msg += "[%s -> %s]" % (result._host.get_name(),
                             delegated_vars['ansible_host'])
    else:
      msg += "[%s]" % (result._host.get_name())

    self._handle_warnings(result._result)
    self._display.display(msg + " (item=%s) => %s" % (self._get_item_label(
        result._result), self._dump_results(result._result)), color=C.COLOR_ERROR)

  def v2_runner_item_on_skipped(self, result):
    if 'no_print' in self._task.tags:
      return

    if 'no_print_skipped' in self._task.tags:
      return

    if self.display_skipped_hosts or ('print_skipped_action' in result._task.tags):
      if self._last_task_banner != result._task._uuid:
        self._print_task_banner(result._task)

      self._clean_results(result._result, result._task.action)
      msg = "skipping: [%s] => (item=%s) " % (
          result._host.get_name(), self._get_item_label(result._result))
      if ((self._display.verbosity > 0 or '_ansible_verbose_always' in result._result)
              and '_ansible_verbose_override' not in result._result):
        msg += " => %s" % self._dump_results(result._result)
      self._display.display(msg, color=C.COLOR_SKIP)

  def v2_playbook_on_include(self, included_file):
    if 'no_print' in self._task.tags:
      return

    if 'no_print_skipped' in self._task.tags:
      return

    if self.display_ok_hosts:
      msg = 'included: %s for %s' % (included_file._filename, ", ".join([
                                     h.name for h in included_file._hosts]))
      if 'item' in included_file._args:
        msg += " => (item=%s)" % (self._get_item_label(included_file._args),)
      self._display.display(msg, color=C.COLOR_SKIP)

  def v2_playbook_on_stats(self, stats):
    self._display.banner("PLAY RECAP")

    hosts = sorted(stats.processed.keys())
    for h in hosts:
      t = stats.summarize(h)

      self._display.display(
          u"%s : %s %s %s %s %s %s %s" % (
              hostcolor(h, t),
              colorize(u'ok', t['ok'], C.COLOR_OK),
              colorize(u'changed', t['changed'], C.COLOR_CHANGED),
              colorize(u'unreachable', t['unreachable'], C.COLOR_UNREACHABLE),
              colorize(u'failed', t['failures'], C.COLOR_ERROR),
              colorize(u'skipped', t['skipped'], C.COLOR_SKIP),
              colorize(u'rescued', t['rescued'], C.COLOR_OK),
              colorize(u'ignored', t['ignored'], C.COLOR_WARN),
          ),
          screen_only=True
      )

      self._display.display(
          u"%s : %s %s %s %s %s %s %s" % (
              hostcolor(h, t, False),
              colorize(u'ok', t['ok'], None),
              colorize(u'changed', t['changed'], None),
              colorize(u'unreachable', t['unreachable'], None),
              colorize(u'failed', t['failures'], None),
              colorize(u'skipped', t['skipped'], None),
              colorize(u'rescued', t['rescued'], None),
              colorize(u'ignored', t['ignored'], None),
          ),
          log_only=True
      )

    self._display.display("", screen_only=True)

    # print custom stats if required
    if stats.custom and self.show_custom_stats:
      self._display.banner("CUSTOM STATS: ")
      # per host
      for k in sorted(stats.custom.keys()):
        if k == '_run':
          continue
        self._display.display('\t%s: %s' % (k, self._dump_results(
            stats.custom[k], indent=1).replace('\n', '')))

      # print per run custom stats
      if '_run' in stats.custom:
        self._display.display("", screen_only=True)
        self._display.display('\tRUN: %s' % self._dump_results(
            stats.custom['_run'], indent=1).replace('\n', ''))
      self._display.display("", screen_only=True)

  def v2_playbook_on_start(self, playbook):
    if self._display.verbosity > 1:
      from os.path import basename  # pylint: disable=import-outside-toplevel
      self._display.banner("PLAYBOOK: %s" % basename(playbook._file_name))

    # show CLI arguments
    if self._display.verbosity > 3:
      if context.CLIARGS.get('args'):
        self._display.display('Positional arguments: %s' % ' '.join(context.CLIARGS['args']),
                              color=C.COLOR_VERBOSE, screen_only=True)

      for argument in (a for a in context.CLIARGS if a != 'args'):
        val = context.CLIARGS[argument]
        if val:
          self._display.display('%s: %s' % (argument, val),
                                color=C.COLOR_VERBOSE, screen_only=True)

  def v2_runner_retry(self, result):
    task_name = result.task_name or result._task
    msg = ("FAILED - RETRYING: %s (%d retries left)." %
           (task_name, result._result['retries'] - result._result['attempts']))
    if ((self._display.verbosity > 2 or '_ansible_verbose_always' in result._result)
            and '_ansible_verbose_override' not in result._result):
      msg += "Result was: %s" % self._dump_results(result._result)
    self._display.display(msg, color=C.COLOR_DEBUG)

  def v2_playbook_on_notify(self, handler, host):
    if self._display.verbosity > 1:
      self._display.display("NOTIFIED HANDLER %s for %s" % (
          handler.get_name(), host), color=C.COLOR_VERBOSE, screen_only=True)

  def _dump_results(self, result, indent=None, sort_keys=True, keep_invocation=False):
    if result.get('_ansible_no_log', False):
      return json.dumps(dict(
          censored="The output has been hidden due to the fact "
          + "that 'no_log: true' was specified for this result"
      ))

    # All result keys stating with _ansible_ are internal,
    # so remove them from the result before we output anything.
    abridged_result = strip_internal_keys(module_response_deepcopy(result))

    # remove invocation unless specifically wanting it
    if not keep_invocation and self._display.verbosity < 3 and 'invocation' in result:
      del abridged_result['invocation']

    # remove diff information from screen output
    if self._display.verbosity < 3 and 'diff' in result:
      del abridged_result['diff']

    # remove exception from screen output
    if 'exception' in abridged_result:
      del abridged_result['exception']

    dumped = ''

    # put changed and skipped into a header line
    if 'changed' in abridged_result:
      dumped += 'changed=' + str(abridged_result['changed']).lower() + ' '
      del abridged_result['changed']

    if 'skipped' in abridged_result:
      dumped += 'skipped=' + str(abridged_result['skipped']).lower() + ' '
      del abridged_result['skipped']

    # if we already have stdout, we don't need stdout_lines
    if 'stdout' in abridged_result and 'stdout_lines' in abridged_result:
      abridged_result['stdout_lines'] = '<omitted>'

    # if we already have stderr, we don't need stderr_lines
    if 'stderr' in abridged_result and 'stderr_lines' in abridged_result:
      abridged_result['stderr_lines'] = '<omitted>'

    if abridged_result:
      dumped += '\n'
      dumped += to_text(yaml.dump(abridged_result, allow_unicode=True,
                                  width=1000, Dumper=AnsibleDumper, default_flow_style=False))

    # indent by a couple of spaces
    dumped = '\n  '.join(dumped.split('\n')).rstrip()
    return dumped

  def _serialize_diff(self, diff):
    return to_text(yaml.dump(
        diff,
        allow_unicode=True,
        width=1000,
        Dumper=AnsibleDumper,
        default_flow_style=False
    ))
