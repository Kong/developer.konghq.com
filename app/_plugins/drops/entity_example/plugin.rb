# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      class Plugin < Base
        def formatted_examples
          @formatted_examples ||= targets.map do |t|
            formats.map do |f|
              Drops::EntityExample::FormattedExample.new(
                format: f,
                presenter_class: 'Plugin',
                example_drop: self
              )
            end
          end.flatten
        end

        def target
          @target ||= @example.target
        end
      end
    end
  end
end
