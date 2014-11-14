# coding: ascii-8bit
require 'digest'

module BitcoinNode
  module Protocol

    class FieldStruct < Struct
      def to_s
        type = self.class.name ? self.class.name.split('::').last : '' 
        "#<struct #{type} #{values.join(', ')}>" 
      end
      alias_method :inspect, :to_s
    end

    AddressField = FieldStruct.new(:host, :port) do
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

    TimedAddressField = FieldStruct.new(:time, :service, :host, :port) do
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

    AddressesListField = FieldStruct.new(:count) do
      def self.parse(count, payload)
        Array.new(count) do
          addr, payload = TimedAddressField.parse(payload)
          addr
        end
      end
    end

    VariableIntegerField = FieldStruct.new(:value) do
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

    InventoryVectorField = FieldStruct.new(:type, :object_hash) do

      TYPES = { ERROR: 0, MSG_TX: 1, MSG_BLOCK: 2, MSG_FILTERED_BLOCK: 3 }

      def pack
        [TYPES.fetch(type), object_hash].pack('Va32') 
      end

      def self.parse(raw)
        type_int, object_hash, remain = raw.unpack('Va32a*')
        [new(TYPES.invert.fetch(type_int), object_hash), remain]
      end
    end

    Integer32Field  = FieldStruct.new(:value) do
      def pack
        [value].pack('V')  
      end

      def self.parse(raw)
        i, remain = raw.unpack('Va*')
        [new(i), remain]
      end
    end

    StringField = FieldStruct.new(:value) do
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

    Integer64Field = FieldStruct.new(:value) do
      def pack
        [value].pack('Q')  
      end

      def self.parse(raw)
        i, remain = raw.unpack('Qa*')
        [new(i), remain]
      end
    end

    BooleanField = FieldStruct.new(:value) do
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
