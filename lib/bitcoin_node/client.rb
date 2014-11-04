require 'socket'

module BitcoinNode
  class Client

    def self.connect(host, port = 8333)
      new(host, port)
    end

    def initialize(host, port = 8333)
      @host = host
      @socket = TCPSocket.new(host, port)
      BN::ClientLogger.info("Connected to #{host}")
    end

    def send(message)
      BN::ClientLogger.info("Sending #{message.bytesize} bytes")
      @socket.write(message)
      response = @socket.recv(1024)
      ResponseHandler.new(self, response).parse
    end

    def close
      @socket.close
      BN::ClientLogger.info("Closing connection to #{@host}")
    end

    class ResponseHandler

      def initialize(client, response)
        @client = client
        @response = response  
      end

      def parse
        network, command, length, checksum = @response.unpack('a4A12Va4')
        payload = @response[24...(24 + length)]
        BN::ClientLogger.info("Received #{@response.bytesize} bytes - Payload '#{command}' of #{payload.bytesize} bytes")
        if command == 'version'
          p BN::Protocol::Version.parse(payload)
          verack = BN::Protocol::Message.new(BN::Protocol::Verack.new)
          @client.send(verack.raw)
        end

        if command == 'verack'
          BN::ClientLogger.info('Version handshake finished')
          @client.close
        end
      end


    end
      
  end
end
