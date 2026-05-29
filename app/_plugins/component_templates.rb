# frozen_string_literal: true

module Jekyll
  module ComponentTemplates
    PATH = 'app/_includes/components'
    EXTENSIONS = { 'markdown' => 'md' }.freeze
    DEFAULT_EXTENSION = 'html'

    @cache = {}

    def self.fetch(name, format, base: PATH)
      ext = EXTENSIONS.fetch(format, DEFAULT_EXTENSION)
      @cache[[name, ext, base]] ||= Liquid::Template.parse(
        File.read(File.expand_path("#{base}/#{name}.#{ext}")),
        { line_numbers: true }
      )
    end
  end
end
