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
          handler = CommandHandler.new(self, @buffer, @probe)
          if handler.extract_payload
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

      class CommandHandler

        HEADER_SIZE = 24 

        def initialize(client, buffer, probe)
          @client, @buffer, @probe = client, buffer, probe
        end

        def parse
          @probe << { receiving: @command }

          message = Parser.new(@command, @payload).parse

          @buffer.clear
          @client.send(message) if message
        end

        def extract_payload
          @payload, @command = BN::Protocol::Message.extract_raw_payload(@buffer)
          true
        rescue BN::Protocol::IncompleteMessageError, BN::Protocol::InvalidChecksumError
          false
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
