autoload :Minevent, File.dirname(__FILE__) + '/../../minevent'
require 'rubygems'
require 'http_tools'

class Minevent::HTTP::Server
  
  def initialize(host, port=8080)
    @server = Minevent::TCPServer.new(host, port)
    @server.on(:connection) do |socket|
      env = {}
      parser = HTTPTools::Parser.new
      parser.on(:method) do |method|
        parser.force_no_body = (method == "GET")
        env["REQUEST_METHOD"] = method
      end
      parser.on(:path) do |path, query|
        env["PATH_INFO"], env["QUERY_STRING"] = path, query
      end
      parser.on(:uri) {|uri| env["REQUEST_URI"] = uri}
      parser.on(:fragment) {|fragment| env["FRAGMENT"] = fragment}
      parser.on(:headers) {|headers| env.merge!(rack_format(headers))}
      parser.on(:finished) do |remainder|
        status, headers, body = @app.call(env)
        socket << HTTPTools::Builder.response(status, headers)
        body.each {|chunk| socket << chunk}
        socket.close
      end
      
      socket.on(:data) do |data|
        parser << data
      end
    end
  end
  
  def run(app)
    @app = app
  end
  
  private
  def rack_format(hash)
    Hash[hash.map {|key, value| ["HTTP_" + key.upcase.tr("-", "_"), value]}]
  end
  
  
end