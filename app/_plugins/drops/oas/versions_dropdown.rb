# frozen_string_literal: true

module Jekyll
  module Drops
    module OAS
      class VersionsDropdown < Liquid::Drop
        class Option < Liquid::Drop
          attr_reader :version

          def initialize(base_url:, version:, latest:)
            @base_url = base_url
            @version  = version
            @latest = latest
          end

          def value
            @value ||= @version.to_s
          end

          def url
            @url ||= if @version == @latest
                       @base_url
                     else
                       "#{@base_url}#{value}/"
                     end
          end
        end

        attr_reader :base_url

        def initialize(base_url:, product:)
          @base_url = base_url
          @product = product
        end

        def options
          @options ||= versions.sort.reverse.map do |version|
            Option.new(base_url:, version:, latest:)
          end
        end

        def versions
          @versions ||= @product.fetch('versions', []).map do |v|
            Version.new(v)
          end
        end

        def latest
          @latest ||= Version.new(@product.fetch('latestVersion'))
        end

        def hash
          @hash ||= base_url.hash
        end
      end
    end
  end
end
