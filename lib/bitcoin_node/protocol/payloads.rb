module BitcoinNode
  module Protocol
    class Version < Payload

      field :protocol_version, Integer32Field, default: 70001
      field :services, Integer64Field, default: 1
      field :timestamp, Integer64Field, default: lambda { Time.now.tv_sec }
      field :addr_recv, AddressField
      field :addr_from, AddressField, default: ['127.0.0.1', '8333']
      field :nonce, Integer64Field, default: lambda { rand(0xffffffffffffffff) }
      field :user_agent, StringField, default: "/bitcoin_node:#{BitcoinNode::VERSION}/"
      field :start_height, Integer32Field, default: 0
      field :relay, BooleanField, default: true

      def self.parse(payload)
        protocol_version, services, timestamp, to, from, nonce, payload = payload.unpack("VQQa26a26Qa*")
        to, = AddressField.parse(to)
        from, = AddressField.parse(from)
        user_agent, payload = StringField.parse(payload)
        last_block, payload = Integer32Field.parse(payload)
        relay, _ = parse_relay(protocol_version, payload) if payload

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
        version >= 70001 ? BooleanField.parse(payload) : true
      end

    end

    class Addr < Payload
      field :count, VariableIntegerField
      field :addr_list, AddressesListField

      def self.parse(raw)
        count, payload = VariableIntegerField.parse(raw) 
        AddressesListField.parse(count, payload)
      end
    end

    class Inv < Payload
      field :count, VariableIntegerField
      field :inventory, InventoryVectorField

      def self.parse(raw)
        count, payload = VariableIntegerField.parse(raw)  
        Array.new(count) do
          inv, payload = InventoryVectorField.parse(payload)
          inv
        end
      end
    end

    class Verack < Payload; end

    class Getaddr < Payload; end

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


