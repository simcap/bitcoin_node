require 'spec_helper'

describe 'Version handshake' do

  let(:port) { 3333 } 

  xit 'peers exchanges version properly' do
    server = BN::P2p::Server.new
    client = BN::P2p::Client.connect('localhost', port)
  end

end
