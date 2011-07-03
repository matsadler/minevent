module Minevent
  module HTTP
    class Rack
      
      def initialize(app)
        @app = app
      end
      
      def self.run(app, options={})
        adaptor = new(app)
        Minevent::HTTP::Server.run(adaptor, options)
      end
      
      def call(env, response)
        input = StringIO.new
        env["rack.input"].on(:data) {|chunk| input << chunk}
        env["rack.input"].on(:end) do
          input.rewind
          env["rack.input"] = input
          status, header, body = @app.call(env)
          
          response.status = status
          response.header.merge!(header)
          body.each do |chunk|
            response << chunk
          end
          body.close if body.respond_to?(:close)
          response.finish
        end
      end
      
    end
  end
end
