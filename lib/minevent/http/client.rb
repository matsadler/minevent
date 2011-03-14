autoload :Minevent, File.dirname(__FILE__) + '/../../minevent'
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
    parser.allow_html_without_headers = true
    parser.force_no_body = !response_has_body
    
    response = nil
    parser.on(:status) {|s, m| response = Minevent::HTTP::Response.new(s, m)}
    parser.on(:headers) {|headers| response.headers = headers}
    parser.on(:body) {|body| response.body = body}
    parser.on(:finished) do |remainder|
      socket.close unless keepalive?
      block.call(response)
    end
    
    socket << HTTPTools::Builder.request(method, @host, path, request_headers)
    request_body.on(:data) {|data| socket << data} if request_body
    
    socket.on(:data) {|data| parser << data}
    socket.on(:end) {parser.finish}
    socket.on(:close) {@socket = nil}
    
    self
  end
end
