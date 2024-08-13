# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module InfoBox
      class Tutorial < Base
        def plugins
          @plugins ||= begin
            plugins = @page.fetch('plugins', [])
            return [] if plugins.empty?

            @site.data['kong_plugins'].values_at(*plugins)
          end
        end

        def template_file
          @template_file ||= File.expand_path('app/_includes/components/info_box/tutorial.html')
        end
      end
    end
  end
end
