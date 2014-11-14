# coding: ascii-8bit
require 'digest'

module BitcoinNode
  module Protocol
    MessageParsingError = Class.new(StandardError)
    IncompleteMessageError = Class.new(MessageParsingError)
    InvalidChecksumError = Class.new(MessageParsingError)

    def self.digest(content)
      Digest::SHA256.digest(Digest::SHA256.digest(content))
    end

    class Header
      SIZE = 24

      def self.build_from(payload)
        new(payload)
      end

      def initialize(payload)
        @payload = payload
      end
      private_class_method :new 

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
        BN::Protocol.digest(@payload.raw)[0...4]
      end

    end

    class Message
      def self.validate(raw_message)
        network, command, expected_length, checksum = raw_message.unpack('a4A12Va4')
        payload = raw_message[Header::SIZE...(Header::SIZE + expected_length)]
        if (actual = payload.bytesize) < expected_length
          raise BN::P::IncompleteMessageError.new("Incomplete message (missing #{expected_length - actual} bytes)")
        elsif checksum != BN::Protocol.digest(payload)[0...4]
          raise BN::P::InvalidChecksumError.new("Invalid checksum on command #{command}")
        else
          [payload, command]
        end
      end

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
      class << self
        def field(name, type, options = {})
          define_method(name) do
            instance_fields[name]
          end

          define_method("#{name}=") do |value|
            if type === value
              instance_fields[name] = value
            else
              instance_fields[name] = type.new(*Array(value))
            end
          end

          fields[name] = type
          defaults[name] = options[:default] if options[:default]
        end

        def defaults
          @defaults ||= {}
        end

        def fields
          @fields ||= {}
        end

        def field_names
          fields.keys
        end

        def parse(payload)
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
      end

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

      def name
        self.class.name.split('::').last.downcase 
      end

      def inspect
        @instance_fields.inspect
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
