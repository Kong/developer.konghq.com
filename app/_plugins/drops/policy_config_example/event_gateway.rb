# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module PolicyConfigExample
      class EventGateway < Base
        def examples
          @examples ||= targets.map do |target|
            EntityExample::EventGatewayPolicy.new(example: self, target:)
          end
        end

        def variables
          @variables ||= example.fetch('variables', {})
        end

        def data
          @data ||= {
            'name' => example.fetch('name'),
            'type' => @plugin.slug,
            'config' => config
          }
        end

        def targets
          @targets ||= if example.key?('phases')
                         unless example['phases'].all? { |p| @plugin.phases.include?(p) }
                           raise ArgumentError,
                                 "Invalid `phases` in #{@file}, supported phases: #{@plugin.phases.join(', ')}"
                         end
                         example.fetch('phases')
                       else
                         @plugin.phases
                       end
        end
      end
    end
  end
end
