require 'socket'

module BitcoinNode
  module P2p
    class Client

      def self.connect(host, port = 8333, probe = LoggingProbe.new('client'))
        new(host, port, probe)
      end

      def initialize(host, port = 8333, probe = LoggingProbe.new('client'))
        @host, @buffer, @probe = host, String.new, probe
        @socket = TCPSocket.new(host, port)
        @probe << { connected: host }
      end

      def send(message)
        raise ArgumentError unless BN::Protocol::Message === message

        @probe << { sending: message.command }
        @socket.write(message.raw)

        loop {
          @buffer << @socket.readpartial(64)
          if (handler = ConnectionHandler.new(self, @buffer, @probe)).parseable?
            handler.parse
            break
          end
        }
      rescue IOError => e
        BN::ClientLogger.error(e.message)
      end

      def close!
        @socket.close
        @probe << { closed: @host }
      end

      class ConnectionHandler

        HEADER_SIZE = 24 

        def initialize(client, buffer, probe = LoggingProbe.new('client'))
          @client, @buffer, @probe = client, buffer, probe
          @network, @command, @expected_length, @checksum = @buffer.unpack('a4A12Va4')
          @payload = @buffer[HEADER_SIZE...(HEADER_SIZE + @expected_length)]
        end

        def parseable?
          @payload.bytesize < @expected_length ? false : true
        end

        def parse
          @probe << { receiving: @command }

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
            BN::Protocol::Version.parse(@payload)
            return BN::Protocol::Message.verack
          end

          if @command == 'verack'
            BN::Logger.info('Version handshake finished')
            nil
          end

          if @command == 'addr'
            BN::Logger.info('Parsing addresses')
            BN::Protocol::Addr.parse(@payload)
            nil
          end

          if @command == 'inv'
            BN::Logger.info('Parsing inv')
            BN::Protocol::Inv.parse(@payload)
            nil
          end
        end

      end

    end
  end
end
