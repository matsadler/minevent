libs = %W{buffer loop}
libs.each {|lib| require "#{File.dirname(__FILE__)}/#{lib}"}
require 'rubygems'
require 'events'

module Minevent
  class BaseIO < Events::EventEmitter
    
    attr_reader :real # :nodoc:
    attr_accessor :chunk_size
    
    def initialize(real)
      @real = real
      @write_queue = []
      self.record_separator = $/
      self.chunk_size = 1024 * 4
      Minevent::Loop.add(self)
    end
    
    def self.from(real)
      instance = self.allocate
      Minevent::BaseIO.instance_method(:initialize).bind(instance).call(real)
      instance
    end
    
    def record_separator
      @read_buffer.record_separator
    end
    
    def record_separator=(value)
      current_buffer_string = @read_buffer ? @read_buffer.string : ""
      @read_buffer = Minevent::Buffer.new(current_buffer_string, value)
      value
    end
    
    def events
      [:data, :end, :error, :close]
    end
    
    def notify_readable # :nodoc:
      @read_buffer << real.read_nonblock(chunk_size)
      @read_buffer.each {|data| emit(:data, data)}
    rescue EOFError
      @read_buffer.end
      @read_buffer.each {|data| emit(:data, data)}
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
    
    def puts(*args)
      write(args.join(record_separator) + record_separator)
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
end