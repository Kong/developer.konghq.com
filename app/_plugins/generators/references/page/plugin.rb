# frozen_string_literal: true

module Jekyll
  module ReferencePages
    module Page
      class Plugin < Base # rubocop:disable Style/Documentation
        def data
          @data ||= begin
            data = super.merge('schema' => schema)
            if @page.data['products'].include?('gateway')
              data.merge!('compatible_protocols' => schema.compatible_protocols)
            end
            data
          end
        end

        def schema
          @schema ||= @page.data['plugin'].schemas.detect { |s| s.release == @release }
        end
      end
    end
  end
end
