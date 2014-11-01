# encoding: ascii-8bit
require 'socket'

module BitcoinNode
  module Message

    def self.pack_var_int(i)
      if i < 0xfd; [ i].pack("C")
      elsif i <= 0xffff; [0xfd, i].pack("Cv")
      elsif i <= 0xffffffff; [0xfe, i].pack("CV")
      elsif i <= 0xffffffffffffffff; [0xff, i].pack("CQ")
      else raise "int(#{i}) too large!"
      end
    end

    def self.unpack_var_int(payload)
      case payload.unpack("C")[0] # TODO add test cases
      when 0xfd; payload.unpack("xva*")
      when 0xfe; payload.unpack("xVa*")
      when 0xff; payload.unpack("xQa*") # TODO add little-endian version of Q
      else; payload.unpack("Ca*")
      end
    end

    class Payload
      include Virtus.model
    end

    class AddressField
      include Virtus.model

      values do
        attribute :port, Integer
        attribute :host
      end

      def pack
        sockaddr = Socket.pack_sockaddr_in(port, host)
        p, h = sockaddr[2...4], sockaddr[4...8]
        [[1].pack('Q'), "\x00" * 10, "\xFF\xFF", h, p].join
      end

      def self.parse(address)
        ip, port = address.unpack("x8x12a4n")
        new(host: ip.unpack("C*").join('.'), port: port)
      end
    end

    class Integer32Field
      include Virtus.model

      values do
        attribute :value, Integer
      end

      def pack
        [value].pack('V')  
      end

      def self.parse(raw)
        i, remain = raw.unpack('Va*')
        [new(value: i), remain]
      end
    end

    class StringField
      include Virtus.model

      values do
        attribute :value, Integer
      end

      def pack
        "#{Message.pack_var_int(value.bytesize)}#{value}"
      end

      def self.parse(raw)
        size, payload = Message.unpack_var_int(raw)
        if size > 0
          v, payload = payload.unpack("a#{size}a*")
          [StringField.new(value: v), payload]
        else 
          [nil, payload]
        end
      end

    end

    class Integer64Field
      include Virtus.model

      values do
        attribute :value, Integer
      end

      def pack
        [value].pack('Q')  
      end

      def self.parse(raw)
        i, remain = raw.unpack('Qa*')
        [new(value: i), remain]
      end
    end

    class BooleanField
      include Virtus.model

      values do
        attribute :value, Integer
      end

      def pack
        (value == true) ? [0xFF].pack("C") : [0x00].pack("C")
      end

      def self.parse(raw)
        b = raw.unpack('C')
        BooleanField.new(value: (b == 0 ? false : true))
      end

    end
  end
end

require 'bitcoin_node/message/version'
