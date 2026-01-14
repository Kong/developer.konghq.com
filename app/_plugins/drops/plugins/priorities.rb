# frozen_string_literal: true

require_relative '../../lib/site_accessor'
require_relative './tabular'

module Jekyll
  module Drops
    module Plugins
      class Priorities < Liquid::Drop # rubocop:disable Style/Documentation
        include Tabular

        def self.all(release:)
          super.sort_by do |r|
            if r.priority.nil?
              [1, r.title]
            else
              [0, -r.priority]
            end
            [r.priority.nil? ? 1 : 0, r.priority ? -r.priority : 0]
          end
        end

        def priority
          @priority ||= site.data.dig(
            'plugins',
            'priorities',
            @release.number.gsub('.', ''),
            @plugin.data['slug']
          )
        end

        def values
          @values ||= [priority || 'N/A']
        end
      end
    end
  end
end
