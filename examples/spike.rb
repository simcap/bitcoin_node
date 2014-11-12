# encoding: ascii-8bit
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'bitcoin_node'

host = ARGV[0] || (abort 'Missing host') 

payload = BN::Protocol::Version.new(addr_recv: [host, 8333])

message = BN::Protocol::Message.new(payload)

client = BN::P2P::Client.connect(host)
client.send(message)
client.send(BN::Protocol::Messages.ping)
client.send(BN::Protocol::Messages.getaddr)

