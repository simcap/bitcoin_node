# coding: ascii-8bit
require 'digest'

module BitcoinNode
  module Protocol

    class AddressField 

      attr_reader :port, :host

      def initialize(values)
        @port = values.fetch(:port)
        @host = values.fetch(:host)
      end

      def pack
        sockaddr = Socket.pack_sockaddr_in(@port, @host)
        p, h = sockaddr[2...4], sockaddr[4...8]
        [[1].pack('Q'), "\x00" * 10, "\xFF\xFF", h, p].join
      end

      def ==(other)
        other.instance_of?(self.class) &&
          port == other.port && host == other.host
      end
      alias_method :eql?, :==

      def to_s
        "#{host}:#{port}"
      end

      def self.parse(address)
        ip, port = address.unpack("x8x12a4n")
        new(host: ip.unpack("C*").join('.'), port: port)
      end
    end

    class SingleValueField < Struct.new(:value)
      def to_s
        "#<#{self.class.to_s.split('::').last} value=#{value.inspect}>"
      end

      def inspect
        to_s
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
        "#{Protocol.pack_var_int(value.bytesize)}#{value}"
      end

      def self.parse(raw)
        size, payload = Protocol.unpack_var_int(raw)
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
