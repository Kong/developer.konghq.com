# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      class EventGatewayPolicy < Base
        extend Forwardable

        def_delegators :@example, :policy_target

        def entity_type
          @entity_type ||= 'event_gateway_policy'
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
          @data ||= begin
            data = @example.data
            data.delete('config') if data['config'].nil? || data['config'].empty?
            data
          end
        end

        def ordering
          @ordering ||= @example.ordering
        end
      end
    end
  end
end
