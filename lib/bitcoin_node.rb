require 'logger'

require 'bitcoin_node/version'
require 'bitcoin_node/protocol'

require 'bitcoin_node/client'


module BitcoinNode

  Logger = ::Logger.new(STDOUT)

end

BN = BitcoinNode
