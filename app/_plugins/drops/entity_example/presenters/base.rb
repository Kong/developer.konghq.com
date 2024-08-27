# frozen_string_literal: true

require_relative '../utils/variable_replacer'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        class Base < Liquid::Drop
          def initialize(example_drop:)
            @example_drop = example_drop
          end

          def entity_type
            @entity_type ||= @example_drop.entity_type
          end

          def variables
            @variables ||= @example_drop.variables
          end

          private

          def site
            @site ||= Jekyll.sites.first
          end

          def entity_examples_config
            @entity_examples_config ||= site.data['entity_examples']['config']
          end

          def formats
            @formats ||= entity_examples_config['formats']
          end

          def targets
            @targets ||= entity_examples_config['targets']
          end
        end
      end
    end
  end
end
