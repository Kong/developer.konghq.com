# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Data
    module Title
      class Plugin < Base
        def title_sections
          return [page_title] unless @page.data['plugin?']

          [
            name,
            title,
            version,
            'Plugin'
          ]
        end

        def llm_title
          return page_title unless @page.data['plugin?']
          return name if @page.data['example?']

          [
            name,
            'Plugin',
            title
          ].compact.join(' ')
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

          if @page.data['reference?']
            return 'AI Gateway v2 on-prem Configuration Reference' if @page.data['aigw_onprem_plugin_reference?']

            'Configuration Reference'
          elsif @page.data['changelog?']
            'Changelog'
          elsif @page.data['api_reference?']
            'OpenAPI Specification'
          end
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
