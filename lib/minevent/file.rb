autoload :Minevent, File.dirname(__FILE__) + '/../minevent'

class Minevent::File < Minevent::BaseIO
  
  def initialize(fd, mode_string='r')
    super(File.new(fd, mode_string))
  end
  
  class << self
    alias open new
  end
  
end
