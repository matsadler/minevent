libs = %W{io file tcp_socket tcp_server loop}
libs.each {|lib| require "#{File.dirname(__FILE__)}/minevent/#{lib}"}

module Minevent
  def self.puts(*args)
    (@stdout ||= Minevent::IO.from(STDOUT)).puts(*args)
  end
end