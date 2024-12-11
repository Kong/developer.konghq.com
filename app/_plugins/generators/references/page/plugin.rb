# frozen_string_literal: true

module Jekyll
  module ReferencePages
    module Page
      class Plugin < Base
        def data
          @data ||= super.merge(
            'schema' => schema.to_json,
            'compatible_protocols' => schema.compatible_protocols
          )
        end

        def schema
          @schema ||= @page.data['plugin'].schemas.detect { |s| s.release == @release }
        end
      end
    end
  end
end
