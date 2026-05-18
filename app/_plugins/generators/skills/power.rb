# frozen_string_literal: true

module Jekyll
  module SkillPages
    class Power
      attr_reader :site, :file

      def initialize(site:, file:)
        @site = site
        @file = file
      end

      def name
        @name ||= nonblank(metadata['name']) || nonblank(metadata['title']) || heading || 'Kong Power'
      end

      def description
        @description ||= nonblank(metadata['description']) || first_paragraph || default_description
      end

      def badge_text
        @badge_text ||= nonblank(metadata['badge']) || inferred_badge_text
      end

      def host_name
        @host_name ||= nonblank(metadata['host']) || nonblank(metadata['install_target']) || inferred_host_name
      end

      def icon
        @icon ||= begin
          custom_icon = nonblank(metadata['icon'])

          if custom_icon&.start_with?('/', 'http://', 'https://', 'data:')
            custom_icon
          elsif custom_icon&.include?('/') || custom_icon&.include?('.')
            "/assets/icons/#{custom_icon}"
          elsif custom_icon
            "/assets/icons/#{custom_icon}.svg"
          elsif inferred_text.include?('kiro') || inferred_text.include?('aws')
            '/assets/icons/aws.svg'
          else
            '/assets/icons/sparkle.svg'
          end
        end
      end

      def source_path
        'POWER.md'
      end

      def source_url
        @source_url ||= Jekyll::SkillPages.repo_blob_url(site, source_path)
      end

      def learn_more_url
        @learn_more_url ||= nonblank(metadata['learn_more_url']) || nonblank(metadata['url'])
      end

      def to_data
        {
          'name' => name,
          'description' => description,
          'badge_text' => badge_text,
          'host_name' => host_name,
          'icon' => icon,
          'source_path' => source_path,
          'source_url' => source_url,
          'learn_more_url' => learn_more_url
        }
      end

      private

      def metadata
        @metadata ||= parser.frontmatter
      end

      def raw_content
        @raw_content ||= File.read(file)
      end

      def content
        @content ||= parser.content
      end

      def parser
        @parser ||= Jekyll::Utils::MarkdownParser.new(raw_content)
      end

      def heading
        @heading ||= raw_content.lines.filter_map do |line|
          line.match(/^#\s+(.+)/)&.captures&.first&.strip
        end.first
      end

      def first_paragraph
        @first_paragraph ||= content.split(/\n{2,}/)
                                    .map { |block| clean_markdown(block) }
                                    .find(&:itself)
      end

      def clean_markdown(block)
        cleaned = block.to_s.strip
        return if cleaned.empty?
        return if cleaned.start_with?('#', '```', '|', '- ', '* ')

        cleaned.gsub!(/!\[([^\]]*)\]\([^)]+\)/, '\1')
        cleaned.gsub!(/\[([^\]]+)\]\([^)]+\)/, '\1')
        cleaned.gsub!(/[`*_>#]/, '')
        cleaned.gsub!(/\s+/, ' ')

        normalized = cleaned.strip
        normalized.empty? ? nil : normalized
      end

      def inferred_text
        @inferred_text ||= [name, description, content].compact.join(' ').downcase
      end

      def inferred_host_name
        return 'Kiro' if inferred_text.include?('kiro')
        return 'AWS' if inferred_text.include?('aws')

        nil
      end

      def inferred_badge_text
        return "#{host_name} Power available" if host_name

        'Power install available'
      end

      def default_description
        'Install the Kong marketplace as a Power while reusing the same skills and MCP wiring.'
      end

      def nonblank(value)
        normalized = value.to_s.strip
        normalized.empty? ? nil : normalized
      end
    end
  end
end
