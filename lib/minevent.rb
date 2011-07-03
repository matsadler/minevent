module Minevent
  require_base = File.dirname(__FILE__) + '/minevent/'
  autoload :IO, require_base + 'io'
  autoload :Loop, require_base + 'loop'
  autoload :TCPServer, require_base + 'tcp_server'
  autoload :TCPSocket, require_base + 'tcp_socket'
  HTTP = Module.new
  HTTP.autoload :Client, require_base + 'http/client'
  HTTP.autoload :Rack, require_base + 'http/rack'
  HTTP.autoload :Response, require_base + 'http/response'
  HTTP.autoload :Server, require_base + 'http/server'
  
  def print; end; def printf; end; def putc; end; def puts; end # for docs
  methods = [:print, :printf, :putc, :puts]
  stdout = Minevent::IO.new(STDOUT)
  methods.each do |method|
    define_method(method) do |*args|
      stdout.send(method, *args)
    end
  end
  module_function *methods
  
  module_function
  def defer(*args, &block)
    Minevent::Loop.defer(*args, &block)
  end
  
end
