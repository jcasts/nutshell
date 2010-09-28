require 'test/test_helper'

class TestRemoteShell < Test::Unit::TestCase

  def setup
    Nutshell::RemoteShell.class_eval{ include MockOpen4 }

    @host = "user@some_server.com"
    @remote_shell = mock_remote_shell @host
  end

  def teardown
    @remote_shell.disconnect
  end

  def test_connect
    login_cmd = Nutshell::RemoteShell::LOGIN_LOOP
    login_cmd = @remote_shell.send :quote_cmd, login_cmd
    login_cmd = @remote_shell.send :ssh_cmd, login_cmd, :sudo => false

    assert @remote_shell.method_called?(:popen4, :args => [login_cmd.join(" ")])
    assert @remote_shell.connected?
  end

  def test_disconnect
    @remote_shell.disconnect
    assert !@remote_shell.connected?
  end

  def test_call
    @remote_shell.call "echo 'line1'; echo 'line2'"
    assert_ssh_call "echo 'line1'; echo 'line2'"

    @remote_shell.sudo = "sudouser"
    @remote_shell.call "sudocall"
    assert_ssh_call "sudocall", @remote_shell, :sudo => "sudouser"
  end

  def test_call_with_stderr
    @remote_shell.set_mock_response 1, :err => 'this is an error'
    cmd = "echo 'this is an error'"
    @remote_shell.call cmd
    raise "Didn't raise CmdError on stderr"
  rescue Nutshell::CmdError => e
    ssh_cmd = @remote_shell.build_remote_cmd(cmd).join(" ")
    assert_equal "Execution failed with status 1: #{ssh_cmd}", e.message
  end

  def test_upload
    @remote_shell.upload "test/fixtures/nutshell_test", "nutshell_test"
    assert_rsync "test/fixtures/nutshell_test",
      "#{@remote_shell.host}:nutshell_test"

    @remote_shell.sudo = "blah"
    @remote_shell.upload "test/fixtures/nutshell_test", "nutshell_test"
    assert_rsync "test/fixtures/nutshell_test",
      "#{@remote_shell.host}:nutshell_test", @remote_shell, "blah"
  end

  def test_download
    @remote_shell.download "nutshell_test", "."
    assert_rsync "#{@remote_shell.host}:nutshell_test", "."

    @remote_shell.download "nutshell_test", ".", :sudo => "sudouser"
    assert_rsync "#{@remote_shell.host}:nutshell_test", ".",
      @remote_shell, "sudouser"
  end

  def test_make_file
    @remote_shell.make_file("some_dir/nutshell_test_file", "test data")
    tmp_file = "#{Nutshell::TMP_DIR}/nutshell_test_file"
    tmp_file = Regexp.escape tmp_file
    assert_rsync(/^#{tmp_file}_[0-9]+/,
      "#{@remote_shell.host}:some_dir/nutshell_test_file")
  end

  def test_os_name
    @remote_shell.os_name
    assert_ssh_call "uname -s"
  end

  def test_equality
    ds_equal = Nutshell::RemoteShell.new @host
    ds_diff1 = Nutshell::RemoteShell.new @host, :user => "blarg"
    ds_diff2 = Nutshell::RemoteShell.new "some_other_host"

    assert_equal ds_equal, @remote_shell
    assert_equal ds_diff1, @remote_shell
    assert ds_diff2 != @remote_shell
  end

  def test_file?
    @remote_shell.file? "some/file/path"
    assert_ssh_call "test -f some/file/path"
  end

  def test_symlink
    @remote_shell.symlink "target_file", "sym_name"
    assert_ssh_call "ln -sfT target_file sym_name"
  end
end

