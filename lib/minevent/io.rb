require 'stringio'
require 'rubygems'
require 'events'

class Minevent::IO < Events::EventEmitter
  attr_reader :io # :nodoc:
  alias to_io io # :nodoc:
  attr_accessor :chunk_size
  
  def initialize(*args)
    io_class = self.class.io_class
    @io = args.first.is_a?(io_class) ? args.first : io_class.new(*args)
    @write_queue = []
    self.chunk_size = 1024 * 4
    Minevent::Loop << self
  end
  
  class << self
    attr_accessor :io_class
    alias set_io_class io_class=
  end
  
  set_io_class IO
  
  def events
    [:data, :end, :error, :close]
  end
  
  def notify_readable # :nodoc:
    emit(:data, io.read_nonblock(chunk_size))
  rescue EOFError
    emit(:end)
    close
  end
  
  def notify_writeable # :nodoc:
    if data = @write_queue.shift
      written = io.write_nonblock(data)
      remainder = data.slice(written..-1)
      @write_queue.unshift(remainder) unless remainder.empty?
    end
    real_close if @closing && !pending_write?
  rescue Errno::EPIPE
    if @closing then real_close else raise end
  end
  
  def write(data)
    string = data.to_s
    @write_queue.push(string)
    string.length
  end
  
  def <<(data)
    write(data)
    self
  end
  
  def print; end; def printf; end; def putc; end; def puts; end # for docs
  [:print, :printf, :putc, :puts].each do |method|
    define_method(method) do |*args|
      string_io = StringIO.new
      string_io.send(method, *args)
      write(string_io.string)
      nil
    end
  end
  
  def pending_write? # :nodoc:
    @write_queue.any?
  end
  
  def listeners? # :nodoc:
    events.find {|event| listeners(event).any?}
  end
  
  def closed?
    @closed
  end
  
  def active? # :nodoc:
    !closed? && (pending_write? || listeners?)
  end
  
  def close
    return if closed?
    @closing = true
    real_close unless pending_write?
  end
  
  private
  def real_close
    @closed = true
    Minevent::Loop.remove(self)
    io.close unless io.closed?
    emit(:close)
  end
  
end
