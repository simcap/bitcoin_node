# encoding: ascii-8bit
require 'socket'

module BitcoinNode
  module Message

    class Payload

      class << self
        def field(name, type, options = {})
          define_method(name) do
            instance_fields[name]
          end

          define_method("#{name}=") do |value|
            if type === value
              instance_fields[name] = value
            else
              instance_fields[name] = type.new(value)
            end
          end

          fields << name
          defaults[name] = options[:default] if options[:default]
        end

        def defaults
          @defaults ||= {}
        end

        def fields
          @fields ||= []
        end
      end

      def initialize(attributes)
        attributes.each do |k,v|
          self.send("#{k}=", v) 
        end
        missings = self.class.fields - attributes.keys
        missings.each do |k|
          self.send("#{k}=", self.class.defaults[k])
        end
      end

      def raw
        ordered = instance_fields.values_at(*self.class.fields)
        ordered.map(&:pack).join
      end

      def instance_fields
        @instance_fields ||= {}
      end

    end


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

    class SingleValueField < Struct.new(:value); end

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
        "#{Message.pack_var_int(value.bytesize)}#{value}"
      end

      def self.parse(raw)
        size, payload = Message.unpack_var_int(raw)
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
        b = raw.unpack('C')
        BooleanField.new(b == 0 ? false : true)
      end

    end
  end
end

require 'bitcoin_node/message/version'
