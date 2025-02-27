# frozen_string_literal: true

module Jekyll
  class IndexGenerator < Jekyll::Generator
    priority :low

    def generate(site)
      @seen = {}
      Dir.glob(File.join(site.source, '_indices/**/*.yaml')).each do |file|
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
        section['match'] ||= []
        section['not_match'] ||= []

        next unless section['auto_exclude']

        index['sections'].each do |other|
          next if section['title'] == other['title']

          # If we have a block containing /foo/**/*
          # And use auto_exclude on a sub-path, nothing will be included
          # so we have to add a negative matcher here too
          not_match = other['match'].reject do |match|
            section['auto_exclude_except']&.any? do |a|
              a == match
            end
          end

          section['not_match'] = section['not_match'].concat(not_match)
        end
      end

      index
    end

    def config_to_grouped_pages(site, index)
      sections = {}

      index['sections'].each do |section|
        sections[section['title']] = {
          'title' => section['title'],
          'pages' => []
        }
      end

      site.pages.each do |page|
        next if page.data['skip_index']

        # Take only the latest versioned page
        next if page.data['releases'] && !page.data['releases'].empty? && !page.data['canonical?']

        index['sections'].each do |section|
          section['match'].each_with_index do |match, i|
            # Add support for arbitrary pages in an index file
            if match.is_a?(Hash)

              # How-To Lookup
              if match['type'] == 'how-to'
                how_tos = site.collections['how-tos'].docs.each_with_object([]) do |t, result|
                  has_match = (!match.key?('tags') || t.data.fetch('tags', []).intersect?(match['tags'])) &&
                          (!match.key?('products') || t.data.fetch('products', []).intersect?(match['products'])) &&
                          (!match.key?('tools') || t.data.fetch('tools', []).intersect?(match['tools'])) &&
                          (!match.key?('plugins') || t.data.fetch('plugins', []).intersect?(match['plugins']))
                  result << t if has_match
                end

                how_tos.each do |how_to|
                  next if @seen[how_to.url]
                  sections[section['title']]['pages'] << {
                    'page' => how_to,
                    'match_index' => i
                  }
                  @seen[how_to.url] = true
                end
              else
                # Or a hardcoded page
                next if @seen[match.url]
                sections[section['title']]['pages'] << {
                  'page' => match,
                  'match_index' => i
                }
                @seen[match.url] = true
              end
              next
            else
              next unless File.fnmatch(match, page.url, ::File::FNM_PATHNAME)

              should_match = !section['not_match']&.any? do |not_match|
                next unless not_match.is_a?(String)
                File.fnmatch(not_match, page.url, ::File::FNM_PATHNAME)
              end


              next unless should_match

              next if @seen[page.url]
              sections[section['title']]['pages'] << {
                'page' => page,
                'match_index' => i
              }
              @seen[page.url] = true
            end
          end
        end
      end

      sections.each_key do |title|
        sections[title]['pages'] = sections[title]['pages'].sort do |a, b|
          # Sort by position in section map
          if a['match_index'] != b['match_index']
            next a['match_index'] <=> b['match_index']
          end

          page_a = a['page']
          page_b = b['page']

          # If there are no weights
          page_a_weight = page_a.respond_to?(:data) && page_a.data['weight'] || nil
          page_b_weight = page_b.respond_to?(:data) && page_b.data['weight'] || nil
          unless page_a_weight.nil? && page_b_weight.nil?
            next 1 if page_a_weight.nil?
            next -1 if page_b_weight.nil?

            next page_b_weight <=> page_a_weight
          end

          # Then by alphabetical
          page_a_title = page_a.respond_to?(:data) && page_a.data['weight'] || page_a['title']
          page_b_title = page_b.respond_to?(:data) && page_b.data['weight'] || page_b['title']
          next page_a_title.downcase <=> page_b_title.downcase
        end

        # Remove the match index
        sections[title]['pages'] = sections[title]['pages'].map { |p| p['page'] }.uniq
      end


      sections.values
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
