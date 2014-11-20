module BitcoinNode
  module Protocol
    module FieldsDsl

      def self.included(base)
        base.extend(ClassMethods)
      end

      def defaults_definitions
        self.class.defaults_definitions
      end

      def fields_definitions
        self.class.fields_definitions
      end

      module ClassMethods
        def field(name, type, options = {})
          define_method(name) do
            fields[name]
          end

          define_method("#{name}=") do |value|
            if type === value
              fields[name] = value
            else
              fields[name] = type.new(*Array(value))
            end
          end

          fields_definitions[name] = type
          defaults_definitions[name] = options[:default] if options[:default]
        end

        def defaults_definitions
          @defaults_definitions ||= {}
        end

        def fields_definitions
          @fields_definitions ||= {}
        end
      end
    end
  end
end
