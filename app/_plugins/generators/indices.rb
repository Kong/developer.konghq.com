# frozen_string_literal: true

module Jekyll
  class IndexGenerator < Jekyll::Generator
    priority :low

    def generate(site)
      Dir.glob(File.join(site.source, '_indices/**/*.yaml')).each do |file|
        @seen = {}
        @sections = {}
        site.pages << build_page(site, file)
      end
      
    end

    def build_page(site, file)
      filename = File.basename(file).gsub('.yaml', '.html')
      page = PageWithoutAFile.new(site, __dir__, 'index', filename)

      # load yaml
      index = YAML.load_file(file)

      index = process_auto_exclude(index)

      page.data['title'] = index['title']
      page.data['layout'] = 'indices'
      page.content = render(index, config_to_grouped_pages(site, index))
      page
    end

    def process_auto_exclude(index)
      index['sections'].each do |section|
        section['items'] ||= []
        section['not_match'] ||= []

        next unless section['auto_exclude']

        index['sections'].each do |other|
          next if section['title'] == other['title']

          # If we have a block containing /foo/**/*
          # And use auto_exclude on a sub-path, nothing will be included
          # so we have to add a negative matcher here too
          not_match = other['items'].reject do |match|
            section['auto_exclude_except']&.any? do |a|
              a == match
            end
          end

          section['not_match'] = section['not_match'].concat(not_match)
        end
      end

      index
    end

    def add_entry(title, page, match_index)
      url = page.respond_to?(:url) ? page.url : page['url']

      return if @seen[url]

      @sections[title]['pages'] << {
        'page' => page,
        'match_index' => match_index
      }

      @seen[url] = true
    end

    def config_to_grouped_pages(site, index)
      # Initialize the sections
      index['sections'].each do |section|
        @sections[section['title']] = {
          'title' => section['title'],
          'pages' => []
        }
      end

      all = [].concat(site.pages, site.documents)
      all.each do |page|
        # Some pages are not meant to be in the index
        # These are usually the /index.md page for folders that serve as an index themselves
        next if page.data['skip_index']

        # Take only the latest versioned page
        next if page_is_versioned(page)

        index['sections'].each do |section|
          section['items'].each_with_index do |match, i|
            # It's a path
            next add_path(page, section['title'], match, section['not_match'], i) if match['path']

            # How-To Lookup
            next add_how_to(site, section['title'], match, i) if match['type'] == 'how-to'

            # Or a hardcoded page
            next add_entry(section['title'], match, i) if match['url']

            raise "Unknown match type: #{match}"
          end
        end
      end

      sort_sections!

      @sections.values
    end

    def page_is_versioned(page)
      page.data['releases'] && !page.data['releases'].empty? && !page.data['canonical?']
    end

    def add_path(page, section, match, not_match, match_index)
      return unless File.fnmatch(match['path'], page.url, ::File::FNM_PATHNAME)

      should_match = not_match&.none? do |nm|
        next unless nm['path']

        File.fnmatch(nm['path'], page.url, ::File::FNM_PATHNAME)
      end

      return unless should_match

      add_entry(section, page, match_index)
    end

    def add_how_to(site, section, match, match_index)
      how_tos = fetch_how_tos(site, match)

      how_tos.each do |how_to|
        add_entry(section, how_to, match_index)
      end
    end

    def sort_sections!
      @sections.each_key do |title|
        @sections[title]['pages'] = @sections[title]['pages'].sort_by! do |p|
          entry = p['page']

          # Handle explicit page definitions where there is no `page` key
          entry = {} if entry.nil?
          [
            # Sort by position in section map
            p['match_index'],
            # By explicit weight
            entry.respond_to?(:data) ? entry.data['weight'] : entry['weight'],
            # By title
            entry.respond_to?(:data) ? entry.data['title'].downcase : entry['title']&.downcase
          ]
        end

        # Remove the match index
        @sections[title]['pages'] = @sections[title]['pages'].map { |p| p['page'] ? p['page'] : p }.uniq
      end
    end

    def fetch_how_tos(site, match)
      site.collections['how-tos'].docs.select do |t|
        match_criteria(t.data, match)
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

    def render(index, groups)
      context = {
        'index' => index,
        'groups' => groups,
      }
      Liquid::Template.parse(template).render(context)
    end
  end
end
