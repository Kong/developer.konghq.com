# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module KIC
          class Base < Liquid::Drop
            def initialize(data:, target:, entity_type:, variables:)
              @data        = data
              @target      = target
              @entity_type = entity_type
              @variables   = variables
            end

            def data
              @data
            end
          end

          class Plugin < Base
          end
        end
      end
    end
  end
end
