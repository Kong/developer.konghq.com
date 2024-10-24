# frozen_string_literal: true

require 'nokogiri'

class StripReleaseFromLinks
  def initialize(thing)
    @thing = thing
  end

  def process
    return unless @thing.data['content_type'] == 'reference' && @thing.url == @thing.data['base_url']

    doc = Nokogiri::HTML(@thing.output)
    changes = false
    release = @thing.data['release']['release']

    doc.css('a').each do |link|
      href = link['href']

      next unless href&.start_with?('/') && (href&.end_with?("/#{release}/") || href&.end_with?("/#{release}"))

      changes = true
      modified_href = href.sub(%r{/#{release}/?$}, '/')
      link['href'] = modified_href
    end

    @thing.output = doc.to_html if changes
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |thing|
  StripReleaseFromLinks.new(thing).process
end
