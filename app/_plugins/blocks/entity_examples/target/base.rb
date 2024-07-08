# frozen_string_literal: true

module Jekyll
  module EntityExamples
    module Target
      class Base
        MAPPINGS = {
          'consumer'       => 'Consumer',
          'consumer_group' => 'ConsumerGroup',
          'global'         => 'Global',
          'route'          => 'Route',
          'service'        => 'Service',
        }.freeze

        def self.make_for(target:)
          klass = MAPPINGS[target]

          raise ArgumentError, "Unsupported `target`: #{target}. Available targets: #{MAPPINGS.keys.join(', ')}" unless klass

          Object.const_get("Jekyll::EntityExamples::Target::#{klass}").new(target:)
        end

        def initialize(target:)
          @target = target
        end

        def value
          @value ||= @target
        end

        def validate!; end

        def to_drop
          Object.const_get(
            "Jekyll::Drops::EntityExample::Target::#{self.class.name.split('::').last}"
          ).new(target: self)
        end
      end
    end
  end
end
