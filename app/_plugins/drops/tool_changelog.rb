# frozen_string_literal: true

module Jekyll
  module Drops
    class ToolChangelog < Liquid::Drop # rubocop:disable Style/Documentation
      class Version < Liquid::Drop # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        attr_reader :number

        def initialize(tool:, number:, entries:) # rubocop:disable Lint/MissingSuper
          @tool = tool
          @number = number
          @entries = entries
        end

        def entries_by_type
          @entries_by_type ||= @entries.group_by { |e| e['type'] }
                                       .sort_by { |k, _| order.index(k) || Float::INFINITY }.to_h
        end

        def release_date
          @release_date ||= site.data.dig('tools', @tool, 'release_dates', @number)
        end

        private

        def order
          @order ||= YAML.safe_load(File.read(File.join(site.source, '_changelogs', 'config.yaml')))
                         .fetch('order', [])
        end
      end

      def initialize(site:, tool:) # rubocop:disable Lint/MissingSuper
        @site = site
        @tool = tool
      end

      def versions
        @versions ||= entries_by_version.map do |number, entries|
          Version.new(tool: @tool, number:, entries:)
        end.sort_by { |v| Gem::Version.new(v.number) }.reverse # rubocop:disable Style/MultilineBlockChain
      end

      def entries_by_version
        @entries_by_version ||= json_changelog.each_with_object({}) do |(version, values), hash|
          hash[version] = values.values.flatten
        end
      end

      def json_changelog
        @json_changelog ||= JSON.parse(File.read(File.join(@site.source, '_changelogs', "#{@tool}.json")))
      end
    end
  end
end
