autoload :Minevent, File.dirname(__FILE__) + '/../minevent'
autoload :TCPServer, 'socket'

class Minevent::TCPServer < Minevent::BaseIO
  
  def initialize(host, port)
    self.class.from(TCPServer.new(host, port), self)
  end
  
  def self.from(real, instance=allocate)
    instance = super
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