# frozen_string_literal: true

require_relative 'tabbed_tables'
require_relative '../../monkey_patch'

module Jekyll
  module RenderPlugins
    class ReferenceableFields < Liquid::Tag # rubocop:disable Style/Documentation
      include TabbedTables

      def rows(release)
        Drops::Plugins::ReferenceableFields.all(release:).select(&:any?)
      end

      def table
        'referenceable_fields'
      end
    end
  end
end

Liquid::Template.register_tag('referenceable_fields', Jekyll::RenderPlugins::ReferenceableFields)
