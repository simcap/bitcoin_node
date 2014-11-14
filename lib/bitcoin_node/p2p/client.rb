require 'socket'

module BitcoinNode
  module P2p
    class Client
      def self.connect(host, port = 8333, probe = LoggingProbe.new("client-#{host}"))
        new(host, port, probe)
      end

      attr_accessor :handshaked, :version

      def initialize(host, port = 8333, probe = LoggingProbe.new("client-#{host}"))
        @host, @buffer, @probe = host, String.new, probe
        @socket = TCPSocket.new(host, port)
        @handshaked = false
        @version = BN::Protocol::VERSION
        @probe << { connected: host }
      end

      alias_method :handshaked?, :handshaked

      def send(message)
        raise ArgumentError unless BN::Protocol::Message === message

        @probe << { sending: message.command }
        @socket.write(message.raw)

        loop {
          @buffer << @socket.readpartial(1024)
          handler = CommandHandler.new(self, @buffer, @probe)
          if handler.valid_message?
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
        def initialize(client, buffer, probe)
          @client, @buffer, @probe = client, buffer, probe
        end

        def parse
          @probe << { receiving: @command }

          callback = Parser.new(@command, @payload).parse

          @buffer.clear
          callback.call(@client)
        end

        def valid_message?
          @payload, @command = BN::Protocol::Message.validate(@buffer)
        rescue BN::P::IncompleteMessageError
          false
        rescue BN::P::InvalidChecksumError => e  
          BN::Logger.info(e.message)
          false
        end
      end

      class Parser
        def initialize(command, payload)
          @command, @payload = command, payload
        end

        def parse
          callback = Proc.new {}

          if @command == 'version'
            received = BN::Protocol::Version.parse(@payload)
            remote_protocol_version = received.protocol_version.value
            callback = lambda do |client|
              client.version = [remote_protocol_version, client.version].min
              client.send(BN::Protocol::Messages.verack)
            end
          end

          if @command == 'verack'
            BN::Logger.info('Version handshake finished')
            callback = lambda { |client| client.handshaked = true }
          end

          if @command == 'addr'
            BN::Logger.info('Parsing addresses')
            BN::Protocol::Addr.parse(@payload)
          end

          if @command == 'inv'
            BN::Logger.info('Parsing inv')
            p BN::Protocol::Inv.parse(@payload)
          end

          callback
        end

      end

    end
  end
end
