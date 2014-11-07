module BitcoinNode
  module Protocol
    class Ping < Payload
      field :nonce, Integer64Field, default: lambda { rand(0xffffffffffffffff) }

      def self.parse(payload)
        nonce, _ = payload.unpack('Q')
        new(nonce: nonce)
      end
    end

    class Pong < Payload
      field :nonce, Integer64Field
    end

  end
end


