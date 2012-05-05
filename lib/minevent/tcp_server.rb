require 'socket'

class Minevent::TCPServer < Minevent::IO
  set_io_class TCPServer
  EVENTS = (superclass::EVENTS + [:connection]).freeze
  
  def_delegators :@io, :listen
  
  def notify_readable # :nodoc:
    connection = Minevent::TCPSocket.for_io(io.accept_nonblock, true)
    emit(:connection, connection)
  end
  
  undef write
  undef puts
  
end
