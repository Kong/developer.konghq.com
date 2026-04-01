# frozen_string_literal: true

require 'yaml'
require_relative '../utils/variable_replacer'
require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Deck
          class Base < Presenters::Base # rubocop:disable Style/Documentation
            def entity
              @entity ||= if @example_drop.entity_type == 'target'
                            'upstreams'
                          elsif @example_drop.entity_type == 'sni'
                            'certificates'
                          else
                            "#{@example_drop.entity_type}s"
                          end
            end

            def data
              @data ||= Utils::VariableReplacer::DeckData.run(
                data: _data,
                variables: variables
              )
            end

            def config
              @config ||= Jekyll::Utils::HashToYAML.new(
                { entity => [data] }
              ).convert
            end

            def template_file
              '/components/entity_example/format/deck.md'
            end

            def missing_variables
              @missing_variables ||= []
            end

            private

            def _data
              if @example_drop.entity_type == 'target'
                { 'name' => 'example_upstream', 'targets' => [@example_drop.data] }
              elsif @example_drop.entity_type == 'sni'
                { 'id' => @example_drop.data.dig('certificate', 'id'),
                  'cert' => "-----BEGIN CERTIFICATE-----\n-----END CERTIFICATE-----",
                  'key' => "-----BEGIN RSA PRIVATE KEY-----\n-----END RSA PRIVATE KEY",
                  'snis' => [@example_drop.data.except('certificate')] }
              else
                @example_drop.data
              end
            end
          end

          class Plugin < Base # rubocop:disable Style/Documentation
            def config
              plugin = { 'name' => @example_drop.data.fetch('name') }
              plugin.merge!(target.key => target_value) if target.key != 'global'
              plugin.merge!('partials' => partials) unless partials.empty?
              plugin.merge!('tags' => @example_drop.tags) unless @example_drop.tags.empty?
              config_field = @example_drop.data.fetch('config', {})
              plugin.merge!('config' => config_field) unless config_field.empty?
              plugin.merge!('ordering' => ordering) unless ordering.nil?

              plugin = Utils::VariableReplacer::DeckData.run(
                data: plugin,
                variables:
              )

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

              @missing_variables ||= [formats['deck']['variables'][target.key]]
            end

            def ordering
              return nil unless @example_drop.ordering

              @example_drop.ordering
            end

            def target_value
              @target_value ||= if target.key == 'global'
                                  nil
                                else
                                  target.value || formats['deck']['variables'][target.key]['placeholder']
                                end
            end

            def partials
              @partials ||= @example_drop.data.fetch('partials', [])
            end
          end
        end
      end
    end
  end
end
