# frozen_string_literal: true

module Jekyll
  module SkillPages
    class Skill
      attr_reader :folder, :slug

      def initialize(folder:, slug:)
        @folder = folder
        @slug   = slug
      end

      def name
        @name ||= metadata.fetch('name', slug)
      end

      def description
        @description ||= metadata.fetch('description', '')
      end

      def version
        @version ||= metadata.dig('metadata', 'version')
      end

      def author
        @author ||= metadata.dig('metadata', 'author')
      end

      def license
        @license ||= metadata.fetch('license', nil)
      end

      def products
        @products ||= metadata.dig('metadata', 'products') || []
      end

      def license_file?
        return false unless license

        File.exist?(File.join(@folder, license))
      end

      def allowed_tools
        @allowed_tools ||= metadata.fetch('allowed-tools', nil)
      end

      def scripts?
        Dir.exist?(File.join(@folder, 'scripts'))
      end

      def references?
        Dir.exist?(File.join(@folder, 'references'))
      end

      def assets?
        Dir.exist?(File.join(@folder, 'assets'))
      end

      def content
        @content ||= parser.content
      end

      def processed_content
        @processed_content ||= Jekyll::SkillPages.demote_headings(content)
      end

      def metadata
        @metadata ||= parser.frontmatter
      end

      private

      def parser
        @parser ||= Jekyll::Utils::MarkdownParser.new(
          File.read(File.join(@folder, 'SKILL.md'))
        )
      end
    end
  end
end
