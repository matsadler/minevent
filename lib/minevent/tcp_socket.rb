autoload :Minevent, File.dirname(__FILE__) + '/../minevent'
autoload :TCPSocket, 'socket'

class Minevent::TCPSocket < Minevent::BaseIO
  
  RECORD_SEPARATOR = "\r\n"
  CHUNK_SIZE = 1024 * 16
  
  def initialize(host, port)
    self.class.from(TCPSocket.new(host, port), self)
    Minevent.defer {emit(:connect)}
  end
  
  def self.from(real, instance=allocate)
    instance = super
    instance.record_separator = RECORD_SEPARATOR
    instance.chunk_size = CHUNK_SIZE
    instance
  end
  
  def events
    super + [:connect]
  end
  
end