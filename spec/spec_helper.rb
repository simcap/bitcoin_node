require File.expand_path('../lib/bitcoin_node.rb', __dir__)

require 'socket'
require 'thread'

require 'celluloid/io'

class LocalServer
  include Celluloid::IO
  finalizer :shutdown

  attr_reader :last_message

  def initialize(port = 3333)
    @server = TCPServer.new('localhost', port)
    async.run
  end

  def run
    loop { async.read_message @server.accept }
  end

  def shutdown
    @server.close if @server
  end

  private

  def read_message(socket)
    _, port, host = socket.peeraddr
    puts "thread #{Thread.current}"
    puts "*** Received connection from #{host}:#{port}"
    @last_message = socket.recv(4096)
    @last_message.tap {|m| puts "*** message is #{m}"}
  end

end

module LocalClient

  def self.send_message(message, port = 3333)
    Thread.new do
      c = TCPSocket.new('localhost', port)
      c.send(message, 0)
      c.close
    end
  end

end
