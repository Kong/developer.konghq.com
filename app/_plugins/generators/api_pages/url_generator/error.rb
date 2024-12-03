# frozen_string_literal: true

module Jekyll
  module APIPages
    module URLGenerator
      class Error
        def initialize(file:, version:, latest_version:)
          @file = file
          @version = version
          latest_version = latest_version
          @api_url = API.new(file:, version:, latest_version:)
        end

        def canonical_url
          @canonical_url ||= "#{@api_url.canonical_url}errors/"
        end

        def versioned_url
          @versioned_url ||= "#{@api_url.versioned_url}errors/"
        end

        def api_canonical_url
          @api_canonical_url ||= @api_url.canonical_url
        end

        def api_versioned_url
          @api_versioned_url ||= @api_url.versioned_url
        end
      end
    end
  end
end
