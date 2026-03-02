# frozen_string_literal: true

NO_MATCH = 'NO DATA'
module Jekyll
  class TagExplorer < Jekyll::Generator
    priority :lowest
    def generate(site)
      return if Jekyll.env == 'production'
      return if site.config.dig('skip', 'explorer')

      jobs = [
        {
          'type' => 'product',
          'items' => fetch_products(site),
          'match_key' => 'products',
          'group_by' => 'tags',
          'group_by_type' => 'list',
          'columns' => ['tags']
        },
        {
          'type' => 'tag',
          'items' => fetch_tags(site),
          'match_key' => 'tags',
          'group_by' => 'products',
          'group_by_type' => 'list',
          'columns' => %w[products tags]
        }
      ]

      jobs.each do |job|
        job['items'].each do |item|
          @groups = {}

          build_groups(site, job, item)

          groups = @groups.values.sort_by { |g| g['title'] }

          content = render(item, groups, job)
          site.pages << make_item_page(site, job['type'], item, content)
        end
        site.pages << make_type_index_page(site, job)
      end
      site.pages << make_explorer_index_page(site, jobs)
    end

    def fetch_products(site)
      Dir.glob(File.join(site.source, '_data/products/*.yml')).map do |file|
        File.basename(file).gsub('.yml', '')
      end
    end

    def all_site_pages(site)
      [].concat(site.pages).concat(site.documents)
    end

    def fetch_tags(site)
      all_site_pages(site).flat_map do |p|
        p.data['tags'] || []
      end.uniq
    end

    def build_groups(site, job, item)
      all_site_pages(site).each do |page|
        next if should_skip?(job, item, page)

        match_key = job['match_key']
        next unless page.data[match_key]&.include?(item)

        group_by = job['group_by']
        group_name = page.data[group_by]
        group_name = group_name&.first if job['group_by_type'] == 'list'

        group_name = NO_MATCH if group_name.nil?

        add_entry(group_name, page)
      end
    end

    # Output
    def template
      @template ||= File.read(File.expand_path('app/_includes/explorer.html'))
    end

    def render(item, groups, job)
      context = {
        'index' => {
          'title' => "Exploring the '#{item}' #{job['type']}"
        },
        'type' => job['type'],
        'groups' => groups,
        'group_by' => job['group_by'],
        'columns' => job['columns']
      }
      Liquid::Template.parse(template, { line_numbers: true }).render(context)
    end

    def render_list(title, prefix, items)
      # Sort items by key
      items = items.sort_by { |item, _c| item.downcase }

      content = items.uniq.map do |item, c|
        "<li><a href=\"/_explorer/#{prefix}#{item}/\">#{item} #{c ? "(#{c})" : ''}</a></li>"
      end.join("\n")
      "<h1>#{title}</h1> <ul>\n#{content}\n</ul>"
    end

    # Methods to create pages
    def make_item_page(site, type, name, content)
      page = PageWithoutAFile.new(site, __dir__, "_explorer/#{type}", "#{name}.html")

      page.data['title'] = "#{type} Explorer"
      page.data['layout'] = 'indices'
      page.content = content
      page
    end

    def make_type_index_page(site, job)
      type = job['type']
      page = PageWithoutAFile.new(site, __dir__, '_explorer/', "#{type}.html")

      # Augment items with the count
      counts = {}
      job['items'].each do |item|
        counts[item] = 0
      end
      all_site_pages(site).each do |p|
        job['items'].each do |item|
          next if should_skip?(job, item, p)

          match_key = job['match_key']
          next unless p.data[match_key]&.include?(item)

          counts[item] += 1
        end
      end

      job['items'].map do |item|
        "#{item} (#{counts[item]})"
      end

      page.data['title'] = "#{type.titlecase} Explorer Index"
      page.data['layout'] = 'indices'
      page.content = render_list("#{type.titlecase} Index", "#{type}/", counts)

      page
    end

    def make_explorer_index_page(site, jobs)
      page = PageWithoutAFile.new(site, __dir__, '', '_explorer.html')

      page.data['title'] = 'Explorer Index'
      page.data['layout'] = 'indices'
      page.content = render_list('Explorer Index', '', jobs.map { |job| job['type'] })

      page
    end

    def add_entry(title, page, meta = {})
      page.respond_to?(:url) ? page.url : page['url']

      if @groups[title].nil?
        @groups[title] = {
          'title' => title,
          'pages' => []
        }.merge(meta)
      end

      @groups[title]['pages'] << page.clone
    end

    private

    def should_skip?(job, item, page)
      return true if job['type'] == 'product' && !page.data['products']&.include?(item)
      return true if page_is_versioned?(page)
      return true if page.data['content_type'] == 'plugin_example'
      return true if page.url.start_with?('/plugins/') && page.url.split('/').size > 3

      false
    end

    def page_is_versioned?(page)
      page.data['releases'] && !page.data['releases'].empty? && !page.data['canonical?']
    end
  end
end
