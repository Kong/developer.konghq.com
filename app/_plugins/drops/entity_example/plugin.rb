# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      class Plugin < Base
        def target
          @target ||= PluginTarget.new(target: @example.target)
        end
      end
    end
  end
end
