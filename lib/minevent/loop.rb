require 'set'

module Minevent
  module Loop
    class << self
      
      def add(connection)
        connections.push(connection)
      end
      alias << add
      
      def connections
        @connections ||= []
      end
      
      def remove(connection)
        garbage.add(connection)
      end
      
      def run(timeout=0.25)
        yield if block_given?
        while connections.find(&:active?)
          reals = connections.map(&:real)
          readable, writeable, errored = if connections.find(&:pending_write?)
            select(reals, reals, reals, timeout)
          else
            select(reals, nil, reals, timeout)
          end
          readable.each {|r| wrapper(r).notify_readable} if readable
          writeable.each {|w| wrapper(w).notify_writeable} if writeable
          errored.each {|e| wrapper(e).notify_errored} if errored
          collect_garbage
        end
      end
      
      private
      def wrapper(connection)
        (@real_to_wrap_cache ||= Hash.new do |hash, key|
          hash[key] = connections.find {|connect| connect.real == key}
        end)[connection]
      end
      
      def garbage
        @garbage ||= Set.new
      end
      
      def collect_garbage
        garbage.each do |connection|
          @real_to_wrap_cache.delete(connection.real) if @real_to_wrap_cache
          connections.delete(connection)
        end.clear
      end
      
    end
  end
end