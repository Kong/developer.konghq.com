# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module KIC
          class Base < Presenters::Base
            def data
              @data ||= Utils::VariableReplacer::Data.run(
                data: @example_drop.data,
                variables: variables
              )
            end

            def custom_template
              p = "components/entity_example/format/snippets/kic/#{entity_type}.md"
              File.exist?(site.in_source_dir("_includes/#{p}")) ? p : nil
            end

            def template_file
              '/components/entity_example/format/kic.md'
            end

            def k8s_entity_type
              @k8s_entity_type ||= entity_type.split('_').map(&:capitalize).join
            end
          end

          class Plugin < Base
          end
        end
      end
    end
  end
end
