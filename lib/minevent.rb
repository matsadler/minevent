module Minevent
  require_base = File.dirname(__FILE__) + '/minevent/'
  autoload :BaseIO, require_base + 'base_io'
  autoload :Buffer, require_base + 'buffer'
  autoload :File, require_base + 'file'
  autoload :IO, require_base + 'io'
  autoload :Loop, require_base + 'loop'
  autoload :TCPServer, require_base + 'tcp_server'
  autoload :TCPSocket, require_base + 'tcp_socket'
  
  def self.puts(*args)
    (@stdout ||= Minevent::IO.from(STDOUT)).puts(*args)
  end
end