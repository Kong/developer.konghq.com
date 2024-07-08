# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      class FormattedExample < Liquid::Drop
        def initialize(format:, data:, target:, presenter_class:, entity_type:)
          @format          = format
          @data            = data
          @target          = target
          @presenter_class = presenter_class
          @entity_type     = entity_type
        end

        def presenter
          @presenter ||= Object.const_get(
            "Jekyll::Drops::EntityExample::Presenters::#{@format.class.name.split('::').last}::#{@presenter_class}"
          ).new(target: target, data: @data, entity_type: @entity_type)
        end

        def format
          @format.value
        end

        def target
          @target.value
        end

        def template_file
          @template_file ||= @format.template_file(@entity_type)
        end
      end
    end
  end
end
