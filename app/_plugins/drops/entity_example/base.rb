# frozen_string_literal: true

require 'securerandom'

module Jekyll
  module Drops
    module EntityExample
      class Base < Liquid::Drop
        def initialize(example:)
          @example = example
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
              target: Jekyll::EntityExamples::Target::Base.make_for(target: @example.type).to_drop,
              data: @example.data,
              presenter_class: 'Base',
              entity_type: @example.type
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
