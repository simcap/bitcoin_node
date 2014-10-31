# encoding: ascii-8bit
$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'bitcoin_node'

host = ARGV[0] || (abort 'Missing host') 

payload = BN::Protocol::Version.new(
  addr_recv: { host: host, port: 8333 },
  addr_from: { host: '127.0.0.1', port: 8333 },
  start_height: 127953,
  relay: true,
)

message = BN::Protocol::Message.new(payload)

client = BN::Client.connect(host)
client.send(message)
client.send(BN::Protocol::Message.ping)

