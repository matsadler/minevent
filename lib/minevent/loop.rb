module Minevent::Loop
  @connections = []
  @deferred = []
  
  class << self
    attr_reader :connections, :deferred
    
    def <<(connection)
      connections.push(connection)
      self
    end
    
    def defer(*args, &block)
      deferred.push(args << block)
      nil
    end
    
    def remove(connection)
      connections.delete(connection)
    end
    
    def run(timeout=0.25)
      yield if block_given?
      while connections.any? {|c| c.active?}
        readable, writeable = if connections.any? {|c| c.pending_write?}
          select(connections, connections, nil, timeout)
        else
          select(connections, nil, nil, timeout)
        end
        readable.each {|r| r.notify_readable} if readable
        writeable.each {|w| w.notify_writeable} if writeable
        deferred.reject! {|d| d.pop.call(*d); true}
      end
    end
    
  end
end
