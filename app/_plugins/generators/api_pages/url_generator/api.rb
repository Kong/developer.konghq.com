# frozen_string_literal: true

module Jekyll
  module APIPages
    module URLGenerator
      class API
        def initialize(file:, version:, latest_version:)
          @file = file
          @version = version
          @latest_version = latest_version
        end

        def base_url
          @base_url ||= file_to_url
        end

        def canonical_url
          @canonical_url ||= "#{base_url}#{@latest_version}/"
        end

        def versioned_url
          @versioned_url ||= "#{base_url}#{version_segment}/"
        end

        def file_to_url
          @file_to_url ||= @file
                           .gsub('_index.md', '')
                           .gsub('_api', '/api')
        end

        def version_segment
          @version_segment ||= @version.to_s
        end
      end
    end
  end
end
