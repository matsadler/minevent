autoload :Minevent, File.dirname(__FILE__) + '/../minevent'

module Minevent::Loop
  class << self
    
    def add(connection)
      connections.push(connection)
      self
    end
    alias << add
    
    def defer(*args, &block)
      deferred.push(args << block)
      nil
    end
    
    def remove(connection)
      defer do
        @real_to_wrap_cache.delete(connection.real) if @real_to_wrap_cache
        connections.delete(connection)
      end
    end
    
    def run(timeout=0.25)
      yield if block_given?
      while connections.find {|c| c.active?}
        reals = connections.map {|c| c.real}
        readable, writeable = if connections.find {|c| c.pending_write?}
          select(reals, reals, nil, timeout)
        else
          select(reals, nil, nil, timeout)
        end
        readable.each {|r| wrapper(r).notify_readable} if readable
        writeable.each {|w| wrapper(w).notify_writeable} if writeable
        deferred.reject! {|d| d.pop.call(*d); true}
      end
    end
    
    private
    def connections
      @connections ||= []
    end
    
    def deferred
      @deferred ||= []
    end
    
    def wrapper(connection)
      (@real_to_wrap_cache ||= Hash.new do |hash, key|
        hash[key] = connections.find {|connect| connect.real == key}
      end)[connection]
    end
    
  end
end