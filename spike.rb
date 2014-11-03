# encoding: ascii-8bit
require 'digest'

require 'bitcoin_node'

host = ARGV[0] || (raise 'missing host') 

message = BN::Message::Version.new(
  addr_recv: { host: host, port: 8333 },
  addr_from: { host: '127.0.0.1', port: 8333 },
  start_height: 127953,
  relay: true,
).raw

pkt = "".force_encoding(Encoding.find('ASCII-8BIT'))
pkt << "\xF9\xBE\xB4\xD9".force_encoding(Encoding.find('ASCII-8BIT')) \
    << "version".ljust(12, "\x00")[0...12].force_encoding(Encoding.find('ASCII-8BIT')) \
    << [message.bytesize].pack("V") \
    << Digest::SHA256.digest(Digest::SHA256.digest(message))[0...4]  \
    << message.force_encoding(Encoding.find('ASCII-8BIT'))

client = BN::Client.new(host)
client.send(pkt)
