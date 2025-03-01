# frozen_string_literal: true

require 'uri'

class PruneNextStepsAndRelatedResources # rubocop:disable Style/Documentation
  def initialize(page_or_doc)
    @page_or_doc = page_or_doc
  end

  def process # rubocop:disable Metrics/AbcSize
    # Pages might have links to reference pages that don't exist
    # in their next_steps and related_resources, mostly reference pages
    # that might haven't been released yet.
    @page_or_doc.data.fetch('related_resources', []).delete_if do |link|
      validate_relative_url!(link['url'])

      link['url'].start_with?('/') && !relative_page_exist?(link['url'])
    end

    @page_or_doc.data.fetch('next_steps', []).delete_if do |link|
      validate_relative_url!(link['url'])

      link['url'].start_with?('/') && !relative_page_exist?(link['url'])
    end
  end

  private

  def relative_page_exist?(url)
    url = url.gsub(/\{\{\s*page\.release\s*\}\}/, release)

    # TODO: consider redirects in the future
    site.data['pages_urls'].include?(URI(url).path)
  end

  def site
    @site ||= @page_or_doc.site
  end

  def release
    @release ||= @page_or_doc.data['release'].to_s
  end

  def validate_relative_url!(path)
    uri = URI.parse(path)

    return unless uri.scheme.nil? && uri.host.nil?

    base_path = uri.path

    return if base_path.end_with?('/')

    raise ArgumentError, "Relative URL must end with a trailing slash: #{path} on page: #{@page_or_doc.url}"
  end
end

Jekyll::Hooks.register [:documents, :pages], :pre_render do |page_or_doc|
  PruneNextStepsAndRelatedResources.new(page_or_doc).process
end
