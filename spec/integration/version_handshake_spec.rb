require 'spec_helper'

describe 'Version handshake' do

  let(:port) { 3333 } 

  it 'peers exchanges version properly' do
    server = BN::P2p::Server.new

    client_probe = BN::P2p::StoreProbe.new
    client = BN::P2p::Client.connect('localhost', port, client_probe)

    payload = BN::Protocol::Version.new(addr_recv: ['127.0.0.1', port])
    message = BN::Protocol::Message.new(payload)

    client.send(message)
    client.send(BN::Protocol::Messages.ping)

    expect(client_probe.store[:sending]).to eql %w(version verack ping)
    expect(client_probe.store[:receiving]).to eql %w(version verack pong)
  end

end
