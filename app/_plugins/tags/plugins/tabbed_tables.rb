# frozen_string_literal: true

require_relative '../../monkey_patch'
require_relative '../../component_templates'

module Jekyll
  module RenderPlugins
    module TabbedTables # rubocop:disable Style/Documentation
      def render(context)
        @context = context
        @page = context.environments.first['page']
        site = context.registers[:site]

        context.stack do
          context['heading_level'] = Jekyll::ClosestHeading.new(@page, @line_number, context).level
          context['type'] = table
          context['tables'] = tables(site)
          ComponentTemplates.fetch('tabbed_tables', 'markdown', base: 'app/_includes/plugins').render(context)
        end
      end

      private

      def tables(site)
        columns = site.data.dig('plugins', 'tables', table, 'columns')

        releases(site).each_with_object({}) do |r, h|
          key = r.lts ? "#{r.number} LTS" : r.number
          h[key] = { 'columns' => columns, 'rows' => rows(r) }
        end
      end

      def releases(site)
        site.data
            .dig('products', 'gateway', 'releases')
            .reject { |r| r.key?('label') }
            .map { |r| Drops::Release.new(r) }
            .sort.reverse
      end
    end
  end
end
