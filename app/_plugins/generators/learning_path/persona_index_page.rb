# frozen_string_literal: true

module Jekyll
  module LearningPath
    class PersonaIndexPage < Jekyll::Page # rubocop:disable Style/Documentation
      def initialize(site, persona_id, learning_paths) # rubocop:disable Lint/MissingSuper
        @site = site

        process('index.md')

        @dir = "#{@site.dest}/learning-paths/personas/#{persona_id}/"

        @content = ''
        @data = {
          'layout' => 'learning-path-index',
          'title' => "#{persona_display_name(site, persona_id)} Learning Paths",
          'persona' => persona_id,
          'breadcrumbs' => ['/learning-paths/', '/learning-paths/personas/'],
          'learning_paths' => serialize_paths(learning_paths)
        }

        @relative_path = "_generated/learning-paths/personas/#{persona_id}/index.md"
      end

      def url
        @url ||= "/learning-paths/personas/#{@data['persona']}/"
      end

      private

      def persona_display_name(site, persona_id)
        persona = Array(site.data['personas']).find { |p| p['id'] == persona_id }
        persona&.fetch('name', nil) || persona_id.split('-').map(&:capitalize).join(' ')
      end

      def serialize_paths(learning_paths)
        learning_paths.map do |lp|
          {
            'title' => lp.data['title'],
            'description' => lp.data['description'],
            'url' => lp.url,
            'tags' => lp.data['tags'] || [],
            'products' => lp.data['products'] || []
          }
        end
      end
    end
  end
end
