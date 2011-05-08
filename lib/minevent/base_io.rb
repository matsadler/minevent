autoload :Minevent, File.dirname(__FILE__) + '/../minevent'
require 'stringio'
require 'rubygems'
require 'events'

class Minevent::BaseIO < Events::EventEmitter
  attr_reader :real # :nodoc:
  attr_accessor :chunk_size, :buffer
  
  def initialize(*args)
    real_class = self.class.real_class
    @real = args.first.is_a?(real_class) ? args.first : real_class.new(*args)
    @write_queue = []
    self.chunk_size = 1024 * 4
    Minevent::Loop.add(self)
  end
  
  class << self
    attr_accessor :real_class
    alias set_real_class real_class=
    alias from new
  end
  
  def record_separator
    buffer.record_separator if buffer
  end
  
  def record_separator=(value)
    self.buffer = Minevent::Buffer.new(buffer ? buffer.string : "", value)
  end
  
  def events
    [:data, :end, :error, :close]
  end
  
  def notify_readable # :nodoc:
    if buffer
      buffer << real.read_nonblock(chunk_size)
      buffer.each {|data| emit(:data, data)}
    else
      emit(:data, real.read_nonblock(chunk_size))
    end
  rescue EOFError
    buffer.end {|data| emit(:data, data)} if buffer
    emit(:end)
    close
  end
  
  def notify_writeable # :nodoc:
    if data = @write_queue.shift
      written = real.write_nonblock(data)
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
    real.close unless real.closed?
    emit(:close)
  end
  
end