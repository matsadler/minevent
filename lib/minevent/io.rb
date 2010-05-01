autoload :Minevent, File.dirname(__FILE__) + '/../minevent'

class Minevent::IO < Minevent::BaseIO
  
  def initialize(fd, mode_string='r')
    super(IO.new(fd, mode_string))
  end
  
end