autoload :Minevent, File.dirname(__FILE__) + '/../minevent'
autoload :TCPSocket, 'socket'

class Minevent::TCPSocket < Minevent::BaseIO
  set_real_class TCPSocket
  CHUNK_SIZE = 1024 * 16
  
  def initialize(*args)
    super
    self.chunk_size = CHUNK_SIZE
    Minevent.defer {emit(:connect)}
  end
  
  def events
    super + [:connect]
  end
  
end