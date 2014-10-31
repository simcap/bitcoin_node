require 'spec_helper'

describe 'Messages protocol' do

  it 'sends and parses version correctly' do
    now = Time.now.tv_sec
    nonce = rand(0xffffffffffffffff)

    version = BN::Message::Version.new(
      protocol_version: 7001,
      services: 1,
      timestamp: now,
      addr_recv: '127.0.0.0:8333',
      addr_from: '192.168.0.1:45555', 
      nonce: nonce,
      start_height: 127953,
      relay: true,
    )

    sent_version = BN::Message::Version.from_raw(version.raw)

    %i(protocol_version services timestamp addr_recv
        addr_from nonce).each do |field|
      expect(sent_version.send(field)).to eql(version.send(field))
    end
  end

end
