# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module InfoBox
      class Plugin < Base
        def template_file
          @template_file ||= File.expand_path('app/_includes/components/info_box/plugin.html')
        end
      end
    end
  end
end
