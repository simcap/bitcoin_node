# coding: ascii-8bit

require 'logger'

require 'bitcoin_node/version'

require 'bitcoin_node/protocol'
require 'bitcoin_node/p2p'


module BitcoinNode

  NETWORKS = { main: "\xF9\xBE\xB4\xD9".freeze, testnet: "\xFA\xBF\xB5\xDA".freeze }

  def self.network
    NETWORKS[:main]
  end

  Logger = ::Logger.new(STDOUT)
  Logger.progname = 'NODE'

end

BN = BitcoinNode
BN::P = BN::Protocol
