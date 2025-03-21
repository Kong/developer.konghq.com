# frozen_string_literal: true

module Jekyll
  module Drops
    module OAS
      class VersionsDropdown < Liquid::Drop
        class Option < Liquid::Drop
          attr_reader :version

          def initialize(base_url:, version:)
            @base_url = base_url
            @version  = version
          end

          def label
            @label ||= @version.to_s
          end

          def value
            @value ||= "#{@base_url}#{@version}/"
          end

          def id
            @id ||= @version.id
          end

          def as_json
            { 'value' => value, 'label' => label, 'id' => id }
          end
        end

        attr_reader :base_url

        def initialize(base_url:, product:)
          @base_url = base_url
          @product = product
        end

        def options
          @options ||= versions.sort.reverse.map do |version|
            Option.new(base_url:, version:)
          end
        end

        def versions
          @versions ||= @product.fetch('versions', []).map do |v|
            Version.new(v)
          end
        end

        def hash
          @hash ||= base_url.hash
        end

        def as_json
          options.map(&:as_json)
        end
      end
    end
  end
end
