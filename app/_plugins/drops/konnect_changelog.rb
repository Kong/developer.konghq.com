# frozen_string_literal: true

module Jekyll
  module Drops
    class KonnectChangelog < Liquid::Drop # rubocop:disable Style/Documentation
      class Entry < Liquid::Drop # rubocop:disable Style/Documentation
        attr_reader :title, :date, :content, :url

        def initialize(title:, date:, content:, url: nil) # rubocop:disable Lint/MissingSuper
          @title = title
          @date = date
          @content = content
          @url = url
        end
      end

      def initialize(site:) # rubocop:disable Lint/MissingSuper
        @site = site
      end

      def entries
        @entries ||= raw_entries.map do |data|
          Entry.new(
            title: data['title'],
            date: data['date'],
            content: data['content'],
            url: data['url']
          )
        end.sort_by(&:date).reverse
      end

      private

      def raw_entries
        (@site.data.dig('changelogs', 'konnect') || {}).values
      end
    end
  end
end
