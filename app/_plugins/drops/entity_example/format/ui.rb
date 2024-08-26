# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class UI < Base
          def template_file
            @template_file ||= "/components/entity_example/format/ui.md"
          end

          def to_option
            'Kong Manager/Gateway Manager'
          end
        end
      end
    end
  end
end
