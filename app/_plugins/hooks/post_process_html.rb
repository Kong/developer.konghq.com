# frozen_string_literal: true

require 'nokogiri'

class AddLinksToHeadings # rubocop:disable Style/Documentation
  def initialize(page_or_doc)
    @page_or_doc = page_or_doc
  end

  def process # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    doc = Nokogiri::HTML(@page_or_doc.output)
    changes = false

    h2_id = nil
    h3_id = nil

    doc.css('h2, h3, h4, h5, h6').each do |heading|
      should_always_link = heading['class']&.split&.include?('always-link')

      next if heading.ancestors('.card').any? && !should_always_link
      next if heading.ancestors('.accordion-trigger').any?
      next unless heading['id']

      # handle new-in badge
      text = if @page_or_doc.url == '/mesh/changelog/'
               # special case, it has links in the headings
               heading.content.strip
             else
               text = heading.children.find(&:text?)&.text&.strip
               text = heading.content.strip if text.nil? || text.empty?
               text
             end
      old_id = heading['id']

      # Index pages have specific heading IDs to account for groups
      unless heading.attr('data-skip-process-heading-id') && heading.attr('data-skip-process-heading-id') == 'true'
        heading['id'] = Jekyll::Utils.slugify(text)
      end

      if ['/gateway/changelog/', '/operator/reference/custom-resources/'].include?(@page_or_doc.url)
        if heading.name == 'h2'
          h2_id = heading['id']
          h3_id = nil
        elsif heading.name == 'h3'
          h3_id = heading['id']
        end
        # Fix for gateway's changelog anchor links
        # All releases have the same entries
        heading['id'] = [h2_id, h3_id, heading['id']].compact.uniq.join('-')
      end

      # special case, it has links in the headings
      heading.content = heading.text if @page_or_doc.url == '/mesh/changelog/'

      toc_item = doc.at_css("#toc a[href='##{old_id}']")
      if toc_item
        toc_item['href'] = "##{heading['id']}"
        toc_item.content = text
      end

      anchor = Nokogiri::XML::Node.new('a', doc)
      anchor['href'] = "##{heading['id']}"
      anchor['aria-label'] = 'Anchor'
      anchor['title'] = text
      anchor['class'] =
        'flex items-center gap-2 link-anchor group w-full hover:no-underline text-primary'

      heading.children.each do |child|
        anchor.add_child(child)
      end

      span = Nokogiri::HTML::DocumentFragment.parse(
        <<-HTML
          <span class="text-brand hidden link-anchor-icon group-hover:flex">
            #{File.read('app/assets/icons/link.svg')}
          </span>
        HTML
      )

      anchor.add_child(span)

      changes = true
      heading.inner_html = anchor.to_s
    end

    doc.css('a').each do |link|
      href = link.attributes['href']&.value
      next unless href # No href, skip
      next unless href.start_with?('http') # Not an external link, skip

      changes = true

      link.set_attribute('target', '_blank')
      link.set_attribute('rel', "noopener nofollow noreferrer #{link.attributes['rel']&.value}")
    end

    @page_or_doc.output = doc.to_html if changes
  end
end

class KongPluginsMetaInjector
  def initialize(page_or_doc)
    @page_or_doc = page_or_doc
  end

  def process
    return unless should_inject?

    inject_meta_tag(build_meta_tag)
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

  def inject_meta_tag(meta_tag)
    doc = Nokogiri::HTML(@page_or_doc.output)
    head = doc.at_css('head')

    last_meta = head.css('meta').last

    if last_meta
      last_meta.add_next_sibling("\n  #{meta_tag}")
    else
      head.prepend_child("#{meta_tag}\n  ")
    end

    @page_or_doc.output = doc.to_html
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |page_or_doc|
  AddLinksToHeadings.new(page_or_doc).process
  KongPluginsMetaInjector.new(page_or_doc).process
end
