autoload :Minevent, File.dirname(__FILE__) + '/../minevent'

module Minevent::HTTP
  require_base = File.dirname(__FILE__) + '/http/'
  autoload :Client, require_base + 'client'
  autoload :Response, require_base + 'response'
end