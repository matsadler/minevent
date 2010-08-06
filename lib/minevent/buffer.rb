autoload :Minevent, File.dirname(__FILE__) + '/../minevent'

class Minevent::Buffer
  include Enumerable
  
  attr_reader :string, :record_separator, :ended
  
  def initialize(string="", record_separator=$/)
    @string = string
    @record_separator = record_separator
    @ended = false
  end
  
  def concat(data)
    string.concat(data)
  end
  alias << concat
  
  def each(&block)
    block ? entries.each(&block) : entries.each
  end
  
  def entries
    collection = []
    while string.length > 0 &&
      (index = string.index(record_separator) || (string.index(/\Z/) if ended))
      collection.push(string.slice!(0, index + record_separator.length))
    end
    collection
  end
  alias to_a entries
  
  def end
    @ended = true
  end
  
end