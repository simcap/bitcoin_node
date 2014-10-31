# encoding: ascii-8bit
require 'socket'

module BitcoinNode
  module Message

    class Payload
      include Virtus.model
    end

    class AddressField
      include Virtus.model

      values do
        attribute :port, Integer
        attribute :host
      end

      def pack
        sockaddr = Socket.pack_sockaddr_in(port, host)
        p, h = sockaddr[2...4], sockaddr[4...8]
        [[1].pack('Q'), "\x00" * 10, "\xFF\xFF", h, p].join
      end

      def self.unpack(address)
        ip, port = address.unpack("x8x12a4n")
        new(host: ip.unpack("C*").join('.'), port: port)
      end
      
    end


  end
end

require 'bitcoin_node/message/version'
