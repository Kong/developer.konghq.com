# frozen_string_literal: true

require_relative '../../lib/site_accessor'
require_relative './tabular'

module Jekyll
  module Drops
    module Plugins
      class ReferenceableFields < Liquid::Drop # rubocop:disable Style/Documentation
        include Tabular

        def all(release:)
          site.data.fetch('kong_plugins').map do |_slug, plugin|
            new(release:, plugin:)
          end
        end

        def referenceable_fields
          @referenceable_fields ||= site.data.dig(
            'referenceable_fields',
            @release.number,
            @plugin['slug']
          )&.sort
        end

        def any?
          referenceable_fields&.any?
        end
      end
    end
  end
end
