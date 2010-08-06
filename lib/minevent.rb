module Minevent
  require_base = File.dirname(__FILE__) + '/minevent/'
  autoload :BaseIO, require_base + 'base_io'
  autoload :Buffer, require_base + 'buffer'
  autoload :File, require_base + 'file'
  autoload :IO, require_base + 'io'
  autoload :Loop, require_base + 'loop'
  autoload :TCPServer, require_base + 'tcp_server'
  autoload :TCPSocket, require_base + 'tcp_socket'
  
  def print; end; def printf; end; def putc; end; def puts; end # for docs
  methods = [:print, :printf, :putc, :puts]
  methods.each do |method|
    define_method(method) do |*args|
      (@stdout ||= Minevent::IO.from(STDOUT)).send(method, *args)
    end
  end
  module_function *methods
  
  module_function
  def defer(*args, &block)
    Minevent::Loop.defer(*args, &block)
  end
  
end