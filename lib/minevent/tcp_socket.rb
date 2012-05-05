require 'socket'

class Minevent::TCPSocket < Minevent::Socket
  set_io_class Socket
  EVENTS = (superclass::EVENTS + [:connect]).freeze
  
  def_delegators :@io, :peeraddr
  
  def initialize(host, port=nil)
    addrinfo = Addrinfo.tcp(host, port)
    super(addrinfo.pfamily, addrinfo.socktype)
    connect(addrinfo)
  end
  
end
