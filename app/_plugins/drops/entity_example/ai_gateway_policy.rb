# frozen_string_literal: true

require_relative 'base'

module Jekyll
  module Drops
    module EntityExample
      class AIGatewayPolicy < Base
        def entity_type
          @entity_type ||= 'policy'
        end

        def variables
          @variables ||= @example.raw_variables
        end

        def target
          @target ||= PluginTarget.new(
            target: OpenStruct.new(key: @options[:target], value: @options[:target])
          )
        end

        def data
          @data ||= @example.data.merge('global' => target.key == 'global')
        end

        def scope_note
          return nil if target.key == 'global'

          scope = scope_labels.fetch(target.key)
          "After creating the policy, add `#{@example.data['name']}` to the `policies` array of your [#{scope['label']}](#{scope['url']})."
        end

        private

        def scope_labels
          @scope_labels ||= Jekyll.sites.first.data.dig('entity_examples', 'config', 'ai_gateway_scopes')
        end
      end
    end
  end
end
