autoload :Minevent, File.dirname(__FILE__) + '/../minevent'

class Minevent::IO < Minevent::BaseIO
  set_real_class IO
end