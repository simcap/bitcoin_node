require 'socket'
require 'celluloid/io'

module BitcoinNode
  class Server
    include Celluloid::IO
    finalizer :shutdown

    attr_reader :last_message

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
      BN::ServerLogger.info("Received #{response.bytesize} bytes - Payload '#{command}' of #{payload.bytesize} bytes")

      if command == 'version'
        payload = BN::Protocol::Version.new(
          addr_recv: { host: '127.0.0.1', port: port },
          addr_from: { host: '127.0.0.1', port: 8333 },
          start_height: 127953,
          relay: true,
        )

        version = BN::Protocol::Message.new(payload)
        socket.write(version.raw)
      end

      if command == 'verack'
        verack = BN::Protocol::Message.new(BN::Protocol::Verack.new)
        socket.write(verack.raw)
      end
    end

  end
end
