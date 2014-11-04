require 'logger'

require 'bitcoin_node/version'
require 'bitcoin_node/protocol'

require 'bitcoin_node/client'
require 'bitcoin_node/server'


module BitcoinNode

  Logger = ::Logger.new(STDOUT)

  ClientLogger = ::Logger.new(STDOUT)
  ClientLogger.progname = 'CLIENT'

  ServerLogger = ::Logger.new(STDOUT)
  ServerLogger.progname = 'SERVER'

end

BN = BitcoinNode
