# frozen_string_literal: true

module Jekyll
  module Drops
    module Plugins
      class AIGWPolicySchema < Liquid::Drop
        def initialize(hash)
          @hash = hash
        end

        def as_json(*)
          @hash
        end
      end
    end
  end
end
