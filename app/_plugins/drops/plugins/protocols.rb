# frozen_string_literal: true

require 'json'
require_relative './tabular'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module Plugins
      class Protocol < Liquid::Drop
        include Tabular

        def columns
          @columns ||= site.data.dig('plugins', 'tables', 'protocols', 'columns').map do |c|
            c.fetch('key')
          end
        end

        def value(protocol)
          !!json_schema.dig('properties', 'protocols', 'items', 'enum').include?(protocol)
        end
      end
    end
  end
end
