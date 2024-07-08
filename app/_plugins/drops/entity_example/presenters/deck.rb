# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module Deck
          class Base < Liquid::Drop
            def initialize(target:, data:, entity_type:)
              @target      = target
              @data        = data
              @entity_type = entity_type
            end

            def entity
              @entity ||= "#{@entity_type}s"
            end

            def data
              YAML.dump(@data).delete_prefix("---\n")
            end
          end

          class Plugin < Base
            TARGETS = {
              'consumer'       => 'CONSUMER_NAME|ID',
              'consumer_group' => 'CONSUMER_GROUP_NAME|ID',
              'global'         => nil,
              'route'          => 'ROUTE_NAME|ID',
              'service'        => 'SERVICE_NAME|ID'
            }.freeze

            def data
              YAML.dump(
                {
                  'name' => @data.fetch('name'),
                  @target => TARGETS.fetch(@target)
                }.merge('config' => @data.fetch('config'))
              ).delete_prefix("---\n")
            end
          end
        end
      end
    end
  end
end
