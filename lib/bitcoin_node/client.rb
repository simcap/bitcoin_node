require 'socket'

module BitcoinNode
  class Client

    def self.connect(host)
      new(host)
    end

    def initialize(host)
      @host = host
      @socket = TCPSocket.new(host, 8333)
      BN::Logger.info("Connected to #{host}")
    end

    def send(message)
      BN::Logger.info("Sending #{message.bytesize} bytes")
      @socket.write(message)
      response = @socket.recv(1024)
      ResponseHandler.new(self, response).parse
    end

    def close
      @socket.close
      BN::Logger.info("Closing connection to #{@host}")
    end

    class ResponseHandler

      def initialize(client, response)
        @client = client
        @response = response  
      end

      def parse
        network, command, length, checksum = @response.unpack('a4A12Va4')
        payload = @response[24...(24 + length)]
        BN::Logger.info("Received #{@response.bytesize} bytes - Payload '#{command}' of #{payload.bytesize} bytes")
        if command == 'version'
          p BN::Protocol::Version.parse(payload)
          verack = BN::Protocol::Message.new(BN::Protocol::Verack.new)
          @client.send(verack.raw)
        end

        if command == 'verack'
          @client.close
        end
      end


    end
      
  end
end
