# frozen_string_literal: true

require 'json'
require 'net/http'
require 'jekyll'
require 'kramdown'
require 'kramdown-parser-gfm'
require 'yaml'

# Writes the kong-harnesses changelog page data from CHANGELOG.md on the main branch of
# Kong/kong-harnesses. The export parses the changelog with the parser that the site
# uses, changes the tree, and writes it back with kramdown's own Markdown writer, so it
# never rewrites Markdown text with patterns. check-changelog-links.rb then checks the
# result as the site renders it.
module KongHarnessesChangelog
  module_function

  ROOT = File.expand_path('../..', __dir__)
  DATA_FILE = File.join(ROOT, 'app/_data/kong-harnesses/changelog.json')
  REPO = 'Kong/kong-harnesses'

  # Readers of the site need what changed for them, not the repository's own build, CI,
  # docs and review work, so only these sections are published.
  USER_SECTIONS = ['⚠ BREAKING CHANGES', 'Features', 'Bug Fixes', 'Performance'].freeze
  BREAKING_CHANGES = '⚠ BREAKING CHANGES'
  # Scopes of changes to the repository's own tooling, reviews and dependency pins.
  # docs/release.md in Kong/kong-harnesses names the same list; change both together.
  INTERNAL_SCOPES = %w[ci deps ksai threat-model].freeze

  # The elements that the export knows how to write back. It refuses any other, such
  # as a footnote, math or raw HTML, rather than guess. A `del` is GFM strikethrough.
  ELEMENTS = %i[root blank header p text ul ol li strong em codespan codeblock a img br hr
                blockquote smart_quote typographic_sym entity xml_comment eob html_element].freeze

  REMOVED = "\u0000"
  LINE_BREAK = "\u0001"
  WEB_ADDRESS = %r{<https?://[^\s<>]*>|https?://[^\s<>()]*(?:\([^\s<>()]*\)[^\s<>()]*)*}i
  # The release-please preset links an issue number and a user name even inside a code
  # span, so the export puts the plain text back in code.
  PRESET_LINKS = [
    %r{\[(\#\d+)\]\(https://github\.com/Kong/kong-harnesses/issues/\d+\)},
    %r{\[(@[\w-]+)\]\(https://github\.com/[\w-]+\)}
  ].freeze

  # The site's parser, but a line with a `|` in an entry is text, not a table, and a
  # `<name>` in an entry is text, not HTML. The writer escapes both, so the site also
  # shows them as text.
  class Parser < Kramdown::Parser::GFM
    def initialize(source, options)
      super
      @block_parsers.delete(:table)
      @span_parsers.delete(:span_html)
    end
  end

  # Kramdown's writer, which also escapes `<`, because the site reads `<name>` as HTML.
  class Writer < Kramdown::Converter::Kramdown
    def convert_text(el, opts)
      result = super
      opts[:raw_text] ? result : result.gsub('<', '\<')
    end

    # The writer escapes a `:` at the start of any line of a paragraph, also in a code
    # span, so a line break in a code span is held as a mark until the paragraph is done.
    def convert_p(el, opts)
      super.gsub(LINE_BREAK, "\n")
    end

    def convert_header(el, opts)
      super.gsub(LINE_BREAK, "\n")
    end

    # Kramdown's writer puts a code span that starts with a space in single backticks,
    # which kramdown then reads as text. Two or more backticks, with the space that
    # kramdown takes off each side, keep any value.
    def convert_codespan(el, _opts)
      value = el.value.gsub("\n", LINE_BREAK)
      return "`#{value}`" if el.value.match?(/\A[^\s`](?:[^`]*[^\s`])?\z/)

      delimiter = '`' * [2, el.value.scan(/`+/).map(&:length).max.to_i + 1].max
      "#{delimiter} #{value} #{delimiter}"
    end
  end

  def options
    @options ||= begin
      config = Jekyll::Configuration.from(YAML.safe_load_file(File.join(ROOT, 'jekyll.yml')))
      parser = Jekyll::Converters::Markdown::KramdownParser.new(config)
      Kramdown::Options.merge(parser.instance_variable_get(:@config)).merge(line_width: 10_000).freeze
    end
  end

  def parse(markdown)
    root, = Parser.parse(markdown, options)
    root
  end

  def text_of(element)
    element.type == :text || element.type == :codespan ? element.value.to_s : element.children.map { |child| text_of(child) }.join
  end

  # An issue or pull request number, or the hash of a commit link, means nothing without
  # its link. A word of hex letters, such as "defaced", is a hash only on a commit link,
  # and a number such as a year is a reference only on an issue or pull request link.
  def reference?(text, address)
    text.match?(/\A#\d+\z/) ||
      (address.match?(%r{/(?:issues|pull)/\d+}i) && text.match?(/\A\d+\z/)) ||
      (address.match?(%r{/commits?/}i) && text.match?(/\A\h{7,40}\z/))
  end

  def removed
    Kramdown::Element.new(:text, REMOVED)
  end

  # Refuses an element that the export cannot write back, and drops every attribute but
  # the language of a code block, so no attribute list reaches the page. Gives the
  # attributes that the element had.
  def cleaned(element)
    raise "The changelog has #{element.type}, which the export cannot write back safely." unless ELEMENTS.include?(element.type)
    raise 'The changelog has raw HTML, which the export cannot write back safely.' if element.type == :html_element && element.value != 'del'

    attributes = element.attr.dup
    element.attr.clear unless element.type == :codeblock && attributes.keys == ['class'] && attributes['class'].match?(/\Alanguage-[\w+-]+\z/)
    element.options.delete(:ial)
    attributes
  end

  # Every link goes and keeps its text, an image gives its alt text, and an address
  # that is its own text goes, so the page has no links. Code stays as it is, but for
  # the links that the release-please preset adds inside it.
  def without_links(element)
    attributes = cleaned(element)
    if %i[codespan codeblock].include?(element.type)
      element.value = PRESET_LINKS.reduce(element.value) { |value, link| value.gsub(link, '\1') }
      return [element]
    end
    return [] if element.type == :xml_comment

    children = element.children.flat_map { |child| without_links(child) }
    case element.type
    when :a
      address = attributes.fetch('href', '').to_s
      text = text_of(element)
      return [removed] if reference?(text, address) || text == address || text == address.delete_prefix('mailto:')

      children
    when :img
      [Kramdown::Element.new(:text, attributes.fetch('alt', '').to_s)]
    else
      element.children = separated(joined(children))
      [element]
    end
  end

  # The writer gives a code block as indented code, which goes on a paragraph right
  # before it unless a blank line is between them. A tight list item writes no line
  # break after its paragraph, so that paragraph is no longer tight.
  def separated(children)
    children.each_with_object([]) do |child, list|
      if child.type == :codeblock && list.last && list.last.type != :blank
        list.last.options[:transparent] = false if list.last.type == :p
        list << Kramdown::Element.new(:blank, "\n")
      end
      list << child
    end
  end

  # Joins neighbor text nodes, removes bare addresses, and drops brackets that held only
  # removed links. Each removed link takes one space with it.
  def joined(children)
    children.each_with_object([]) do |child, list|
      if child.type == :text && list.last&.type == :text
        list.last.value += child.value
      else
        list << (child.type == :text ? Kramdown::Element.new(:text, child.value.dup) : child)
      end
    end.each do |child|
      next unless child.type == :text

      child.value = child.value.gsub(WEB_ADDRESS, REMOVED)
                         .gsub(/\(\s*(?:#{REMOVED}\s*)+\)/, REMOVED)
                         .gsub(/\(#{REMOVED}+ ?/, '(')
                         .gsub(/ ?#{REMOVED}+/, '')
    end
  end

  def entry_text_empty?(element)
    text_of(element).strip.empty? && element.children.none? { |child| %i[codeblock img hr].include?(child.type) }
  end

  # A list entry such as "* **deps(actions):** bump" has the scope `deps`.
  def scope(item)
    strong = item.children.first&.children&.first
    return unless strong&.type == :strong

    text_of(strong)[/\A([^:*(]+)(?:\([^)]*\))?:\z/, 1]
  end

  def public_section(title, content)
    name = text_of(title).strip
    return [] unless USER_SECTIONS.include?(name)

    kept = content.flat_map do |element|
      if %i[ul ol].include?(element.type)
        cleaned(element)
        # An upgrade step stays whatever its scope, because a user must still do it.
        element.children = element.children.reject { |item| name != BREAKING_CHANGES && INTERNAL_SCOPES.include?(scope(item)) }
        element.children = element.children.flat_map { |item| without_links(item) }.reject { |item| entry_text_empty?(item) }
        element.children.empty? ? [] : [element]
      else
        without_links(element)
      end
    end
    kept.all? { |element| element.type == :blank } ? [] : [without_links(title).first, *kept]
  end

  # Only text of a published release reaches the site. release-please writes a section
  # when the release pull request merges, before the release job publishes it, and a
  # release candidate can be published before its final release, or for a final release
  # that never comes. So a section stays only when its heading names a published release
  # (`published`, the versions without the v), and a release candidate stays only once
  # the final release of the same version is published. The candidate's section stays
  # after that, because release-please takes the version in its manifest, the candidate,
  # as the last release, so the final section lists only the commits after it. Text
  # before the first heading goes. A heading with no version, or no heading for `highest`,
  # the highest published release, stops the sync, so a changelog that lost its sections
  # cannot empty the page. So does a changelog with no entries for users left.
  def export(markdown, published:, highest:)
    raise 'The changelog contains a NUL or SOH control character.' if markdown.include?(REMOVED) || markdown.include?(LINE_BREAK)

    releases = []
    source = parse(markdown)
    source.children.each do |element|
      level = element.type == :header ? element.options[:level] : nil
      if level == 2
        releases << { heading: element, sections: [] }
      elsif level == 3 && releases.any?
        releases.last[:sections] << { title: element, content: [] }
      elsif releases.last&.dig(:sections)&.any?
        releases.last[:sections].last[:content] << element
      end
    end

    versions = releases.map do |release|
      raw = release[:heading].options[:raw_text].to_s
      raw[/\A\[?(\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?)(?=[\]\s(]|\z)/, 1] ||
        raise("The changelog has a release heading with no version: #{raw}")
    end
    raise "The changelog has no section for #{highest}, the highest published release." unless versions.include?(highest)

    root = Kramdown::Element.new(:root, nil, nil, source.options.slice(:encoding))
    releases.zip(versions).each do |release, version|
      next unless published.include?(version) && published.include?(version.split('-').first)

      sections = release[:sections].flat_map { |section| public_section(section[:title], section[:content]) }
      root.children.concat(without_links(release[:heading]), sections) unless sections.empty?
    end
    raise 'The changelog has no entries for users in its published releases.' if root.children.empty?

    output, = Writer.convert(root, options)
    # Kramdown does not take the indent of a list item off a blank line in a code block,
    # so the blank lines that the writer indents would add spaces to the code.
    output = "#{output.gsub(/^[ \t]+$/, '').sub(/\A\n+/, '').sub(/\n+\z/, '')}\n"
    written(output, root)
  end

  def types_of(element)
    [element.type, *element.children.flat_map { |child| types_of(child) }]
  end

  def code_of(element)
    return [element.value.chomp] if %i[codespan codeblock].include?(element.type)

    element.children.flat_map { |child| code_of(child) }
  end

  # The writer is not built for the GFM parser, so the export reads its own output again
  # and refuses it when a link is left or the text of any code changed.
  def written(output, tree)
    reread = parse(output)
    raise 'The export would write a link back, so it refuses the changelog.' if types_of(reread).intersect?(%i[a img])
    raise 'The export would change the text of code, so it refuses the changelog.' unless code_of(reread) == code_of(tree)

    output
  end

  # `get` takes a path of the GitHub API and an Accept type, and gives the status code
  # and the body.
  def fetch(get)
    releases = []
    (1..).each do |page|
      status, body = get.call("/repos/#{REPO}/releases?per_page=100&page=#{page}", 'application/vnd.github+json')
      raise "GitHub API request for #{REPO} releases failed (#{status}). Set GH_TOKEN to a GitHub token with read access to #{REPO}." unless status == 200

      batch = JSON.parse(body)
      releases.concat(batch)
      break if batch.length < 100
    end
    # The highest vX.Y.Z release, not the newest or the one marked latest, as the versions
    # job picks it: anyone who can write to the repository can mark an older release as
    # the latest, and a backport published after a newer release must not replace it.
    highest = releases.reject { |release| release['draft'] || release['prerelease'] }
                      .map { |release| release['tag_name'] }
                      .grep(/\Av\d+\.\d+\.\d+\z/)
                      .max_by { |tag| Gem::Version.new(tag.delete_prefix('v')) }
    raise "#{REPO} has no published vX.Y.Z release." unless highest

    # Every published release, release candidates too, but no draft.
    published = releases.reject { |release| release['draft'] }
                        .map { |release| release['tag_name'] }
                        .grep(/\Av\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?\z/)
                        .map { |tag| tag.delete_prefix('v') }
    # main, not the tag, so a correction to an earlier entry reaches the page.
    status, changelog = get.call("/repos/#{REPO}/contents/CHANGELOG.md?ref=main", 'application/vnd.github.raw')
    raise "GitHub API request for #{REPO} CHANGELOG.md on main failed (#{status})." unless status == 200

    [highest, export(changelog.force_encoding('UTF-8'), published: published, highest: highest.delete_prefix('v'))]
  end

  def github(token)
    lambda do |path, accept|
      uri = URI("https://api.github.com#{path}")
      request = Net::HTTP::Get.new(uri, 'Accept' => accept)
      request['Authorization'] = "Bearer #{token}" if token && !token.empty?
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
      [response.code.to_i, response.body]
    end
  end

  def sync(out_file: DATA_FILE, get: github(ENV.fetch('GH_TOKEN', nil)))
    tag, markdown = fetch(get)
    File.write(out_file, "#{JSON.pretty_generate({ markdown: markdown })}\n")
    tag
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    puts "Wrote the kong-harnesses changelog at #{KongHarnessesChangelog.sync}"
  rescue StandardError => e
    warn "Error: #{e.message}"
    exit 1
  end
end
