# frozen_string_literal: true

module Jekyll
  module EditLink
    class Base
      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        @page.data['edit_link'] = edit_link
      end

      private

      def edit_link
        @edit_link ||= "#{repo_edit_url}/#{@page.relative_path}"
      end

      def repo_edit_url
        "#{@site.config['repos']['developer']}/edit/#{@site.config['git_branch']}/app"
      end
    end
  end
end