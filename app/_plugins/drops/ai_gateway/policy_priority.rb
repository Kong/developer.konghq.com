# frozen_string_literal: true

require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module AIGateway
      class PolicyPriority < Liquid::Drop
        extend Jekyll::SiteAccessor

        def self.all
          priorities = site.data.dig('policies', 'ai-gateway', 'priorities') || {}

          rows = site.data.fetch('ai_gateway_policies').filter_map do |slug, policy|
            next if policy.data['published'] == false

            priority = priorities[slug]
            next if priority.nil?

            new(slug:, policy:, priority:)
          end
          rows.sort_by { |row| [-row.priority, row.title] }
        end

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
