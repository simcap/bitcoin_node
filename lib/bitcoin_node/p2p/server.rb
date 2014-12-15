require 'socket'
require 'celluloid/io'

module BitcoinNode
  module P2p
    class Server
      include Celluloid::IO
      finalizer :shutdown

      def initialize(port = 3333,  probe = LoggingProbe.new('server'))
        @server = TCPServer.new('localhost', port)
        @probe  = probe
        @peers = Peers.new
        async.run
      end

      def run
        loop { async.accept_connection @server.accept }
      end

      def shutdown
        @server.close if @server
      end

      private

      def accept_connection(socket)
        _, port, host = socket.peeraddr
        @peers.update(host, :connect)
        @probe << { connection: "#{host}:#{port}" }

        loop { handle_messages(socket) }
      end

      def handle_messages(socket)
        _, port, host = socket.peeraddr
        response = socket.readpartial(1024)
        network, command, length, checksum = response.unpack('a4A12Va4')
        payload = response[24...(24 + length)]
        @probe << { receiving: command }

        if command == 'version'
          payload = BN::Protocol::Version.new(addr_recv: ['127.0.0.1', port]) 
          message = BN::Protocol::Message.new(payload)
          @probe << { sending: 'version' }
          @peers.update(host, :version)
          socket.write(message.raw)
        end

        if command == 'verack'
          if @peers.status(host) == :version
            verack = BN::Protocol::Messages.verack
            @probe << { sending: 'verack' }
            @peers.update(host, :verack)
            socket.write(verack.raw)
          else
            @probe << { ignoring: 'verack' }
          end
        end

        if command == 'ping'
          ping_nonce = BN::Protocol::Ping.parse(payload).nonce.value
          pong = BN::Protocol::Messages.pong(ping_nonce)
          @probe << { sending: 'pong' }
          socket.write(pong.raw)
        end
      end


      class Peers 
        def initialize
          @mutex = Mutex.new
          @peers = {}
        end

        def update(peer, status)
          @mutex.synchronize do
            @peers[peer] = status
          end
        end

        def status(peer)
          @mutex.synchronize do
            @peers[peer]
          end
        end

        def to_s
          @peers.to_s 
        end
      end
    end
  end
end
