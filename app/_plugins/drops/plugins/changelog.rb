# frozen_string_literal: true

module Jekyll
  module Drops
    module Plugins
      class Changelog < Liquid::Drop # rubocop:disable Style/Documentation
        class Version < Liquid::Drop # rubocop:disable Style/Documentation
          include Jekyll::SiteAccessor

          attr_reader :number

          def initialize(number:, entries:) # rubocop:disable Lint/MissingSuper
            @number = number
            @entries = entries
          end

          def release_date
            @release_date ||= site.data.dig('products', 'gateway', 'release_dates', @number)
          end

          def entries_by_type
            @entries_by_type ||= @entries.group_by { |e| e['type'] }
                                         .sort_by { |k, _| order.index(k) || Float::INFINITY }.to_h
          end

          def order
            @order ||= site.data.dig('changelogs', 'config', 'order') || []
          end
        end

        def initialize(changelog) # rubocop:disable Lint/MissingSuper
          @changelog = changelog
        end

        def versions
          @versions ||= @changelog.map { |number, entries| Version.new(number:, entries:) }
                                  .sort_by { |v| Gem::Version.new(v.number) }.reverse
        end
      end
    end
  end
end
