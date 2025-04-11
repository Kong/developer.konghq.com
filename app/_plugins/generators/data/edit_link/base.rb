# frozen_string_literal: true

module Jekyll
  module Data
    module EditLink
      class Base # rubocop:disable Style/Documentation
        def initialize(site:, page:)
          @site = site
          @page = page
        end

        def process
          return if @page.data['edit_link']

          @page.data['edit_link'] = edit_link
        end

        private

        def edit_link
          return if @page.data['content_type'] == 'policy'

          "#{repo_edit_url}/#{@page.relative_path}"
        end

        def repo_edit_url
          "#{@site.config['repos']['developer']}/edit/#{@site.config['git_branch']}/app"
        end
      end
    end
  end
end
