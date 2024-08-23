# frozen_string_literal: true

require_relative './base'
require_relative './target'

module Jekyll
  module EntityExampleBlock
    class Plugin < Base
      def target
        @target ||= Target.new(data: @data)
      end
    end
  end
end
