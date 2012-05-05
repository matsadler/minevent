require 'socket'

class Minevent::Socket < Minevent::IO
  set_io_class Socket
  EVENTS = (superclass::EVENTS + [:connect]).freeze
  CHUNK_SIZE = 1024 * 16
  
  def initialize_with_io(io, connected=false)
    super(io)
    @connected = connected
    self.chunk_size = CHUNK_SIZE
  end
  private :initialize_with_io
  
  def connect(sockaddr)
    @sockaddr = sockaddr
    check_connection
  end
  
  def notify_readable
    check_connection
    super
  end
  
  def notify_writeable
    check_connection
    super
  end
  
  def check_writeable?
    pending_write? || !@connected
  end
  
  private
  def check_connection
    return if @connected
    io.connect_nonblock(@sockaddr)
    @connected = true
    emit(:connect)
  rescue IO::WaitWritable
  rescue Errno::EISCONN
    @connected = true
    emit(:connect)
  rescue StandardError => e
    emit(:error, e)
  end
  
end
