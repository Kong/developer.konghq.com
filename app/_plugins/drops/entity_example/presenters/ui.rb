# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module UI
          class Base < Liquid::Drop
            def initialize(example_drop:)
              @example_drop = example_drop
            end

            def entity_type
              @entity_type ||= @example_drop.entity_type
            end

            def data
              @data ||= @example_drop.data
            end
          end

          class Plugin < Base
          end
        end
      end
    end
  end
end
