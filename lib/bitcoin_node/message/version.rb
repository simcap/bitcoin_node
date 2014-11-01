module BitcoinNode
  module Message
    class Version < Payload

      attribute :protocol_version, Integer32Field, default: Integer64Field.new(value: 7001)
      attribute :services, Integer64Field, default: Integer64Field.new(value: 1)
      attribute :timestamp, Integer64Field
      attribute :addr_recv, AddressField
      attribute :addr_from, AddressField
      attribute :nonce, Integer64Field, default: Integer64Field.new(value: rand(0xffffffffffffffff))
      attribute :user_agent, StringField, default: StringField.new(value: "/bitcoin_node:#{BitcoinNode::VERSION}/")
      attribute :start_height, Integer32Field
      attribute :relay, BooleanField

      def raw
        attributes.values.map(&:pack).join
      end

      def self.from_raw(payload)
        protocol_version, services, timestamp, to, from, nonce, payload = payload.unpack("VQQa26a26Qa*")
        to, from = AddressField.parse(to), AddressField.parse(from)
        user_agent, payload = StringField.parse(payload)
        last_block, payload = Integer32Field.parse(payload)
        relay = parse_relay(protocol_version, payload)

        new(
          protocol_version: { value: protocol_version},
          services: { value: services},
          timestamp: { value: timestamp},
          addr_recv: to,
          addr_from: from, 
          nonce: { value: nonce},
          user_agent: user_agent,
          start_height: last_block,
          relay: relay,
        )
      end

      private

      def self.parse_relay(version, payload)
        ( version >= 70001 and payload ) ? BooleanField.parse(payload) : BooleanField.new(value: true)
      end

      def self.unpack_var_string(payload)
        size, payload = BN::Message.unpack_var_int(payload)
        if size > 0
          [StringField.new(value: payload.unpack("a#{size}a*")), payload]
        else 
          [nil, payload]
        end
      end

    end
  end
end 
