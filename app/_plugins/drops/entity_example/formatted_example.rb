# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      class FormattedExample < Liquid::Drop
        def initialize(format:, data:, target:, presenter_class:, entity_type:, variables:)
          @format          = format
          @data            = data
          @target          = target
          @presenter_class = presenter_class
          @entity_type     = entity_type
          @variables       = variables
        end

        def presenter
          @presenter ||= Object.const_get(
            "Jekyll::Drops::EntityExample::Presenters::#{@format.class.name.split('::').last}::#{@presenter_class}"
          ).new(target: @target.value, data: @data, entity_type: @entity_type, variables: @variables)
        end

        def format
          @format
        end

        def target
          @target
        end

        def template_file
          @template_file ||= @format.template_file(@entity_type)
        end
      end
    end
  end
end
