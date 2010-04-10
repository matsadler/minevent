require 'socket'
require "#{File.dirname(__FILE__)}/base_io"

module Minevent
  class TCPSocket < Minevent::BaseIO
    
    RECORD_SEPARATOR = "\r\n"
    
    def initialize(host, port)
      super(::TCPSocket.new(host, port))
      self.record_separator = RECORD_SEPARATOR
    end
    
    def self.from(real)
      (instance = super).record_separator = RECORD_SEPARATOR
      instance
    end
    
    def events
      super + [:connect]
    end
    
  end
end