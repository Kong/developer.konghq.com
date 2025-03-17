# frozen_string_literal: true

require_relative '../../lib/site_accessor'
require_relative './tabular'

module Jekyll
  module Drops
    module Plugins
      class ReferenceableFields < Liquid::Drop # rubocop:disable Style/Documentation
        include Tabular

        def values
          @values ||= site.data.dig(
            'referenceable_fields',
            @release.number,
            @plugin['slug']
          )&.sort
        end

        def any?
          values&.any?
        end
      end
    end
  end
end
