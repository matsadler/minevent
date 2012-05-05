require 'stringio'
require 'forwardable'
require 'rubygems'
require 'events'

class Minevent::IO < Events::EventEmitter
  EVENTS = [:data, :end, :error, :close].freeze
  
  extend Forwardable
  attr_reader :io # :nodoc:
  alias to_io io # :nodoc:
  attr_accessor :chunk_size
  
  def initialize(*args)
    initialize_with_io(self.class.io_class.new(*args))
  end
  
  def initialize_with_io(io)
    @io = io
    @write_queue = []
    self.chunk_size = 1024 * 4
    Minevent::Loop << self
  end
  private :initialize_with_io
  
  def self.for_io(*args)
    instance = allocate
    instance.instance_eval {initialize_with_io(*args)}
    instance
  end
  
  class << self
    attr_accessor :io_class
    alias set_io_class io_class=
  end
  
  set_io_class IO
  
  def notify_readable # :nodoc:
    begin
      data = io.read_nonblock(chunk_size)
    rescue EOFError
      emit(:end)
      close
    rescue StandardError => e
      emit(:error, e)
    end
    emit(:data, data) if data
  end
  
  def notify_writeable # :nodoc:
    if data = @write_queue.shift
      begin
        written = io.write_nonblock(data)
      rescue StandardError => e
        if @closing && e.is_a?(Errno::EPIPE) then return real_close end
        written = 0
        emit(:error, e)
      end
      remainder = data.slice(written..-1)
      @write_queue.unshift(remainder) unless remainder.empty?
    end
    real_close if @closing && !pending_write?
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
  alias check_writeable? pending_write?
  
  def listeners? # :nodoc:
    self.class::EVENTS.find {|event| listeners(event).any?}
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
