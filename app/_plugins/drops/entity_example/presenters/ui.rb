# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module UI
          class Base < Presenters::Base
            def data
              @data ||= @example_drop.data
            end

            def template_file
              '/components/entity_example/format/ui.md'
            end
          end

          class Plugin < Base
          end

          class EventGatewayPolicy < Base
            def policy_type
              @policy_type ||= @example_drop.data['type']
            end
          end
        end
      end
    end
  end
end
