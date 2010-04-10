require "#{File.dirname(__FILE__)}/base_io"

module Minevent
  class IO < Minevent::BaseIO
    
    def initialize(fd, mode_string='r')
      super(::IO.new(fd, mode_string))
    end
    
  end
end