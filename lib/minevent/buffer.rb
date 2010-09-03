autoload :Minevent, File.dirname(__FILE__) + '/../minevent'
require 'strscan'

class Minevent::Buffer
  include Enumerable
  
  attr_reader :string, :record_separator, :ended
  
  def initialize(string="", record_separator=$/)
    @scanner = StringScanner.new(string)
    if record_separator.is_a?(Regexp)
      @record_separator = record_separator
    else
      @record_separator = Regexp.new(record_separator)
    end
    @ended = false
  end
  
  def concat(data)
    @scanner << data
    self
  end
  alias << concat
  
  def each(&block)
    block ? entries.each(&block) : entries.each
  end
  
  def entries
    collection = []
    separator = ended ? Regexp.union(record_separator, /\Z/) : record_separator
    while !@scanner.eos? && (match = @scanner.scan_until(separator))
      collection.push(match)
    end
    @scanner.string.replace(@scanner.rest)
    @scanner.reset
    collection
  end
  alias to_a entries
  
  def end(&block)
    @ended = true
    each(&block) if block
    self
  end
  
end