require 'socket'

module BitcoinNode
  class Client

    def initialize(host)
      @socket = TCPSocket.new(host, 8333)
      BN::Logger.info("Connected to #{host}")
    end

    def send(message)
      BN::Logger.info("Sending #{message.bytesize} bytes")
      @socket.write(message)
      response = @socket.recv(1024)
      BN::Logger.info("Received\n#{response}")
      @socket.close
    end
      
  end
end
