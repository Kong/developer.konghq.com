# frozen_string_literal: true

require 'nokogiri'

class StripReleaseFromLinks
  def initialize(page_or_doc)
    @page_or_doc = page_or_doc
  end

  def process # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return unless @page_or_doc.data['content_type'] == 'reference' && @page_or_doc.url == @page_or_doc.data['base_url']
    return if @page_or_doc.data['no_version']

    doc = Nokogiri::HTML(@page_or_doc.output)
    changes = false
    release = @page_or_doc.data['release']['release']

    doc.css('a').each do |link|
      href = link['href']

      next unless href&.start_with?('/') && (href&.end_with?("/#{release}/") || href&.end_with?("/#{release}"))

      changes = true
      modified_href = href.sub(%r{/#{release}/?$}, '/')
      link['href'] = modified_href
    end

    @page_or_doc.output = doc.to_html if changes
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |page_or_doc|
  StripReleaseFromLinks.new(page_or_doc).process
end
