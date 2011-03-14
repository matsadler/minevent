autoload :Minevent, File.dirname(__FILE__) + '/../../minevent'

class Minevent::HTTP::Response
  attr_reader :status, :message
  attr_accessor :headers, :body
  
  def initialize(status, message, headers={}, body=nil)
    @status, @message, @headers, @body = status, message, headers, body
  end
  
  def inspect
    "#<Response #{status} #{message}: #{body.to_s.length} bytes>"
  end
  
  def to_s
    body.to_s
  end
end
