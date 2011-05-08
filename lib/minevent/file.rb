autoload :Minevent, File.dirname(__FILE__) + '/../minevent'

class Minevent::File < Minevent::BaseIO
  set_real_class File
  
  class << self
    alias open new
  end
  
end
