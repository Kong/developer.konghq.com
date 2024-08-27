# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module KIC
          class Base < Presenters::Base
            def data
              @data ||= @example_drop.data
            end

            def template_file
              '/components/entity_example/format/kic.md'
            end
          end

          class Plugin < Base
          end
        end
      end
    end
  end
end
