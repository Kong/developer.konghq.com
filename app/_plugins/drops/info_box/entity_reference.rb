# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module InfoBox
      class EntityReference < Base
        def template_file
          @template_file ||= File.expand_path('app/_includes/components/info_box/entity_reference.html')
        end

        def api_specs
          @api_specs ||= begin
            api_specs = @page.fetch('api_specs', {})

            api_specs.map do |namespace, apis|
              @site.data['api_specs'][namespace].values_at(*apis)
            end.flatten
          end
        end
      end
    end
  end
end
