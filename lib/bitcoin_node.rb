# coding: ascii-8bit

require 'logger'

require 'bitcoin_node/version'
require 'bitcoin_node/protocol'

require 'bitcoin_node/client'
require 'bitcoin_node/server'


module BitcoinNode

  NETWORKS = { main: "\xF9\xBE\xB4\xD9".freeze, testnet: "\xFA\xBF\xB5\xDA".freeze }

  def self.network
    NETWORKS[:main]
  end

  Logger = ::Logger.new(STDOUT)

  ClientLogger = ::Logger.new(STDOUT)
  ClientLogger.progname = 'CLIENT'

  ServerLogger = ::Logger.new(STDOUT)
  ServerLogger.progname = 'SERVER'

end

BN = BitcoinNode
