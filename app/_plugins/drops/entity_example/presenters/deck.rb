# frozen_string_literal: true

require 'yaml'
require_relative '../utils/variable_replacer'
require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Deck
          class Base < Presenters::Base
            def entity
              @entity ||= "#{@example_drop.entity_type}s"
            end

            def data
              @data ||= @example_drop.data
            end

            def config
              @config ||= Jekyll::Utils::HashToYAML.new(
                { entity => [ data ] }
              ).convert
            end

            def template_file
              '/components/entity_example/format/deck.md'
            end

            def missing_variables
              @missing_variables ||= []
            end
          end

          class Plugin < Base
            def config
              plugin = { 'name' => @example_drop.data.fetch('name') }
              plugin.merge!(target.key => target_value) if target.key != 'global'
              plugin.merge!('config' => @example_drop.data.fetch('config'))

              Jekyll::Utils::HashToYAML.new({ 'plugins' => [plugin] }).convert
            end

            def target
              @target ||= @example_drop.target
            end

            def variables
              super.merge(@example_drop.target.key => target_value)
            end

            def missing_variables
              return [] if @example_drop.target.key == 'global'

              @missing_variables ||= [formats['deck']['variables'][@example_drop.target.key]]
            end

            def target_value
              @target_value ||= target.value || formats['deck']['variables'][target.key]['placeholder']
            end
          end
        end
      end
    end
  end
end
