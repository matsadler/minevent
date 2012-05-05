module Minevent
  HTTP = Module.new
  
  require_base = File.expand_path("../minevent", __FILE__)
  libs = %W{io loop socket tcp_server tcp_socket http/client http/rack
    http/response http/server}
  libs.each do |lib|
    require [require_base, lib].join("/")
  end
  
  def print; end; def printf; end; def putc; end; def puts; end # for docs
  methods = [:print, :printf, :putc, :puts]
  stdout = Minevent::IO.for_io(STDOUT)
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
