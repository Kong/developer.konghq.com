# frozen_string_literal: true

require 'json'

module Jekyll
  module Drops
    module Plugins
      class AIGWPolicySchema < Liquid::Drop # rubocop:disable Style/Documentation
        SCHEMAS_DIR = File.expand_path('../../../_schemas/ai-gateway/policies', __dir__).freeze
        FILE_INDEX = Dir.glob(File.join(SCHEMAS_DIR, '*.json'))
                        .to_h { |f| [File.basename(f).downcase, f] }
                        .freeze

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
          @file_path ||= FILE_INDEX["#{@slug.delete('-')}.json"] ||
                         raise(ArgumentError, "Schema file not found for policy `#{@slug}`")
        end
      end
    end
  end
end
