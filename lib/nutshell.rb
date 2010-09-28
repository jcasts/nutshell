require 'rubygems'
require 'open4'
require 'highline'

require 'fileutils'
require 'tmpdir'


module Nutshell

  VERSION = "1.0.0"

  ##
  # Temp directory used by various nutshell classes
  # for uploads, checkouts, etc...
  TMP_DIR = File.join Dir.tmpdir, "nutshell_#{$$}"
  FileUtils.mkdir_p TMP_DIR


  class TimeoutError < Exception; end
  class CmdError < Exception; end
  class ConnectionError < Exception; end


  def self.config
    @config ||= {}
  end


  def self.timeout
    config[:timeout]
  end


  def self.interactive?
    config[:interactive]
  end


  require 'nutshell/shell'
  require 'nutshell/remote_shell'
end
