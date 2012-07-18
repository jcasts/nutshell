require 'rubygems'
require 'open4'
require 'highline'
require 'termios'

require 'fileutils'
require 'tmpdir'


module Nutshell

  VERSION = "1.0.1"

  ##
  # Temp directory used by various nutshell classes
  # for uploads, checkouts, etc...
  TMP_DIR = File.join Dir.tmpdir, "nutshell_#{$$}"
  FileUtils.mkdir_p TMP_DIR


  class TimeoutError < Exception; end
  class CmdError < Exception; end
  class ConnectionError < Exception; end

  DEFAULT_CONFIG = {
    :timeout => 300,
    :interactive => true,
    :tty_state_freq => 0.1
  }

  ##
  # Set the config.

  def self.config
    @config ||= DEFAULT_CONFIG.dup
  end


  ##
  # How long to wait with no data coming in before timing out.
  # Reads config[:timeout].

  def self.timeout
    config[:timeout]
  end


  ##
  # Defines if process should fail when user interaction is required.
  # Defaults to true. Reads config[:interactive].

  def self.interactive?
    config[:interactive]
  end


  ##
  # How often to check the state of the tty in seconds.
  # Used for detecting prompts.
  # Defaults to 0.1. Reads config[:tty_state_freq].

  def self.tty_state_freq
    config[:tty_state_freq]
  end


  require 'nutshell/shell'
  require 'nutshell/remote_shell'
end
