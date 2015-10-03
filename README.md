# BitcoinNode

Study of Bitcoin protocol by implementing a simple node in the p2p bitcoin network.

Using as much as Ruby stdlib as possible. Main foreign dependency is `Celluloid::IO`

## Installation

Add to your Gemfile `gem 'bitcoin_node'` or locally run

    $ gem install bitcoin_node

Test

    $ bundle exec rspec

## Usage

### Create messages

```ruby
require 'bitcoin_node'

ping = BitcoinNode::Protocol::Messages.ping
# => #<BitcoinNode::Protocol::Message:0x007feb24e1fa20 @payload=#<Ping {:nonce=>#<struct Integer64Field 12031756400052209357>}>, @command="ping">

ping.raw
# => "\xF9\xBE\xB4\xD9ping\x00\x00\x00\x00\x00\x00\x00\x00\b\x00\x00\x00\xAB\x0F\x0FZ\x95\xDC{\xA1\xB1i\x11]"

version = BN::Protocol::Messages.version
```

### Single client

```ruby
require 'bitcoin_node'

host = '144.76.217.165'

client = BN::P2P::Client.connect(host)

client.send(BN::Protocol::Messages.version)
client.send(BN::Protocol::Messages.ping)
client.send(BN::Protocol::Messages.getaddr)
```
