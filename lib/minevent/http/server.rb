autoload :Minevent, File.dirname(__FILE__) + '/../../minevent'
require 'stringio'
require 'rubygems'
require 'http_tools'

class Minevent::HTTP::Server
  
  REQUEST_METHOD = "REQUEST_METHOD".freeze
  SCRIPT_NAME = "SCRIPT_NAME".freeze
  PATH_INFO = "PATH_INFO".freeze
  QUERY_STRING = "QUERY_STRING".freeze
  REQUEST_URI = "REQUEST_URI".freeze
  FRAGMENT = "FRAGMENT".freeze
  SERVER_NAME = "SERVER_NAME".freeze
  SERVER_PORT = "SERVER_PORT".freeze
  RACK_VERSION = "rack.version".freeze
  RACK_URL_SCHEME = "rack.url_scheme".freeze
  RACK_INPUT = "rack.input".freeze
  RACK_ERRORS = "rack.errors".freeze
  RACK_MULTITHREAD = "rack.multithread".freeze
  RACK_MULTIPROCESS = "rack.multiprocess".freeze
  RACK_RUN_ONCE = "rack.run_once".freeze
  
  PROTOTYPE_ENV = {
    REQUEST_METHOD => nil,
    SCRIPT_NAME => "".freeze,
    PATH_INFO => "/".freeze,
    QUERY_STRING => "".freeze,
    SERVER_NAME => "".freeze,
    SERVER_PORT => "".freeze,
    RACK_VERSION => [1, 1].freeze,
    RACK_URL_SCHEME => "http".freeze,
    RACK_INPUT => nil,
    RACK_ERRORS => nil,
    RACK_MULTITHREAD => false,
    RACK_MULTIPROCESS => false,
    RACK_RUN_ONCE => false}.freeze
  
  GET = "GET".freeze
  HTTP_ = "HTTP_".freeze
  LOWERCASE = "a-z-".freeze
  UPPERCASE = "A-Z_".freeze
  NO_BODY = {"GET" => true, "HEAD" => true}
  
  def initialize(app, options={})
    host, port = options[:Host] || "0.0.0.0", options[:Port] || 8080
    error_stream = Minevent::IO.from(STDERR)
    def error_stream.flush
    end
    @server = Minevent::TCPServer.new(host, port)
    @server.on(:connection) do |socket|
      env = PROTOTYPE_ENV.dup
      env[SERVER_NAME] = host
      env[SERVER_PORT] = port.to_s
      env[RACK_INPUT] = StringIO.new
      env[RACK_ERRORS] = error_stream
      
      parser = HTTPTools::Parser.new
      parser.on(:method) do |method|
        parser.force_no_body = NO_BODY[method.upcase]
        env[REQUEST_METHOD] = method
      end
      parser.on(:path) do |path, query|
        env.merge!(PATH_INFO => path, QUERY_STRING => query)
      end
      parser.on(:uri) {|uri| env[REQUEST_URI] = uri}
      parser.on(:fragment) {|fragment| env[FRAGMENT] = fragment}
      parser.on(:headers) {|headers| merge_in_rack_format(env, headers)}
      parser.on(:stream) {|chunk| env[RACK_INPUT] << chunk}
      parser.on(:finished) do |remainder|
        env[RACK_INPUT].rewind
        status, headers, body = app.call(env)
        socket << HTTPTools::Builder.response(status, headers)
        body.each {|chunk| socket << chunk}
        socket.close
      end
      
      socket.on(:data) do |data|
        parser << data
      end
    end
  end
  
  def self.run(app, options={})
    new(app, options)
    Minevent::Loop.run
  end
  
  private
  def merge_in_rack_format(env, headers)
    headers.each {|k, val| env[HTTP_ + k.tr(LOWERCASE, UPPERCASE)] = val}; env
  end
  
end