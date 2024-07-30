# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module InfoBox
      class EntityReference < Base
        def template_file
          @template_file ||= File.expand_path('app/_includes/components/info_box/entity_reference.html')
        end
      end
    end
  end
end
