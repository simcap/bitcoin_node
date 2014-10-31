require 'spec_helper'

describe 'Messages protocol' do

  it 'sends and parses version correctly' do
    now = Time.now.tv_sec

    version = BN::Message::Version.new(
      services: 1,
      timestamp: now,
      addr_recv: '127.0.0.0:8333',
      addr_from: '192.168.0.1:45555', 
      start_height: 127953,
      relay: true,
    )

    sent_version = BN::Message::Version.from_raw(version.raw)

    expect(sent_version.protocol_version).to eql(7001)
    expect(sent_version.services).to eql(version.services)
    expect(sent_version.timestamp).to eql(version.timestamp)
    expect(sent_version.addr_recv).to eql(version.addr_recv)
    expect(sent_version.addr_from).to eql(version.addr_from)
    expect(sent_version.nonce).to eql(version.nonce)
    expect(sent_version.user_agent).to eql("/bitcoin_node:#{BitcoinNode::VERSION}/")
    expect(sent_version.start_height).to eql(version.start_height)
    expect(sent_version.relay).to eql(version.relay)
  end

end
