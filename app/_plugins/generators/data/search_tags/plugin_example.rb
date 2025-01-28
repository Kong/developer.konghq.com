# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Data
    module SearchTags
      class PluginExample < Base # rubocop:disable Style/Documentation
        def search_data
          super.merge('title' => @page.data['example_title'])
        end
      end
    end
  end
end
