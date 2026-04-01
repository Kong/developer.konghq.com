# frozen_string_literal: true

module Jekyll
  module Drops
    class GatewayChangelog < Liquid::Drop # rubocop:disable Style/Documentation
      class Entries < Liquid::Drop # rubocop:disable Style/Documentation
        NO_LINK = '_no_link_'

        def initialize(entries:) # rubocop:disable Lint/MissingSuper
          @entries = entries

          group_plugin_entries
        end

        def by_scope
          @by_scope ||= begin
            grouped = @entries.group_by { |e| e['scope'] }
            grouped['Plugin'] = group_plugin_entries if grouped.key?('Plugin')
            grouped
          end
        end

        def group_plugin_entries
          @group_plugin_entries ||= strip_plugin_from_messages(
            group_messages_by_plugin(
              @entries.group_by { |e| e['scope'] }.fetch('Plugin', [])
            )
          ).sort.to_h
        end

        private

        def leading_markdown_link(message)
          match = message.match(/^\[.*?\]\(.*?\)\s*:/)
          match ? match[0] : nil
        end

        def leading_markdown_bold(message)
          match = message.match(/^\*\*(.*)\*\*\s*:/)
          match ? match[0] : nil
        end

        def group_messages_by_plugin(data)
          data.group_by do |entry|
            leading_markdown_link(entry['message']) || leading_markdown_bold(entry['message']) || NO_LINK
          end
        end

        def strip_plugin_from_messages(hash)
          hash.each_with_object({}) do |(key, value), h|
            h[key] = value.map do |v|
              if key != NO_LINK
                message = v['message'].sub(/^#{Regexp.escape(key)}/, '')
                v.merge('message' => message)
              else
                v
              end
            end
          end
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
                                       .sort_by { |k, _| order.index(k) || Float::INFINITY }.to_h
        end

        def release_date
          @release_date ||= site.data.dig('products', 'gateway', 'release_dates', @number)
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

        def order
          @order ||= site.data.dig('changelogs', 'config', 'order') || []
        end
      end

      def initialize(site:) # rubocop:disable Lint/MissingSuper
        @site = site
      end

      def versions
        @versions ||= entries_by_version.map do |number, entries|
          Version.new(number:, entries:)
        end.sort_by { |v| Gem::Version.new(v.number) }.reverse # rubocop:disable Style/MultilineBlockChain
      end

      def entries_by_version
        @entries_by_version ||= json_changelog.each_with_object({}) do |(version, values), hash|
          values['kong-manager-ee'].map { |e| e['scope'] = 'Kong Manager' } if values.key?('kong-manager-ee')
          key = version_to_key(version)
          hash[key] ||= []
          hash[key].concat(values.values.flatten)
        end
      end

      def version_to_key(version)
        # treat ee and oss versions as ee versions
        parts = version.split('.').map(&:to_i)
        parts.fill(0, parts.size...4)
        parts.join('.')
      end

      def json_changelog
        @json_changelog ||= @site.data.dig('changelogs', 'gateway')
      end
    end
  end
end
