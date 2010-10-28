require 'nutshell'
require 'test/unit'

require 'test/mocks/mock_object'
require 'test/mocks/mock_open4'


def mock_remote_shell host=nil
  host ||= "user@some_server.com"
  remote_shell = Nutshell::RemoteShell.new host

  remote_shell.extend MockOpen4
  remote_shell.extend MockObject

  use_remote_shell remote_shell

  remote_shell.connect
  remote_shell
end


def mock_remote_shell host=nil
  host ||= "user@some_server.com"
  remote_shell = Nutshell::RemoteShell.new host

  remote_shell.extend MockOpen4
  remote_shell.extend MockObject

  use_remote_shell remote_shell

  remote_shell.connect
  remote_shell
end


def assert_not_called *args
  assert !@remote_shell.method_called?(:call, :args => [*args]),
    "Command called by #{@remote_shell.host} but should't have:\n #{args[0]}"
end


def assert_server_call *args
  assert @remote_shell.method_called?(:call, :args => [*args]),
    "Command was not called by #{@remote_shell.host}:\n #{args[0]}"
end


def assert_bash_script name, cmds, check_value
  cmds = cmds.map{|cmd| "(#{cmd})" }
  cmds << "echo true"

  bash = <<-STR
#!/bin/bash
if [ "$1" == "--no-env" ]; then
#{cmds.flatten.join(" && ")}
else
#{@app.root_path}/env #{@app.root_path}/#{name} --no-env
fi
  STR

  assert_equal bash, check_value
end


def assert_ssh_call expected, ds=@remote_shell, options={}
  expected = ds.build_remote_cmd(expected, options).join(" ")

  error_msg = "No such command in remote_shell log [#{ds.host}]\n#{expected}"
  error_msg << "\n\n#{ds.cmd_log.select{|c| c =~ /^ssh/}.join("\n\n")}"

  assert ds.cmd_log.include?(expected), error_msg
end


def assert_rsync from, to, ds=@remote_shell, sudo=false
  received = ds.cmd_log.last

  rsync_path = if sudo
    path = ds.sudo_cmd('rsync', sudo).join(' ')
    "--rsync-path='#{ path }' "
  end

  rsync_cmd = "rsync -azrP #{rsync_path}-e \"ssh #{ds.ssh_flags.join(' ')}\""

  error_msg = "No such command in remote_shell log [#{ds.host}]\n#{rsync_cmd}"
  error_msg << "#{from.inspect} #{to.inspect}"
  error_msg << "\n\n#{ds.cmd_log.select{|c| c =~ /^rsync/}.join("\n\n")}"

  if Regexp === from
    found = ds.cmd_log.select do |cmd|

      cmd_from = cmd.split(" ")[-2]
      cmd_to   = cmd.split(" ").last

      cmd_from =~ from && cmd_to == to && cmd.index(rsync_cmd) == 0
    end

    assert !found.empty?, error_msg
  else
    expected = "#{rsync_cmd} #{from} #{to}"
    assert ds.cmd_log.include?(expected), error_msg
  end
end


def use_remote_shell remote_shell
  @remote_shell = remote_shell
end
