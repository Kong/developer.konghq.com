# frozen_string_literal: true

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
          Liquid::Template.parse(template, { line_numbers: true }).render(context)
        end
      end

      private

      def template
        @template ||= File.read(File.expand_path('app/_includes/plugins/tabbed_tables.md'))
      end

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
