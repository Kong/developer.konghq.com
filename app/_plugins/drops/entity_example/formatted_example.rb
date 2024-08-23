# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      class FormattedExample < Liquid::Drop
        def initialize(format:, presenter_class:, example_drop:)
          @format          = format
          @presenter_class = presenter_class
          @example_drop    = example_drop
        end

        def presenter
          @presenter ||= Object.const_get(
            "Jekyll::Drops::EntityExample::Presenters::#{@format.class.name.split('::').last}::#{@presenter_class}"
          ).new(example_drop: @example_drop)
        end

        def format
          @format
        end

        def template_file
          @template_file ||= @format.template_file(@example_drop.entity_type)
        end
      end
    end
  end
end
