require 'spec_helper'

describe 'Version handshake' do

  let(:port) { 3333 } 

  it 'peers exchanges version properly' do
    server = BN::P2p::Server.new
    client = BN::P2p::Client.connect('localhost', port)

    payload = BN::Protocol::Version.new(
      addr_recv: { host: '127.0.0.1', port: port }
    )

    message = BN::Protocol::Message.new(payload)
    client.send(message)
    client.send(BN::Protocol::Message.ping)
  end

end
