# frozen_string_literal: true

require 'securerandom'
require 'forwardable'

module Jekyll
  module Drops
    module EntityExample
      class Base < Liquid::Drop
        extend Forwardable

        def_delegators :@example, :data, :variables

        def initialize(example:)
          @example = example
        end

        def entity_type
          @entity_type ||= @example.type
        end

        def template
          @template ||= File.expand_path('app/_includes/components/entity_example.html')
        end

        def id
          @id ||= SecureRandom.hex(10)
        end

        def formatted_examples
          @formatted_examples ||= formats.map do |f|
            Drops::EntityExample::FormattedExample.new(
              format: f,
              presenter_class: 'Base',
              example_drop: self
            )
          end
        end

        def formats
          @formats ||= @example.formats.map(&:to_drop)
        end

        def formats_dropdown
          @formats_dropdown ||= begin
            options = formats.map do |f|
              Drops::Dropdowns::Option.new(text: f.to_option, value: f.value)
            end
            Drops::Dropdowns::Select.new(options)
          end
        end
      end
    end
  end
end
