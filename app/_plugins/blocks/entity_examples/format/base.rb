# frozen_string_literal: true

module Jekyll
  module EntityExamples
    module Format
      class Base
        MAPPINGS = {
          'admin-api'   => 'AdminAPI',
          'deck'        => 'Deck',
          'konnect-api' => 'KonnectAPI',
          'kic'         => 'KIC',
          'ui'          => 'UI',
          'terraform'   => 'Terraform'
        }

        def self.make_for(format:)
          klass = MAPPINGS[format]

          raise ArgumentError, "Unsupported `format`: #{format}. Available formats: #{MAPPINGS.keys.join(', ')}" unless klass

          Object.const_get("Jekyll::EntityExamples::Format::#{klass}").new(format:)
        end

        def initialize(format:)
          @format = format
        end

        def value
          @value ||= @format
        end

        def validate!; end

        def to_drop
          Object.const_get(
            "Jekyll::Drops::EntityExample::Format::#{self.class.name.split('::').last}"
          ).new(format: self)
        end
      end
    end
  end
end
