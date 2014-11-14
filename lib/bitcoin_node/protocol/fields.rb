# coding: ascii-8bit
require 'digest'

module BitcoinNode
  module Protocol

    AddressField = Struct.new(:host, :port) do
      def pack
        sockaddr = Socket.pack_sockaddr_in(port, host)
        p, h = sockaddr[2...4], sockaddr[4...8]
        [[1].pack('Q'), "\x00" * 10, "\xFF\xFF", h, p].join
      end

      def self.parse(address)
        ip, port, remain = address.unpack("x8x12a4na*")
        [new(ip.unpack("C*").join('.'), port), remain]
      end
    end

    TimedAddressField = Struct.new(:time, :service, :host, :port) do
      def pack
      end

      def alive?
        (Time.now.tv_sec - 10800) <= time
      end

      def self.parse(address)
        time, service, ip, port, remain = address.unpack('VQx12a4na*')
        [new(time, service, ip.unpack("C*").join('.'), port), remain]
      end
    end

    class AddressesListField
      def self.parse(count, payload)
        Array.new(count) do
          addr, payload = TimedAddressField.parse(payload)
          addr
        end
      end
    end

    SingleValueField = Struct.new(:value) do
      def to_s
        "#<#{self.class.to_s.split('::').last} value=#{value.inspect}>"
      end

      def inspect
        to_s
      end
    end

    class VariableIntegerField < SingleValueField
      def pack
        if value < 0xfd; [value].pack("C")
        elsif value <= 0xffff; [0xfd, value].pack("Cv")
        elsif value <= 0xffffffff; [0xfe, value].pack("CV")
        elsif value <= 0xffffffffffffffff; [0xff, value].pack("CQ")
        else raise "Cannot pack integer #{value}"
        end
      end

      def self.parse(raw)
        case raw.unpack("C")[0]
        when 0xfd; raw.unpack("xva*")
        when 0xfe; raw.unpack("xVa*")
        when 0xff; raw.unpack("xQa*")
        else; raw.unpack("Ca*")
        end
      end
    end

    InventoryVectorField = Struct.new(:type, :object_hash) do

      TYPES = { ERROR: 0, MSG_TX: 1, MSG_BLOCK: 2, MSG_FILTERED_BLOCK: 3 }

      def pack
        [TYPES.fetch(type), object_hash].pack('Va32') 
      end

      def self.parse(raw)
        type_int, object_hash, remain = raw.unpack('Va32a*')
        [new(TYPES.invert.fetch(type_int), object_hash), remain]
      end
    end

    class Integer32Field < SingleValueField
      def pack
        [value].pack('V')  
      end

      def self.parse(raw)
        i, remain = raw.unpack('Va*')
        [new(i), remain]
      end
    end

    class StringField < SingleValueField
      def pack
        "#{VariableIntegerField.new(value.bytesize).pack}#{value}"
      end

      def self.parse(raw)
        size, payload = VariableIntegerField.parse(raw)
        if size > 0
          v, payload = payload.unpack("a#{size}a*")
          [StringField.new(v), payload]
        else 
          [nil, payload]
        end
      end
    end

    class Integer64Field < SingleValueField
      def pack
        [value].pack('Q')  
      end

      def self.parse(raw)
        i, remain = raw.unpack('Qa*')
        [new(i), remain]
      end
    end

    class BooleanField < SingleValueField
      def pack
        (value == true) ? [0xFF].pack("C") : [0x00].pack("C")
      end

      def self.parse(raw)
        b, remain = raw.unpack('C')
        [BooleanField.new(b == 0 ? false : true), remain]
      end
    end
  end
end
