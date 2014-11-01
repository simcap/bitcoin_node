require 'spec_helper'

describe 'Messages protocol' do

  it 'sends and parses version correctly' do
    now = Time.now.tv_sec

    version = BN::Message::Version.new(
      timestamp: { value: now},
      addr_recv: { host: '127.0.0.0', port: 8333 },
      addr_from: { host: '192.168.0.1', port: 45555 },
      start_height: { value: 127953 },
      relay: { value: true},
    )

    parsed_version = BN::Message::Version.from_raw(version.raw)

    expect(parsed_version.protocol_version.value).to eql 7001
    expect(parsed_version.services.value).to eql 1
    expect(parsed_version.timestamp).to eql(version.timestamp)
    expect(parsed_version.addr_recv).to eql(version.addr_recv)
    expect(parsed_version.addr_from).to eql(version.addr_from)
    expect(parsed_version.nonce).to eql(version.nonce)
    expect(parsed_version.user_agent.value).to eql("/bitcoin_node:#{BitcoinNode::VERSION}/")
    expect(parsed_version.start_height).to eql(version.start_height)
    expect(parsed_version.relay).to eql(version.relay)
  end

end
