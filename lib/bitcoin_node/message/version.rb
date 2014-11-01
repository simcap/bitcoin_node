module BitcoinNode
  module Message
    class Version < Payload

      field :protocol_version, Integer32Field, default: 7001
      field :services, Integer64Field, default: 1
      field :timestamp, Integer64Field
      field :addr_recv, AddressField
      field :addr_from, AddressField
      field :nonce, Integer64Field, default: rand(0xffffffffffffffff)
      field :user_agent, StringField, default: "/bitcoin_node:#{BitcoinNode::VERSION}/"
      field :start_height, Integer32Field
      field :relay, BooleanField

      def self.from_raw(payload)
        protocol_version, services, timestamp, to, from, nonce, payload = payload.unpack("VQQa26a26Qa*")
        to, from = AddressField.parse(to), AddressField.parse(from)
        user_agent, payload = StringField.parse(payload)
        last_block, payload = Integer32Field.parse(payload)
        relay = parse_relay(protocol_version, payload)

        new(
          protocol_version: protocol_version,
          services: services,
          timestamp: timestamp,
          addr_recv: to,
          addr_from: from, 
          nonce: nonce,
          user_agent: user_agent,
          start_height: last_block,
          relay: relay,
        )
      end

      private

      def self.parse_relay(version, payload)
        ( version >= 70001 and payload ) ? BooleanField.parse(payload) : true
      end

    end
  end
end 
