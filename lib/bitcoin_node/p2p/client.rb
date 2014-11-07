require 'socket'

module BitcoinNode
  module P2p
    class Client

      def self.connect(host, port = 8333)
        new(host, port)
      end

      def initialize(host, port = 8333)
        @host = host
        @buffer = String.new
        @socket = TCPSocket.new(host, port)
        BN::ClientLogger.info("Connected to #{host}")
      end

      def send(message)
        if BN::Protocol::Message === message
          type, content = message.command, message.raw
        else
          type, content = 'raw', message
        end
        BN::ClientLogger.info("Sending #{type} (#{message.bytesize} bytes)")
        @socket.write(content)
        loop {
          @buffer << @socket.readpartial(64)
          if (handler = ConnectionHandler.new(self, @buffer)).parseable?
            handler.parse
            break
          end
        }
      rescue IOError => e
        BN::ClientLogger.error(e.message)
      end

      def close!
        @socket.close
        BN::ClientLogger.info("Closing connection to #{@host}")
      end

      class ConnectionHandler

        HEADER_SIZE = 24 

        def initialize(client, buffer)
          @client = client
          @buffer = buffer  
          @network, @command, @expected_length, @checksum = @buffer.unpack('a4A12Va4')
          @payload = @buffer[HEADER_SIZE...(HEADER_SIZE + @expected_length)]
        end

        def parseable?
          @payload.bytesize < @expected_length ? false : true
        end

        def parse
          BN::ClientLogger.info("Received #{@command} (#{@buffer.bytesize} bytes)")
          message = Parser.new(@command, @payload).parse
          @buffer.clear
          @client.send(message) if message
        end
      end

      class Parser

        def initialize(command, payload)
          @command, @payload = command, payload
        end

        def parse
          if @command == 'version'
            puts BN::Protocol::Version.parse(@payload)
            return BN::Protocol::Message.verack
          end

          if @command == 'verack'
            BN::ClientLogger.info('Version handshake finished')
            nil
          end
        end

      end

    end
  end
end
