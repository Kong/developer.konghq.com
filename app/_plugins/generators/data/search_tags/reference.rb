# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Data
    module SearchTags
      class Reference < Base # rubocop:disable Style/Documentation
        def search_data
          return {} if @page.data['api_spec'] || @page.data['plugin?'] && @page.data['reference?']

          super
        end
      end
    end
  end
end
