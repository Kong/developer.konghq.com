# frozen_string_literal: true

require 'nokolexbor'
require 'cgi'

class AddLinksToHeadings # rubocop:disable Style/Documentation
  LINK_ICON_SVG = File.read('app/assets/icons/link.svg').freeze
  LINK_ICON_SPAN = <<~HTML.freeze
    <span class="hidden link-anchor-icon group-hover:flex">
            #{LINK_ICON_SVG.chomp}
          </span>
  HTML

  MESH_FLATTEN_URLS = ['/mesh/changelog/', '/mesh/version-specific-upgrade-notes/'].freeze
  COMPOUND_ID_URLS = ['/gateway/changelog/', '/ai-gateway/changelog/',
                      '/operator/reference/custom-resources/'].freeze
  HEADING_SELECTOR = 'h2, h3, h4, h5, h6'
  HEADING_XPATH = './/*[self::h2 or self::h3 or self::h4 or self::h5 or self::h6]'

  ANCHOR_CLASS = 'flex items-center gap-2 link-anchor group w-full hover:no-underline text-primary'

  def initialize(page_or_doc)
    @page_or_doc = page_or_doc
  end

  def process
    doc = Nokolexbor::DocumentFragment.parse(@page_or_doc.content)

    ops = collect_heading_ops(doc)

    if ops.empty?
      @page_or_doc.data['_needs_heading_output_pass'] = true
      return
    end

    content = @page_or_doc.content
    content = apply_heading_rewrites(content, ops)

    @page_or_doc.content = content
  end

  def process_output
    doc = Nokolexbor::DocumentFragment.parse(@page_or_doc.output)

    ops = collect_heading_ops(doc)
    return if ops.empty?

    output = @page_or_doc.output
    output = apply_heading_rewrites(output, ops)

    @page_or_doc.output = output
  end

  private

  def page_url
    @page_url ||= @page_or_doc.url
  end

  def mesh_flatten?
    return @mesh_flatten unless @mesh_flatten.nil?

    @mesh_flatten = MESH_FLATTEN_URLS.include?(page_url)
  end

  def compound_ids?
    return @compound_ids unless @compound_ids.nil?

    @compound_ids = COMPOUND_ID_URLS.include?(page_url)
  end

  def collect_heading_ops(doc)
    ops = []
    h2_id = nil
    h3_id = nil

    doc.xpath(HEADING_XPATH).each do |heading|
      next if skip_heading?(heading)

      old_id = heading['id']
      next unless old_id

      text = heading_text(heading)
      base_id = recompute_slug?(heading) ? Jekyll::Utils.slugify(text) : old_id

      if compound_ids?
        case heading.name
        when 'h2' then h2_id = base_id
                       h3_id = nil
        when 'h3' then h3_id = base_id
        end
        new_id = [h2_id, h3_id, base_id].compact.uniq.join('-')
      else
        new_id = base_id
      end

      inner = mesh_flatten? ? CGI.escapeHTML(heading.content) : heading.inner_html

      ops << { tag: heading.name, old_id: old_id, new_id: new_id, text: text, inner: inner }
    end

    ops
  end

  def skip_heading?(heading)
    always_link = heading['class']&.split&.include?('always-link')
    return true if !always_link && heading.ancestors('.card').any?
    return true if heading.ancestors('.accordion-trigger').any?
    return true if heading.css('a.link-anchor').any?

    false
  end

  def recompute_slug?(heading)
    heading['data-skip-process-heading-id'] != 'true'
  end

  def heading_text(heading)
    return heading.content.strip if mesh_flatten?

    dup = heading.dup
    dup.css('.new-in').each(&:remove)
    dup.content.strip
  end

  def apply_heading_rewrites(output, ops)
    ops.each do |op|
      pattern = %r{<#{op[:tag]}\b([^>]*\bid="#{Regexp.escape(op[:old_id])}"[^>]*)>(.*?)</#{op[:tag]}>}m
      output = output.gsub(pattern) do
        next Regexp.last_match(0) if Regexp.last_match(2).include?('link-anchor')

        attrs_without_id = Regexp.last_match(1).sub(/\s*id="[^"]*"/, '')
        build_heading_html(op, attrs_without_id)
      end
    end
    output
  end

  def build_heading_html(op, attrs)
    escaped_title = CGI.escapeHTML(op[:text])
    anchor = %(<a href="##{op[:new_id]}" aria-label="Anchor" title="#{escaped_title}" class="#{ANCHOR_CLASS}">) \
             "#{op[:inner]}#{LINK_ICON_SPAN}</a>"
    %(<#{op[:tag]} id="#{op[:new_id]}" data-toc-label="#{escaped_title}"#{attrs}>#{anchor}</#{op[:tag]}>)
  end

end

class KongPluginsMetaInjector
  def initialize(page_or_doc)
    @page_or_doc = page_or_doc
  end

  def process
    return unless should_inject?

    @page_or_doc.output = @page_or_doc.output.sub('</head>', "  #{build_meta_tag}\n</head>")
  end

  private

  def should_inject?
    kong_plugins&.any?
  end

  def kong_plugins
    @kong_plugins ||= @page_or_doc.data.fetch('kong_plugins', []).uniq
  end

  def build_meta_tag
    %(<meta name="algolia:kong_plugins" content="#{kong_plugins.join(', ')}">)
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_convert, priority: :low do |page_or_doc|
  AddLinksToHeadings.new(page_or_doc).process
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |page_or_doc|
  AddLinksToHeadings.new(page_or_doc).process_output if page_or_doc.data['_needs_heading_output_pass']
  KongPluginsMetaInjector.new(page_or_doc).process
end
