# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class UI < Base
          def template_file(type)
            @template_file ||= "/components/entity_example/#{type}/ui.md"
          end

          def to_option
            'Kong Manager/Gateway Manager'
          end
        end
      end
    end
  end
end
