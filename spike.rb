# encoding: ascii-8bit
require 'socket'
require 'digest'

host = ARGV[0] || (raise 'missing host') 


def self.pack_boolean(b)
  (b == true) ? [0xFF].pack("C") : [0x00].pack("C")
end

def pack_var_int(i)
  if i < 0xfd; [ i].pack("C")
  elsif i <= 0xffff; [0xfd, i].pack("Cv")
  elsif i <= 0xffffffff; [0xfe, i].pack("CV")
  elsif i <= 0xffffffffffffffff; [0xff, i].pack("CQ")
  else raise "int(#{i}) too large!"
  end
end

def pack_var_string(payload)
  pack_var_int(payload.bytesize) + payload
end

def pack_address(address)
  h, p = address.split(':')
  sockaddr = Socket.pack_sockaddr_in(p.to_i, h)
  p, h = sockaddr[2...4], sockaddr[4...8]
  [[1].pack('Q'), "\x00" * 10, "\xFF\xFF", h, p].join
end

head = [70001, 1, Time.now.tv_sec].pack('VQQ')
from = pack_address('127.0.0.1:8333')
to = pack_address("#{host}:8333")
nonce = [rand(0xffffffffffffffff)].pack('Q')
user_agent = pack_var_string("/bitcoin_node:0.0.1/")
last_block = [127953].pack('V')
relay = pack_boolean(true)

message = [head, from, to, nonce, user_agent, last_block, relay].join

pkt = "".force_encoding(Encoding.find('ASCII-8BIT'))
pkt << "\xF9\xBE\xB4\xD9".force_encoding(Encoding.find('ASCII-8BIT')) \
    << "version".ljust(12, "\x00")[0...12].force_encoding(Encoding.find('ASCII-8BIT')) \
    << [message.bytesize].pack("V") \
    << Digest::SHA256.digest(Digest::SHA256.digest(message))[0...4]  \
    << message.force_encoding(Encoding.find('ASCII-8BIT'))

TCPSocket.open host, 8333 do |s|
  puts s.send(pkt, 0)
  p ['sent version pkt', pkt]
  puts s.recv(5)
end

__END__
bitcoin: {
project: :bitcoin,
magic_head: "\xF9\xBE\xB4\xD9",
address_version: "00",
p2sh_version: "05",
privkey_version: "80",
default_port: 8333,
protocol_version: 70001,
coinbase_maturity: 100,
reward_base: 50 * COIN,
reward_halving: 210_000,
retarget_interval: 2016,
retarget_time: 1209600, # 2 weeks
target_spacing: 600, # block interval
max_money: 21_000_000 * COIN,
min_tx_fee: 10_000,
min_relay_tx_fee: 10_000,
free_tx_bytes: 1_000,
dust: CENT,
per_dust_fee: false,
dns_seeds: [
"seed.bitcoin.sipa.be",
"dnsseed.bluematt.me",
"dnsseed.bitcoin.dashjr.org",
"bitseed.xf2.org",
],
genesis_hash: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f",
proof_of_work_limit: 0x1d00ffff,
alert_pubkeys: ["04fc9702847840aaf195de8442ebecedf5b095cdbb9bc716bda9110971b28a49e0ead8564ff0db22209e0374782c093bb899692d524e9d6a6956e7c5ecbcd68284"],
known_nodes: [
'relay.eligius.st',
'mining.bitcoin.cz',
'blockchain.info',
'blockexplorer.com',
],


