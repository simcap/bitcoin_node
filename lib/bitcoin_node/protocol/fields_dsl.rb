module BitcoinNode
  module Protocol
    module FieldsDsl
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
    end
  end
end
