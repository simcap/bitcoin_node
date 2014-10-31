# encoding: ascii-8bit

module BitcoinNode
  module Message
    class Version < Payload

      attribute :protocol_version, Integer, default: 7001
      attribute :services
      attribute :timestamp
      attribute :addr_recv
      attribute :addr_from
      attribute :nonce, Integer, default: rand(0xffffffffffffffff)
      attribute :user_agent, String, default: "/bitcoin_node:#{BitcoinNode::VERSION}/"
      attribute :start_height
      attribute :relay

      def raw
        [
          [protocol_version, services, timestamp].pack('VQQ'), 
          pack_address(addr_recv),
          pack_address(addr_from),
          [nonce].pack('Q'),
          pack_var_string(user_agent),
          [start_height].pack('V'), 
          pack_boolean(true)
        ].join
      end

      def self.from_raw(payload)
        protocol_version, services, timestamp, to, from, nonce, payload = payload.unpack("VQQa26a26Qa*")
        to, from = unpack_address_field(to), unpack_address_field(from)
        user_agent, payload = unpack_var_string(payload)
        last_block, payload = payload.unpack("Va*")
        relay, payload = unpack_relay_field(protocol_version, payload)

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

      def pack_boolean(b)
        (b == true) ? [0xFF].pack("C") : [0x00].pack("C")
      end

      def pack_var_int(i)
        if i < 0xfd; [ i].pack("C")
        elsif i <= 0xffff; [0xfd, i].pack("Cv")
        elsif i <= 0xffffffff; [0xfe, i].pack("CV")
        elsif i <= 0xffffffffffffffff; [0xff, i].pack("CQ")
        else raise "int(#{i}) too large!"
        end
      end

      def pack_var_string(payload)
        pack_var_int(payload.bytesize) + payload
      end

      def pack_address(address)
        h, p = address.split(':')
        sockaddr = Socket.pack_sockaddr_in(p.to_i, h)
        p, h = sockaddr[2...4], sockaddr[4...8]
        [[1].pack('Q'), "\x00" * 10, "\xFF\xFF", h, p].join
      end

      def self.unpack_relay_field(version, payload)
        ( version >= 70001 and payload ) ? unpack_boolean(payload) : [ true, nil ]
      end

      def self.unpack_boolean(payload)
        bdata, payload = payload.unpack("Ca*")
        [ (bdata == 0 ? false : true), payload ]
      end

      def self.unpack_address_field(address)
        ip, port = address.unpack("x8x12a4n")
        "#{ip.unpack("C*").join(".")}:#{port}"
      end

      def self.unpack_var_string(payload)
        size, payload = unpack_var_int(payload)
        size > 0 ? (string, payload = payload.unpack("a#{size}a*")) : [nil, payload]
      end

      def self.unpack_var_int(payload)
        case payload.unpack("C")[0] # TODO add test cases
        when 0xfd; payload.unpack("xva*")
        when 0xfe; payload.unpack("xVa*")
        when 0xff; payload.unpack("xQa*") # TODO add little-endian version of Q
        else; payload.unpack("Ca*")
        end
      end

    end
  end
end 
