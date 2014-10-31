# encoding: ascii-8bit
require 'digest'

#require File.expand_path('lib/bitcoin_node.rb', __dir__)
require 'bitcoin_node'

host = ARGV[0] || (raise 'missing host') 

message = [rand(0xffffffff)].pack("Q")

pkt = "".force_encoding(Encoding.find('ASCII-8BIT'))
pkt << "\xF9\xBE\xB4\xD9".force_encoding(Encoding.find('ASCII-8BIT')) \
    << "ping".ljust(12, "\x00")[0...12].force_encoding(Encoding.find('ASCII-8BIT')) \
    << [message.bytesize].pack("V") \
    << Digest::SHA256.digest(Digest::SHA256.digest(message))[0...4]  \
    << message.force_encoding(Encoding.find('ASCII-8BIT'))

client = BN::Client.new(host)
client.send(pkt)
