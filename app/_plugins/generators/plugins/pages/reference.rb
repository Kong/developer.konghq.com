# frozen_string_literal: true

require 'yaml'

module Jekyll
  module PluginPages
    module Pages
      class Reference < Base
        def url
          @url ||= "/plugins/#{@plugin.slug}/reference/"
        end

        def content
          ''
        end

        def data
          super
            .merge(metadata)
            .merge(
              'reference?' => true,
              'examples' => examples
            )
        end

        def metadata
          @metadata ||= YAML.load(File.read(file)) || {}
        end

        def file
          @file ||= File.join(@plugin.folder, 'reference.yaml')
        end

        def layout
          'plugins/reference'
        end

        def examples
          @examples ||= Dir.glob(File.join(@plugin.folder, 'examples', '*')).map do |e|
            Drops::PluginExample.new(example_file: e, plugin: @plugin, formats:)
          end
        end

        def formats
          # TODO: pull any extra formats from the metadata
          @formats ||= ['admin-api', 'konnect-api', 'deck', 'kic', 'terraform'].sort.map do |f|
            Jekyll::EntityExampleBlock::Format::Base.make_for(format: f)
          end
        end
      end
    end
  end
end
