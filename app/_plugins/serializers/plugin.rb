# frozen_string_literal: true

module Jekyll
  module Serializers
    class Plugin # rubocop:disable Style/Documentation
      def initialize(plugin)
        @plugin = plugin
      end

      def to_json(*_args)
        {
          'plugin' => { 'name' => @plugin.slug },
          'groups' => groups
        }
      end

      private

      def examples_by_group
        @examples_by_group ||= @plugin.examples.select(&:show_in_api?).group_by(&:group)
      end

      def groups
        examples_by_group.map do |slug, examples|
          {
            'group_name' => group_name(slug),
            'examples' => examples.map { |e| Plugins::Example.new(e).to_json }
          }
        end
      end

      def group_name(slug)
        group = @plugin.examples_groups.detect { |g| g['slug'] == slug }

        group && group['text'] || 'Basic use cases'
      end
    end
  end
end
