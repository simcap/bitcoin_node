# encoding: ascii-8bit
require 'socket'
require 'digest'

host = ARGV[0] || (raise 'missing host') 

message = [rand(0xffffffff)].pack("Q")

pkt = "".force_encoding(Encoding.find('ASCII-8BIT'))
pkt << "\xF9\xBE\xB4\xD9".force_encoding(Encoding.find('ASCII-8BIT')) \
    << "ping".ljust(12, "\x00")[0...12].force_encoding(Encoding.find('ASCII-8BIT')) \
    << [message.bytesize].pack("V") \
    << Digest::SHA256.digest(Digest::SHA256.digest(message))[0...4]  \
    << message.force_encoding(Encoding.find('ASCII-8BIT'))

s = TCPSocket.new host, 8333, '192.168.0.12', 55417 
puts s.write(pkt)
p ['sent ping pkt', pkt]
puts "got back:" + s.recv(1024)
s.close

message = BitcoinNode::Message::Version.new().to_payload

BitcoinNode::Message::Verack.to_packet

BitcoinNode::Message::Version.from_payload()

connection = BitcoinNode.connect(host)
connection.send(Packet.new(version))

