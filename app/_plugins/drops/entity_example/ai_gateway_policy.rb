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

        def attach_example
          return nil if target.key == 'global'

          @attach_example ||= AIGatewayPolicyAttachment.new(example: @example, target: target.key)
        end
      end
    end
  end
end
