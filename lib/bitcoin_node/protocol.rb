# coding: ascii-8bit
require_relative 'protocol/payload_dsl'
require 'digest'

module BitcoinNode
  module Protocol

    VERSION = 70001

    MessageParsingError = Class.new(StandardError)
    IncompleteMessageError = Class.new(MessageParsingError)
    InvalidChecksumError = Class.new(MessageParsingError)

    def self.digest(content)
      Digest::SHA256.digest(Digest::SHA256.digest(content))
    end

    def self.nonce
      rand(0xffffffffffffffff) 
    end

    class Header
      SIZE = 24

      def self.build_from(payload)
        new(payload)
      end

      def self.unpack(raw)
        raw.unpack('a4A12Va4')
      end

      def initialize(payload)
        @payload = payload
      end
      private_class_method :new 

      def raw
        @raw ||= begin
          [BitcoinNode.network,
           @payload.name.ljust(12, "\x00")[0...12],
           [@payload.bytesize].pack("V"),
           BN::Protocol.digest(@payload.raw)[0...4]].join
        end
      end
    end

    class Message
      attr_reader :command

      def initialize(payload)
        raise ArgumentError, 'Expected Payload type' unless Payload === payload
        @payload = payload
        @command = payload.name
      end

      def raw
        @raw ||= begin
          [Header.build_from(@payload).raw, @payload.raw]
            .join
            .force_encoding('binary')
        end
      end

      def bytesize
        raw.bytesize
      end

      def self.validate(raw_message)
        network, command, expected_length, checksum = Header.unpack(raw_message)
        raw_payload = raw_message[Header::SIZE...(Header::SIZE + expected_length)]
        if (actual = raw_payload.bytesize) < expected_length
          raise BN::P::IncompleteMessageError.new("Incomplete message (missing #{expected_length - actual} bytes)")
        elsif checksum != BN::Protocol.digest(raw_payload)[0...4]
          raise BN::P::InvalidChecksumError.new("Invalid checksum on command #{command}")
        else
          [raw_payload, command]
        end
      end
    end

    module Messages
      module_function

      def ping
        BN::P::Message.new(BN::Protocol::Ping.new)
      end

      def pong(nonce)
        BN::P::Message.new(BN::Protocol::Pong.new(nonce: nonce))
      end

      def verack
        BN::P::Message.new(BN::Protocol::Verack.new)
      end

      def version
        BN::P::Message.new(BN::Protocol::Version.new)
      end

      def getaddr
        BN::P::Message.new(BN::Protocol::Getaddr.new)
      end
    end

    class Payload
      extend PayloadDsl

      def initialize(attributes = {})
        attributes.each do |k,v|
          self.send("#{k}=", v) 
        end
        missings = self.class.field_names - attributes.keys
        missings.each do |k|
          d = self.class.defaults[k]
          self.send("#{k}=", Proc === d ? d.call : d)
        end
      end

      def raw
        @raw ||= begin
          ordered = instance_fields.values_at(*self.class.field_names)
          ordered.map(&:pack).join
        end
      end

      def bytesize
        raw.bytesize
      end

      def type
        self.class.name.split('::').last
      end

      def name
        type.downcase 
      end

      def to_s
        "#<#{type} #{@instance_fields.inspect}>"
      end
      alias_method :inspect, :to_s

      def self.parse(payload)
        result = fields.inject({}) do |memo, (field_name, type)|
          custom_parse_method = "parse_#{field_name.to_s}"
          parsed, payload = if respond_to?(custom_parse_method)
                              public_send(custom_parse_method, payload, memo)
                            else
                              type.parse(payload)
                            end
          memo[field_name] = parsed
          memo
        end
        new(result)
      end

      private 

      def instance_fields
        @instance_fields ||= {}
      end
    end
  end
end

require 'bitcoin_node/protocol/fields'
require 'bitcoin_node/protocol/payloads'
