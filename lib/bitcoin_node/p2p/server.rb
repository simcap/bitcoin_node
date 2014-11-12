require 'socket'
require 'celluloid/io'

module BitcoinNode
  module P2p
    class Server
      include Celluloid::IO
      finalizer :shutdown

      def initialize(port = 3333)
        @server = TCPServer.new('localhost', port)
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
        BN::ServerLogger.info("Connection received from #{host}:#{port}")
        loop { handle_messages(socket) }
      end

      def handle_messages(socket)
        _, port, host = socket.peeraddr
        response = socket.readpartial(1024)
        network, command, length, checksum = response.unpack('a4A12Va4')
        payload = response[24...(24 + length)]
        BN::ServerLogger.info("Received #{command} (#{response.bytesize} bytes)")

        if command == 'version'
          payload = BN::Protocol::Version.new(addr_recv: ['127.0.0.1', port]) 
          message = BN::Protocol::Message.new(payload)
          BN::ServerLogger.info("Sending version")
          socket.write(message.raw)
        end

        if command == 'verack'
          verack = BN::Protocol::Message.verack
          BN::ServerLogger.info("Sending verack")
          socket.write(verack.raw)
        end

        if command == 'ping'
          ping_nonce = BN::Protocol::Ping.parse(payload).nonce.value
          pong = BN::Protocol::Message.pong(ping_nonce)
          BN::ServerLogger.info("Sending pong")
          socket.write(pong.raw)
        end
      end

    end
  end
end
