module BitcoinNode
  module Protocol
    class Version < Payload
      field :protocol_version, Integer32Field, default: 70001
      field :services, Integer64Field, default: 1
      field :timestamp, Integer64Field, default: lambda { Time.now.tv_sec }
      field :addr_recv, AddressField, default: ['127.0.0.1', 3333]
      field :addr_from, AddressField, default: ['127.0.0.1', 8333]
      field :nonce, Integer64Field, default: lambda { rand(0xffffffffffffffff) }
      field :user_agent, StringField, default: "/bitcoin_node:#{BitcoinNode::VERSION}/"
      field :start_height, Integer32Field, default: 0
      field :relay, BooleanField, default: true

      def self.parse_relay(payload, fields_parsed)
        parsed_version = fields_parsed.fetch(:protocol_version).value
        parsed_version >= 70001 ? BooleanField.parse(payload) : true
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
    end

    class Pong < Payload
      field :nonce, Integer64Field
    end

  end
end


