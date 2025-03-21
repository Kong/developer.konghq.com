# frozen_string_literal: true

require_relative 'tabbed_tables'

module Jekyll
  module RenderPlugins
    class Priorities < Liquid::Tag # rubocop:disable Style/Documentation
      include TabbedTables

      def rows(release)
        Drops::Plugins::Priorities.all(release:).sort_by do |r|
          if r.priority.nil?
            [1, r.title]
          else
            [0, -r.priority]
          end
          [r.priority.nil? ? 1 : 0, r.priority ? -r.priority : 0]
        end
      end

      def table
        'priorities'
      end
    end
  end
end

Liquid::Template.register_tag('plugin_priorities', Jekyll::RenderPlugins::Priorities)
