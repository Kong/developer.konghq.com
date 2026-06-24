# frozen_string_literal: true

require 'json'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module Plugins
      class AIGWPolicySchema < Liquid::Drop # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def initialize(slug:) # rubocop:disable Lint/MissingSuper
          @slug = slug
        end

        def as_json(*)
          @as_json ||= { 'properties' => { 'config' => schema.dig('properties', 'config') } }
        end

        private

        def schema
          @schema ||= JSON.parse(File.read(file_path))
        end

        def file_path
          @file_path ||= File.join(site.source, '_schemas', 'ai-gateway', 'policies', filename)
        end

        def filename
          "#{@slug.split('-').map(&:capitalize).join}.json"
        end
      end
    end
  end
end
