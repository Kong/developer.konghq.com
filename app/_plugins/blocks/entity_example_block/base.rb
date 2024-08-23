# frozen_string_literal: true

module Jekyll
  module EntityExampleBlock
    class Base
      MAPPINGS = {
        'consumer'       => 'Consumer',
        'consumer_group' => 'ConsumerGroup',
        'plugin'         => 'Plugin',
        'service'        => 'Service',
        'route'          => 'Route',
        'target'         => 'Target',
        'upstream'       => 'Upstream',
        'workspace'      => 'Workspace'
      }

      def self.make_for(example:)
        raise ArgumentError, "Missing `type` for entity_example. Available types: #{MAPPINGS.keys.join(', ')}" unless example['type']

        klass = MAPPINGS[example['type']]

        raise ArgumentError, "Unsupported entity example type: #{example['type']}. Available types: #{MAPPINGS.keys.join(', ')}" unless klass

        Object.const_get("Jekyll::EntityExampleBlock::#{klass}").new(example:)
      end

      def initialize(example:)
        @example = example

        validate!
      end

      def type
        @type ||= @example.fetch('type')
      end

      def data
        @data ||= @example.fetch('data')
      end

      def variables
        @variables ||= @example.fetch('variables', {})
      end

      def formats
        @formats ||= @example.fetch('formats').sort.map do |f|
          Jekyll::EntityExampleBlock::Format::Base.make_for(format: f)
        end
      end

      def to_drop
        Object.const_get(
          "Jekyll::Drops::EntityExample::#{self.class.name.split('::').last}"
        ).new(example: self)
      end

      def validate!
        raise ArgumentError, "Missing `data` for entity_type `#{@example['type']}`." unless @example['data']
        raise ArgumentError, "Missing `formats` for entity_type `#{@example['type']}`. Available formats: #{Format::Base::MAPPINGS.keys.join(', ')}." unless @example['formats']

        formats.map(&:validate!)
      end
    end
  end
end
