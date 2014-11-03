require 'socket'

module BitcoinNode
  class Client

    def self.connect(host)
      new(host)
    end

    def initialize(host)
      @socket = TCPSocket.new(host, 8333)
      BN::Logger.info("Connected to #{host}")
    end

    def send(message)
      BN::Logger.info("Sending #{message.bytesize} bytes")
      @socket.write(message)
      response = @socket.recv(1024)
      BN::Logger.info("Received\n#{response}")
      ResponseHandler.new(response).parse
      @socket.close
    end

    class ResponseHandler

      def initialize(response)
        @response = response  
      end

      def parse
        network, command, length, checksum = @response.unpack('a4A12Va4')
        payload = @response[24...(24 + length)]
        p command
        if command == 'version'
          p BN::Protocol::Version.parse(payload)
        end

      end


    end
      
  end
end
