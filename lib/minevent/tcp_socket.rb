require 'socket'

class Minevent::TCPSocket < Minevent::IO
  set_io_class TCPSocket
  EVENTS = (superclass::EVENTS + [:connect]).freeze
  CHUNK_SIZE = 1024 * 16
  
  def_delegators :@io, :peeraddr
  
  def initialize(*args)
    super
    self.chunk_size = CHUNK_SIZE
    Minevent.defer {emit(:connect)}
  end
  
end
