autoload :Minevent, File.dirname(__FILE__) + '/../minevent'
autoload :TCPServer, 'socket'

class Minevent::TCPServer < Minevent::BaseIO
  set_real_class TCPServer
  
  def notify_readable # :nodoc:
    connection = Minevent::TCPSocket.from(real.accept_nonblock)
    emit(:connection, connection)
  end
  
  def events
    super + [:connection]
  end
  
  undef write
  undef puts
  
end