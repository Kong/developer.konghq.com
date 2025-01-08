# frozen_string_literal: true

require 'json'
require_relative './tabular'
require_relative '../../lib/site_accessor'

module Jekyll
  module Drops
    module Plugins
      class Scope < Liquid::Drop
        include Tabular

        def columns
          @columns ||= site.data.dig('plugins', 'tables', 'scopes', 'columns').map do |c|
            c.fetch('key')
          end
        end

        def value(field)
          if field == 'global'
            true
          else
            !!json_schema.dig('properties', field)
          end
        end
      end
    end
  end
end
