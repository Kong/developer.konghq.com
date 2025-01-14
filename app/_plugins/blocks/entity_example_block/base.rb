# frozen_string_literal: true

module Jekyll
  module EntityExampleBlock
    class Base
      def self.make_for(example:)
        raise ArgumentError, 'Missing `type` for entity_example.}' unless example['type']

        if example['type'] == 'plugin'
          Plugin.new(example:)
        else
          new(example:)
        end
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
        @formats ||= @example.fetch('formats', [])
      end

      def headers
        @headers ||= @example.fetch('headers', {})
      end

      def to_drop
        Object.const_get(
          "Jekyll::Drops::EntityExample::#{self.class.name.split('::').last}"
        ).new(example: self)
      end

      def validate!
        raise ArgumentError, "Missing `data` for entity_type `#{@example['type']}`." unless @example['data']

        return if @example['formats']

        raise ArgumentError,
              "Missing `formats` for entity_type `#{@example['type']}`. Available formats: #{Format::Base::MAPPINGS.keys.join(', ')}."
      end
    end
  end
end
