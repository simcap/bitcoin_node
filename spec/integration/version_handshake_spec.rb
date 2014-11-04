require 'spec_helper'

describe 'Version handshake' do

  let(:port) { 3333 } 

  it 'peers exchanges version properly' do
    server = BN::Server.new
    client = BN::Client.connect('localhost', port)

    payload = BN::Protocol::Version.new(
      addr_recv: { host: '127.0.0.1', port: port },
      addr_from: { host: '127.0.0.1', port: 8333 },
      start_height: 127953,
      relay: true,
    )

    message = BN::Protocol::Message.new(payload)
    client.send(message.raw)

  end

end
