# frozen_string_literal: true

require_relative '../../lib/site_accessor'
require_relative '../release'

module Jekyll
  module Drops
    module AIGateway
      class PolicyPriority < Liquid::Drop
        extend Jekyll::SiteAccessor

        def self.all
          config = site.data.dig('policies', 'ai-gateway', 'priority')
          excluded = config.fetch('exclude')
          overrides = config.fetch('overrides')
          release_priorities = priorities

          rows = site.data.fetch('ai_gateway_policies').filter_map do |slug, policy|
            next if excluded.include?(slug) || policy.data['published'] == false

            priority = overrides[slug] || release_priorities[slug]
            next if priority.nil?

            new(slug:, policy:, priority:)
          end
          rows.sort_by { |row| [-row.priority, row.title] }
        end

        def self.priorities
          site.data.dig('plugins', 'priorities', latest_release.major_minor_version) || {}
        end
        private_class_method :priorities

        def self.latest_release
          site.data.dig('products', 'gateway', 'releases')
              .reject { |r| r.key?('label') }
              .map { |r| Drops::Release.new(r) }
              .max
        end
        private_class_method :latest_release

        def initialize(slug:, policy:, priority:)
          @slug = slug
          @policy = policy
          @priority = priority
        end

        def title
          @title ||= @policy.data['name']
        end

        def url
          @url ||= @policy.data['overview_url']
        end

        attr_reader :slug, :priority

        def [](key)
          key = key.to_s
          public_send(key) if respond_to?(key)
        end
      end
    end
  end
end
