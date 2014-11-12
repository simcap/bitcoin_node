module BitcoinNode
  module P2p
    class NullProbe
      def <<(*args); end
    end

    class StoreProbe
      attr_reader :store

      def initialize
        @store = Hash.new { |h, key| h[key] = [] }
      end

      def <<(hash)
        hash.each do |key, value|
          store[key] << value
        end
      end
    end

    class LoggingProbe
      attr_reader :logger

      def initialize(progname)
        @logger = ::Logger.new(STDOUT)
        @logger.progname = progname.upcase
      end

      def <<(hash)
        hash.each do |key, value|
          case key
          when :sending then logger.info("Sending #{value}")
          when :receiving then logger.info("Receiving #{value}")
          when :connected then logger.info("Connected to #{value}")
          when :connection then logger.info("Connection received from #{value}")
          when :closed then logger.info("Closed connection to #{value}")
          else logger.unknown('Cannot log that!!')
          end
        end
      end
    end
  end
end
