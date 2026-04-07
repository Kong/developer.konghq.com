# frozen_string_literal: true

module Jekyll
  module LearningPath
    class StepPage < Jekyll::Page # rubocop:disable Style/Documentation
      def initialize(site, step_data, path_data, position, series_id, overview_url) # rubocop:disable Lint/MissingSuper,Metrics/ParameterLists
        @site = site

        process('index.md')

        permalink = step_data.fetch('permalink')
        @dir = "#{@site.dest}#{permalink}"

        @content = ''
        # Merge path-level metadata so products/tags/min_version/personas are
        # available on the step page (needed for the info box).
        # Step-level how-to fields override path-level metadata when present.
        step_how_to_fields = step_data.slice('prereqs', 'cleanup', 'faqs', 'next_steps', 'works_on')

        @data = path_data.fetch('metadata', {}).merge(step_how_to_fields).merge(
          'title' => step_data['title'],
          'learn' => step_data['learn'],
          'practice' => step_data['practice'],
          'layout' => 'learning-path-step',
          'content_type' => 'learning_path_step',
          'breadcrumbs' => ['/learning-paths/', overview_url],
          # Use the standard series format expected by Jekyll::Data::Series.
          # The Series generator will populate series['items'] and set
          # page.data['navigation'] (prev/next) automatically.
          'series' => {
            'id' => series_id,
            'position' => position
          }
        )

        @relative_path = "_generated/learning-path-steps#{permalink}index.md"
      end

      def url
        @url ||= @dir.sub(@site.dest, '')
      end
    end
  end
end
