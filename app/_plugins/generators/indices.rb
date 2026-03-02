# frozen_string_literal: true

module Jekyll
  class IndexGenerator < Jekyll::Generator
    priority :low

    def generate(site)
      return if site.config.dig('skip', 'indices')

      site.data['indices'] = {}
      Dir.glob(File.join(site.source, '_indices/**/*.yaml')).each do |file|
        index = YAML.load_file(file)

        index['groups'] = [{ 'sections' => index.delete('sections') }] if index['sections'] && !index['groups']

        index = normalize_paths(index)
        index = process_auto_exclude(index)

        page = build_page(site, file, index)
        site.pages << page
        slug = File.basename(file, File.extname(file))
        site.data['indices'][slug] = page
      end
    end

    def build_page(site, file, index)
      filename = File.basename(file).gsub('.yaml', '.html')
      filename = 'kubernetes-ingress-controller.html' if filename == 'kic.html'
      page = PageWithoutAFile.new(site, __dir__, 'index', filename)
      page.data['title'] = index['title']
      page.data['layout'] = 'indices'
      page.data['toc_depth'] = 3
      page.data['toc_skip_page_title'] = true
      page.data['description'] = index['description']
      page.data['slug'] = File.basename(file, File.extname(file))

      # Needed for edit link and site regeneration
      page.instance_variable_set(:@relative_path, "_indices/#{filename.gsub('.html', '.yaml')}")

      grouped_pages = config_to_grouped_pages(site, index)
      page.content = render(index, grouped_pages, site)
      page
    end

    def normalize_paths(index)
      index['groups'].each do |group|
        group['sections'].each do |section|
          section['items']&.each do |item|
            item['path'] = item['path'].to_s if item.is_a?(Hash) && item.key?('path')
          end
          section['not_match']&.each do |item|
            item['path'] = item['path'].to_s if item.is_a?(Hash) && item.key?('path')
          end
        end
      end
      index
    end

    def process_auto_exclude(index)
      all_sections = index['groups'].flat_map { |g| g['sections'] }

      index['groups'].each do |group|
        group['sections'].each do |section|
          next unless section['auto_exclude'] || section['auto_exclude_group']

          exclusions = if section['auto_exclude_group']
                         group['sections'].reject { |s| s.equal?(section) }.flat_map { |s| s['items'] || [] }
                       else
                         all_sections.reject { |s| s.equal?(section) }.flat_map { |s| s['items'] || [] }
                       end

          section['not_match'] ||= []
          section['not_match'] = (section['not_match'] + exclusions).uniq { |item| item['path'] }
        end
      end

      index
    end

    def config_to_grouped_pages(site, index)
      return [] unless index['groups']

      index['groups'].map do |group|
        @sections = {}
        seen = {}

        group['sections'].each do |section|
          @sections[section['title']] = {
            'pages' => []
          }.merge(section)
        end

        all = [].concat(site.pages, site.documents)
        all.each do |page|
          next if page.data['skip_index'] || page_is_versioned(page)

          group['sections'].each do |section|
            section['items'].each_with_index do |match, i|
              next unless match['path'] || match['type'] == 'how-to' || match['type'] == 'how-to-search' || match['url']

              if match['path']
                add_path(page, section['title'], match, section['not_match'], i, section['allow_duplicates'],
                         seen)
              end
              if match['type'] == 'how-to-search'
                add_how_to_search(site, section['title'], match, i, section['allow_duplicates'],
                                  seen)
              end
              if match['type'] == 'how-to'
                add_how_to(site, section['title'], match, i, section['allow_duplicates'],
                           seen)
              end
              add_entry(section['title'], match, i, section['allow_duplicates'], seen) if match['url']
            end
          end
        end

        sort_sections!

        # Remove the sections config so it doesn't overwrite
        # the grouped pages
        group.delete('sections') || {}

        # Merge everything together
        {
          'sections' => @sections.values
        }.merge(group)
      end
    end

    def page_is_versioned(page)
      page.data['releases'] && !page.data['releases'].empty? && !page.data['canonical?']
    end

    def add_entry(title, page, match_index, allow_duplicates, seen)
      url = page.respond_to?(:url) ? page.url : page['url']
      return if seen[url] && !allow_duplicates

      @sections[title]['pages'] << {
        'page' => page,
        'match_index' => match_index
      }
      seen[url] = true
    end

    def add_path(page, section, match, not_match, match_index, allow_duplicates, seen)
      return unless File.fnmatch(match['path'], page.url, ::File::FNM_PATHNAME)

      should_match = !not_match || not_match.none? do |nm|
        next unless nm['path']

        r = File.fnmatch(nm['path'], page.url, ::File::FNM_PATHNAME)
        r
      end

      return unless should_match

      add_entry(section, page, match_index, allow_duplicates, seen)
    end

    # Supports tags, products, tools and plugins in the search config
    def add_how_to_search(site, section, match, match_index, allow_duplicates, seen)
      search = {
        'title' => match['title'],
        'description' => match['description'],
        'url' => how_to_search_link(match)
      }
      add_entry(section, search, match_index, allow_duplicates, seen)
    end

    def how_to_search_link(config)
      config = config.slice('products', 'tags', 'tools', 'plugins')
      query_string = URI.encode_www_form(config)
      url_segment = '/how-to'
      raise "No search URL found in config: #{config} - '#{query_string}'" if query_string.empty?

      "#{url_segment}?#{query_string}"
    end

    def add_how_to(site, section, match, match_index, allow_duplicates, seen)
      how_tos = fetch_how_tos(site, match)
      how_tos.each do |how_to|
        add_entry(section, how_to, match_index, allow_duplicates, seen)
      end
    end

    def fetch_how_tos(site, match)
      site.collections['how-tos'].docs.select do |t|
        match_criteria(t.data, match)
      end
    end

    def sort_sections!
      @sections.each_key do |title|
        @sections[title]['pages'] = @sections[title]['pages'].sort_by! do |p|
          entry = p['page'] || {}
          [
            p['match_index'],
            entry.respond_to?(:data) ? entry.data['weight'] : entry['weight'],
            entry.respond_to?(:data) ? entry.data['title']&.downcase : entry['title']&.downcase
          ]
        end

        @sections[title]['pages'] = @sections[title]['pages'].map { |p| p['page'] || p }.uniq
      end
    end

    private

    def match_criteria(data, match)
      %w[tags products tools plugins].all? do |key|
        !match.key?(key) || data.fetch(key, []).intersect?(match[key])
      end
    end

    def template
      @template ||= File.read(File.expand_path('app/_includes/indices.html'))
    end

    def render(index, groups, site)
      context = {
        'index' => index,
        'groups' => groups,
        'site' => site.config
      }
      Liquid::Template.parse(template, { line_numbers: true }).render(context, registers: { site: site })
    end
  end
end
