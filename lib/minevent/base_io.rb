require "#{File.dirname(__FILE__)}/loop"
require 'rubygems'
require 'events'

module Minevent
  class BaseIO < Events::EventEmitter
    
    attr_reader :real # :nodoc:
    attr_accessor :record_separator
    
    def initialize(real)
      @real = real
      @write_queue = []
      @read_buffer = ""
      @record_separator = $/
      Minevent::Loop.add(self)
    end
    
    def self.from(real)
      instance = self.allocate
      Minevent::BaseIO.instance_method(:initialize).bind(instance).call(real)
      instance
    end
    
    def events
      [:data, :end, :error, :close]
    end
    
    def notify_readable # :nodoc:
      @read_buffer << real.read_nonblock(4096)
      if index = @read_buffer.rindex(record_separator)
        emit(:data, @read_buffer.slice!(0, index))
        @read_buffer.slice!(0, record_separator.length)
      end
    rescue EOFError
      emit(:data, @read_buffer.slice!(0..-1)) unless @read_buffer.empty?
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
    
    def notify_errored # :nodoc:
      emit(:error)
      close
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
      real.close
      emit(:close)
    end
    
  end
end