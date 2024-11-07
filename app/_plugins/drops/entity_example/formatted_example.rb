# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      class FormattedExample < Liquid::Drop
        MAPPINGS = {
          'admin-api'   => 'AdminAPI',
          'deck'        => 'Deck',
          'konnect-api' => 'KonnectAPI',
          'kic'         => 'KIC',
          'ui'          => 'UI',
          'terraform'   => 'Terraform'
        }

        def initialize(format:, presenter_class:, example_drop:)
          @format          = format
          @presenter_class = presenter_class
          @example_drop    = example_drop
        end

        def presenter
          @presenter ||= Object.const_get(
            "Jekyll::Drops::EntityExample::Presenters::#{MAPPINGS[@format]}::#{@presenter_class}"
          ).new(example_drop: @example_drop)
        end

        def format
          @format
        end

        def template_file
          @template_file ||= presenter.template_file
        end
      end
    end
  end
end
