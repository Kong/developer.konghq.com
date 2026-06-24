# frozen_string_literal: true

class StripReleaseFromLinks
  def initialize(page_or_doc)
    @page_or_doc = page_or_doc
  end

  def process
    return unless applicable?

    release = @page_or_doc.data['release']['release']
    pattern = %r{href="(/[^"]*)/#{Regexp.escape(release)}/?"}
    @page_or_doc.output = @page_or_doc.output.gsub(pattern, 'href="\1/"')
  end

  private

  def applicable?
    @page_or_doc.data['content_type'] == 'reference' &&
      @page_or_doc.url == @page_or_doc.data['base_url'] &&
      @page_or_doc.data['versioned']
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |page_or_doc|
  StripReleaseFromLinks.new(page_or_doc).process
end
