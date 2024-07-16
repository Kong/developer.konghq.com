# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      class Plugin < Base
        def targets_dropdown
          @targets_dropdown ||= Drops::Dropdowns::Select.new(
            [Drops::Dropdowns::Option.new(text: target.to_option, value: target.value)]
            )
        end

        def targets
          @targets ||= @example.targets.map(&:to_drop)
        end

        def targets_dropdown
          @targets_dropdown ||= begin
            options = targets.map do |t|
              Drops::Dropdowns::Option.new(text: t.to_option, value: t.value)
            end
            Drops::Dropdowns::Select.new(options)
          end
        end

        def formatted_examples
          @formatted_examples ||= targets.map do |t|
            formats.map do |f|
              Drops::EntityExample::FormattedExample.new(
                format: f,
                target: t,
                data: @example.data,
                presenter_class: 'Plugin',
                entity_type: @example.type
              )
            end
          end.flatten
        end

        def formatted_examples_by_target
          @formatted_examples_by_target ||= formatted_examples.group_by { |fe| fe.target }
        end
      end
    end
  end
end
