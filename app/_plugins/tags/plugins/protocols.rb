# frozen_string_literal: true

require_relative 'tabbed_tables'

module Jekyll
  module RenderPlugins
    class Protocols < Liquid::Tag # rubocop:disable Style/Documentation
      include TabbedTables

      def rows(release)
        Drops::Plugins::Protocol.all(release:)
      end

      def table
        'protocols'
      end
    end
  end
end

Liquid::Template.register_tag('plugin_protocols', Jekyll::RenderPlugins::Protocols)
