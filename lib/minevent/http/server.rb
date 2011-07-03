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
  
  class AsyncInput < Events::EventEmitter
    def <<(data)
      emit(:data, data)
    end
    
    def finish # :nodoc: internal
      emit(:end)
    end
  end
  
  class AsyncResponse < Events::EventEmitter
    attr_accessor :status, :header, :id, :pipeline
    def initialize(id, pipeline)
      @status = 200
      @header = {}
      @id = id
      @pipeline = pipeline
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
    
    def request_finish # :nodoc: internal
      @request_finished = true
      do_finish
    end
    
    private
    def header_done
      unless @header_emitted
        pipeline.write(id, HTTPTools::Builder.response(status, header))
      end
      @header_emitted = true
    end
    
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
      remote_addr = socket.peeraddr.last
      
      parser.on(:header) do
        input = AsyncInput.new
        env = parser.env.merge!(HTTP_VERSION => parser.version,
          REMOTE_ADDR => remote_addr, RACK_INPUT => input)
        keep_alive = keep_alive?(parser.version, parser.header[CONNECTION])
        response = AsyncResponse.new(request_count += 1, pipeline)
        response.header[CONNECTION] = keep_alive ? KEEP_ALIVE : CLOSE
        @app.call(env, response)
      end
      parser.on(:stream) {|chunk| input << chunk}
      parser.on(:finish) do
        input.finish
        if keep_alive?(parser.version, response.header[CONNECTION])
          Minevent.defer do
            remainder = parser.rest.lstrip
            parser.reset << remainder
          end
        else
          response.on(:finish) {socket.close}
        end
        response.request_finish
      end
      parser.on(:error) {socket.close}
      
      socket.on(:data) {|data| parser << data}
      socket.on(:error) {|e| socket.close}
    end
    self
  end
  
  private
  def keep_alive?(http_version, connection)
    http_version == ONE_ONE && connection != CLOSE || connection == KEEP_ALIVE
  end
  
end
