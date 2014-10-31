# encoding: ascii-8bit

module BitcoinNode
  module Message
    class Version

      FIELDS = %i(protocol_version services timestamp addr_recv
                  addr_from nonce start_height relay).freeze

      attr_accessor *FIELDS

      def initialize(fields)
        fields.each do |k, v|
          self.send("#{k.to_s}=", v)
        end
      end

      def raw
        [
          [protocol_version, services, timestamp].pack('VQQ'), 
          pack_address(addr_recv),
          pack_address(addr_from),
          [nonce].pack('Q'),
          pack_var_string("/bitcoin_node:#{BitcoinNode::VERSION}/"),
          [start_height].pack('V'), 
          pack_boolean(true)
        ].join
      end

      def self.from_raw(version)
        protocol_version, services, timestamp, to, from, nonce, payload = version.unpack("VQQa26a26Qa*")
        to, from = unpack_address_field(to), unpack_address_field(from)
        last_block, _ = payload.unpack("Va*")


        new(
          protocol_version: protocol_version,
          services: services,
          timestamp: timestamp,
          addr_recv: to,
          addr_from: from, 
          nonce: nonce,
          start_height: last_block
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

      def self.unpack_address_field(address)
        ip, port = address.unpack("x8x12a4n")
        "#{ip.unpack("C*").join(".")}:#{port}"
      end

    end
  end
end 
