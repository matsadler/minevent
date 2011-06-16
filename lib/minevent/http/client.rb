require 'rubygems'
require 'http_tools'

class Minevent::HTTP::Client
  attr_accessor :keepalive
  alias keepalive? keepalive
  
  def initialize(host, port=80)
    @host = host
    @port = port
  end
  
  def socket
    @socket ||= Minevent::TCPSocket.new(@host, @port)
  end
  
  def get(path, headers={}, &block)
    request(:get, path, nil, headers, &block)
  end
  
  private
  def request(method, path, request_body=nil, request_headers={}, response_has_body=true, &block)
    parser = HTTPTools::Parser.new
    parser.allow_html_without_header = true
    parser.force_no_body = !response_has_body
    response = nil
    
    parser.on(:header) do
      code, message, header = parser.status_code, parser.message, parser.header
      response = Minevent::HTTP::Response.new(code, message, header)
    end
    parser.on(:stream) {|chunk| response.body << chunk}
    parser.on(:finish) do |remainder|
      socket.close unless keepalive?
      block.call(response)
    end
    
    socket << HTTPTools::Builder.request(method, @host, path, request_headers)
    socket << request_body if request_body
    
    socket.on(:data) {|data| parser << data}
    socket.on(:end) {parser.finish}
    socket.on(:close) {@socket = nil}
    
    self
  end
end
