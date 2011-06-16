require 'socket'

class Minevent::TCPServer < Minevent::IO
  set_io_class TCPServer
  
  def notify_readable # :nodoc:
    connection = Minevent::TCPSocket.new(io.accept_nonblock)
    emit(:connection, connection)
  end
  
  def events
    super + [:connection]
  end
  
  undef write
  undef puts
  
end
