# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class Terraform < Base
          def template_file(type)
            @template_file ||= "/components/entity_example/#{type}/terraform.md"
          end

          def to_option
            'Terraform'
          end
        end
      end
    end
  end
end
