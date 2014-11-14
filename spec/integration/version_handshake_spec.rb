require 'spec_helper'

describe 'Version handshake' do

  let(:port) { 3333 } 

  it 'peers exchanges version properly' do
    server = BN::P2p::Server.new

    client_probe = BN::P2p::StoreProbe.new
    client = BN::P2p::Client.connect('localhost', port, client_probe)
    client.version = 60001

    payload = BN::Protocol::Version.new(addr_recv: ['127.0.0.1', port])
    message = BN::Protocol::Message.new(payload)

    expect(client.handshaked?).to eql false
    
    client.send(message)

    expect(client.handshaked?).to eql true
    expect(client.version).to eql 60001

    client.send(BN::Protocol::Messages.ping)

    expect(client_probe.store[:sending]).to eql %w(version verack ping)
    expect(client_probe.store[:receiving]).to eql %w(version verack pong)
  end

end
