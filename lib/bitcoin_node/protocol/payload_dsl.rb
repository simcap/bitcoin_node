module BitcoinNode
  module Protocol
    module PayloadDsl
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
  end
end
