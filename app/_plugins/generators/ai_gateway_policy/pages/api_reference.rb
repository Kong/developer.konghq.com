# frozen_string_literal: true

require 'yaml'
require_relative './base'

module Jekyll
  module AIGatewayPolicyPages
    module Pages
      class ApiReference < Base # rubocop:disable Style/Documentation
        def self.url(policy)
          if policy.unreleased?
            "#{base_url}#{policy.slug}/api/#{policy.min_release}/"
          else
            "#{base_url}#{policy.slug}/api/"
          end
        end

        def content
          ''
        end

        def markdown_content
          @markdown_content ||= File.read('app/_includes/plugins/api_reference.md')
        end

        def data
          super.merge('api_reference?' => true, 'toc' => false, 'api_spec' => api_spec)
        end

        def layout
          'policies/api_reference'
        end

        private

        def api_spec
          @api_spec ||= YAML.load(File.read(file))
        end
      end
    end
  end
end
