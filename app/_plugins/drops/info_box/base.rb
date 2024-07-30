# frozen_string_literal: true

module Jekyll
  module Drops
    module InfoBox
      class Base < Liquid::Drop
        MAPPINGS = {
          'kong_plugins'     => 'Plugin',
          'gateway_entities' => 'EntityReference',
          'tutorials'        => 'Tutorial'
        }

        def self.make_for(page:)
          klass = MAPPINGS[page.collection]

          raise ArgumentError, "Unsupported info box type: #{page.collection}. Available types: #{MAPPINGS.keys.join(', ')}" unless klass

          Object.const_get("Jekyll::Drops::InfoBox::#{klass}").new(page:)
        end

        def initialize(page:)
          @page = page
        end

        def template_file
          raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
        end
      end
    end
  end
end
