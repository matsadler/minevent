autoload :Minevent, File.dirname(__FILE__) + '/../../minevent'
require 'stringio'
require 'rubygems'
require 'http_tools'

class Minevent::HTTP::Server
  RACK_INPUT = "rack.input".freeze
  CONNECTION = "Connection".freeze
  KEEP_ALIVE = "Keep-Alive".freeze
  CLOSE = "close".freeze
  ONE_ONE = "1.1".freeze
  
  def initialize(app, options={})
    host = options[:host] || options[:Host] || "0.0.0.0"
    port = (options[:port] || options[:Port] || 9292).to_s
    @app = app
    error_stream = Minevent::IO.from(STDERR)
    def error_stream.flush
    end
    @instance_env = {"SERVER_NAME" => host, "SERVER_PORT" => port,
      "rack.errors" => error_stream}
    @server = Minevent::TCPServer.new(host, port)
  end
  
  def self.run(app, options={})
    Minevent::Loop.run {new(app, options).listen}
  end
  
  def listen
    @server.on(:connection) do |socket|
      parser = HTTPTools::Parser.new
      env, input = nil
      
      parser.on(:header) do
        input = StringIO.new
        env = parser.env.merge!(RACK_INPUT => input).merge!(@instance_env)
      end
      parser.on(:stream) {|chunk| input << chunk}
      parser.on(:finish) do |remainder|
        input.rewind
        status, header, body = @app.call(env)
        keep_alive = keep_alive?(parser.version, parser.header[CONNECTION])
        header[CONNECTION] = keep_alive ? KEEP_ALIVE : CLOSE
        socket << HTTPTools::Builder.response(status, header)
        body.each {|chunk| socket << chunk}
        if keep_alive
          Minevent.defer do
            parser.reset
            parser << remainder.lstrip if remainder
          end
        else
          socket.close
        end
      end
      parser.on(:error) {socket.close}
      
      socket.on(:data) {|data| parser << data}
    end
    self
  end
  
  private
  def keep_alive?(http_version, connection)
    http_version == ONE_ONE && connection != CLOSE || connection == KEEP_ALIVE
  end
  
end