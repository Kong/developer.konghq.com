# frozen_string_literal: true

module Jekyll
  module Drops
    class GatewayChangelog < Liquid::Drop # rubocop:disable Style/Documentation
      class Entries < Liquid::Drop # rubocop:disable Style/Documentation
        def initialize(entries:) # rubocop:disable Lint/MissingSuper
          @entries = entries
        end

        def by_scope
          @by_scope ||= @entries.group_by { |e| e['scope'] }
        end
      end

      class Version < Liquid::Drop # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        attr_reader :number

        def initialize(number:, entries:) # rubocop:disable Lint/MissingSuper
          @number = number
          @entries = entries

          process_entries!
        end

        def entries_by_type
          @entries_by_type ||= @entries.group_by { |e| e['type'] }
                                       .transform_values { |entries| Entries.new(entries:) }
        end

        private

        def process_entries!
          @entries.map do |e|
            next unless e['scope'] == 'Plugin'

            match = e['message'].match(/(\*\*(.*?):?\*\*?)/)
            next unless match

            plugin = find_plugin(match[2])
            e['message'].sub!(/\*\*(.*?):?\*\*?/, "[#{plugin.data['slug']}](#{plugin.url})") unless plugin.nil?
          end
        end

        def find_plugin(name_or_slug)
          site.data['kong_plugins'].values.detect do |p|
            name_or_slug = name_or_slug.downcase
            p.data['name'].downcase == name_or_slug || p.data['slug'] == name_or_slug
          end
        end
      end

      def initialize(site:) # rubocop:disable Lint/MissingSuper
        @site = site
      end

      def versions
        @versions ||= entries_by_version.map do |number, entries|
          Version.new(number:, entries:)
        end
      end

      def entries_by_version
        @entries_by_version ||= json_changelog.each_with_object({}) do |(version, values), hash|
          values['kong-manager-ee'].map { |e| e['scope'] = 'Kong Manager' } if values.key?('kong-manager-ee')
          hash[version] ||= []
          hash[version].concat(values.values.flatten)
        end
      end

      def json_changelog
        @json_changelog ||= @site.data.dig('changelogs', 'gateway')
      end
    end
  end
end
