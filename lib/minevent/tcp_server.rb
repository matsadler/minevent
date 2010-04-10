require 'socket'
require "#{File.dirname(__FILE__)}/base_io"

module Minevent
  class TCPServer < Minevent::BaseIO
    
    RECORD_SEPARATOR = "\r\n"
    
    def initialize(host, port)
      super(::TCPServer.new(host, port))
      self.record_separator = RECORD_SEPARATOR
    end
    
    def self.from(real)
      (instance = super).record_separator = RECORD_SEPARATOR
      instance
    end
    
    def notify_readable # :nodoc:
      connection = Minevent::TCPSocket.from(real.accept_nonblock)
      emit(:connection, connection)
      connection.emit(:connect)
    end
    
    def events
      super + [:connection]
    end
    
    undef write
    undef puts
    
  end
end