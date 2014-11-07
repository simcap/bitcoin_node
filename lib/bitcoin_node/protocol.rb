# coding: ascii-8bit
require 'digest'

module BitcoinNode
  module Protocol

    class Header

      def initialize(payload)
        @payload = payload
      end

      def raw
        @raw ||= [raw_network, raw_command, raw_length, raw_checksum_head].join
      end

      private 

      def raw_network
        BitcoinNode.network
      end

      def raw_command
        @payload.name.ljust(12, "\x00")[0...12]
      end

      def raw_length
        [@payload.bytesize].pack("V")
      end

      def raw_checksum_head
        Digest::SHA256.digest(Digest::SHA256.digest(@payload.raw))[0...4]
      end

    end

    class Message

      def self.ping
        new(BN::Protocol::Ping.new)
      end

      def self.pong(nonce)
        new(BN::Protocol::Pong.new(nonce: nonce))
      end

      attr_reader :command

      def initialize(payload)
        @payload = payload
        @command = payload.name
      end

      def raw
        @raw ||= begin
          [Header.new(@payload).raw, @payload.raw].join.force_encoding(Encoding.find('ASCII-8BIT'))
        end
      end

      def bytesize
        raw.bytesize
      end

    end

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

      def initialize(attributes = {})
        attributes.each do |k,v|
          self.send("#{k}=", v) 
        end
        missings = self.class.fields - attributes.keys
        missings.each do |k|
          d = self.class.defaults[k]
          self.send("#{k}=", Proc === d ? d.call : d)
        end
      end

      def raw
        @raw ||= begin
          ordered = instance_fields.values_at(*self.class.fields)
          ordered.map(&:pack).join
        end
      end

      def bytesize
        raw.bytesize
      end

      def name
        self.class.name.split('::').last.downcase 
      end

      def instance_fields
        @instance_fields ||= {}
      end

      def inspect
        @instance_fields.inspect
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
      case payload.unpack("C")[0]
      when 0xfd; payload.unpack("xva*")
      when 0xfe; payload.unpack("xVa*")
      when 0xff; payload.unpack("xQa*")
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

require 'bitcoin_node/protocol/version'
require 'bitcoin_node/protocol/verack'
require 'bitcoin_node/protocol/ping_pong'
