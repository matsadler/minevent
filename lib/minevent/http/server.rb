require 'stringio'
require 'rubygems'
require 'http_tools'
require 'events'

class Minevent::HTTP::Server
  HTTP_VERSION = "HTTP_VERSION".freeze
  REMOTE_ADDR = "REMOTE_ADDR".freeze
  RACK_INPUT = "rack.input".freeze
  CONNECTION = "Connection".freeze
  KEEP_ALIVE = "Keep-Alive".freeze
  CLOSE = "close".freeze
  ONE_ONE = "1.1".freeze
  
  class AsyncResponse < Events::EventEmitter
    attr_accessor :status, :header, :id, :pipeline, :keep_alive
    def initialize(id, pipeline, keep_alive=true)
      @status = 200
      @header = {}
      @id = id
      @pipeline = pipeline
      @keep_alive = keep_alive
    end
    
    def <<(data)
      header_done
      pipeline.write(id, data)
    end
    
    def finish
      @response_finished = true
      header_done
      do_finish
    end
    
    def header_done
      unless @header_emitted
        header[CONNECTION] = keep_alive ? KEEP_ALIVE : CLOSE
        pipeline.write(id, HTTPTools::Builder.response(status, header))
      end
      @header_emitted = true
    end
    
    def request_finished
      @request_finished = true
      do_finish
    end
    
    private
    def do_finish
      if @response_finished && @request_finished
        pipeline.close(id)
        emit(:finish)
      end
    end
  end
  
  class Pipeline
    def initialize(io)
      @queues = Hash.new {|h, k| h[k] = []}
      @active = 0
      @queues[@active] = io
      @closed = Hash.new {|h, k| k < @active}
    end
    
    def write(stream_id, data)
      @queues[stream_id] << data
      self
    end
    
    def close(stream_id)
      @closed[stream_id] = true
      while @closed[@active]
        @closed.delete(@active)
        io = @queues.delete(@active)
        @active += 1
        @queues[@active].each {|data| io << data}
        @queues[@active] = io
      end
      self
    end
  end
  
  def initialize(app, options={})
    host = options[:host] || options[:Host] || "0.0.0.0"
    port = (options[:port] || options[:Port] || 9292).to_s
    @app = app
    error_stream = Minevent::IO.new(STDERR)
    def error_stream.flush
    end
    @instance_env = {"rack.errors" => error_stream}
    @server = Minevent::TCPServer.new(host, port)
    @server.listen(1024)
  end
  
  def self.run(app, options={})
    Minevent::Loop.run {new(app, options).listen}
  end
  
  def listen
    @server.on(:connection) do |socket|
      parser = HTTPTools::Parser.new
      pipeline = Pipeline.new(socket)
      request_count = -1
      input, response = nil
      
      parser.on(:header) do
        input = StringIO.new
        env = parser.env.merge!(
          HTTP_VERSION => parser.version,
          REMOTE_ADDR => socket.peeraddr.last,
          RACK_INPUT => input).merge!(@instance_env)
        keep_alive = keep_alive?(parser.version, parser.header[CONNECTION])
        response = AsyncResponse.new(request_count += 1, pipeline, keep_alive)
        response.on(:finish) do
          if keep_alive
            Minevent.defer do
              remainder = parser.rest.lstrip
              parser.reset << remainder
            end
          else
            socket.close
          end
        end
        @app.call(env, response)
      end
      parser.on(:stream) {|chunk| input << chunk}
      parser.on(:finish) {response.request_finished}
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
