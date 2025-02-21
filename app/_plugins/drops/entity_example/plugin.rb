# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      class Plugin < Base # rubocop:disable Style/Documentation
        def target
          @target ||= PluginTarget.new(target: @example.target)
        end

        def data
          @data ||= begin
            data = @example.data
            data.delete('config') if data['config'].nil? || data['config'].empty?
            data
          end
        end
      end
    end
  end
end
