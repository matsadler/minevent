require "#{File.dirname(__FILE__)}/base_io"

module Minevent
  class File < Minevent::BaseIO
    
    def initialize(fd, mode_string='r')
      super(::File.new(fd, mode_string))
    end
    
    class << self
      alias open new
    end
    
  end
end