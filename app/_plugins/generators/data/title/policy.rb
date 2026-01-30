# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Data
    module Title
      class Policy < Base # rubocop:disable Style/Documentation
        def title_sections
          return [page_title] unless @page.data['plugin?']

          [
            name,
            title,
            version,
            'Policy'
          ]
        end

        def version
          return unless @page.data['reference?']
          return if @page.data['canonical?']

          v = @page.data['release']
          Gem::Version.correct?(v) ? "v#{v}" : v
        end

        def title
          return if @page.data['overview?']
          return if @page.data['example?']

          'Configuration Reference'
        end

        def name
          name = @page.data['plugin'].name

          if @page.data['example?']
            "#{name}: #{@page.data['example_title']}"
          else
            name
          end
        end
      end
    end
  end
end
