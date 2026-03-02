# frozen_string_literal: true

require 'uri'
require 'forwardable'

module Jekyll
  module Drops
    module OAS
      class InsomniaLink < Liquid::Drop
        extend Forwardable

        attr_reader :site, :label

        def_delegators :api_spec_file, :raw_api_spec

        def initialize(label:, version:, page_relative_path:, site:)
          @label = label
          @version = version
          @page_relative_path = page_relative_path.dup
          @site = site
        end

        def url
          @url ||= URI::HTTPS.build(
            host: insomnia_run.host,
            path: insomnia_run.path,
            query:
          ).to_s
        end

        def query
          @query ||= URI.encode_www_form(uri:, label:)
        end

        def exist?
          api_spec_file.exist?
        end

        def hash
          @hash ||= url.to_s.hash
        end

        private

        def uri
          @uri ||= URI::HTTPS.build(host:, path:).to_s
        end

        def host
          @host ||= developer_raw.host
        end

        def path
          @path ||= "#{developer_raw.path}/#{branch}/#{api_spec_file.relative_path}"
        end

        def api_spec_file
          @api_spec_file ||= APIPages::APISpecFile.new(
            site:,
            page_source_file: @page_relative_path,
            version: @version
          )
        end

        def developer_raw
          @developer_raw ||= URI.parse(site.config.dig('repos', 'developer_raw'))
        end

        def branch
          @branch ||= site.config['git_branch']
        end

        def insomnia_run
          @insomnia_run ||= URI.parse(site.config['insomnia_run'])
        end
      end
    end
  end
end
