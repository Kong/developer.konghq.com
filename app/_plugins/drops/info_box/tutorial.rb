# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module InfoBox
      class Tutorial < Base
        def template_file
          @template_file ||= File.expand_path('app/_includes/components/info_box/tutorial.html')
        end
      end
    end
  end
end
