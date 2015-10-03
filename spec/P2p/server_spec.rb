require 'spec_helper'

describe 'Server' do

  let(:addr) { '127.0.0.1' }
  let(:port) { random_port }

  it 'returns socket' do
    server = BN::P2p::Server.new(port)
    thread = Thread.new { server.accept }
    socket = within_io_actor { Celluloid::IO::TCPSocket.open(addr, port) }
    expect(socket).to be_a(Celluloid::IO::TCPSocket)
  end

end
