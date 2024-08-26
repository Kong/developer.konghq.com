# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      class PluginTarget < Liquid::Drop
        def initialize(target:)
          @target = target
        end

        def key
          @key ||= @target.key
        end

        def value
          @value ||= @target.value
        end
      end
    end
  end
end
