require 'socket'
require "#{File.dirname(__FILE__)}/base_io"

module Minevent
  class TCPSocket < Minevent::BaseIO
    
    RECORD_SEPARATOR = "\r\n"
    CHUNK_SIZE = 1024 * 16
    
    def initialize(host, port)
      super(::TCPSocket.new(host, port))
      self.record_separator = RECORD_SEPARATOR
      self.chunk_size = CHUNK_SIZE
    end
    
    def self.from(real)
      instance = super
      instance.record_separator = RECORD_SEPARATOR
      instance.chunk_size = CHUNK_SIZE
      instance
    end
    
    def events
      super + [:connect]
    end
    
  end
end