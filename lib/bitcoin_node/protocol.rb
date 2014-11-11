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

      def self.verack
        new(BN::Protocol::Verack.new)
      end

      def self.getaddr
        new(BN::Protocol::Getaddr.new)
      end

      attr_reader :command

      def initialize(payload)
        @payload = payload
        @command = payload.name
      end

      def raw
        @raw ||= begin
          [Header.new(@payload).raw, @payload.raw]
            .join
            .force_encoding('binary')
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
              instance_fields[name] = type.new(*Array(value))
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
  end
end

require 'bitcoin_node/protocol/fields'
require 'bitcoin_node/protocol/payloads'
