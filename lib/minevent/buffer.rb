autoload :Minevent, File.dirname(__FILE__) + '/../minevent'

class Minevent::Buffer
  include Enumerable
  
  attr_reader :string, :record_separator
  
  def initialize(string="", record_separator=$/)
    @string = string
    @record_separator = record_separator
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
    while index = string.index(record_separator)
      collection.push(string.slice!(0, index))
      string.slice!(0, record_separator.length)
    end
    collection
  end
  alias to_a entries
  
  def end
    i = record_separator.length
    unless string.empty? || string.slice(-i, i) == record_separator
      string.concat(record_separator)
    end
    nil
  end
end