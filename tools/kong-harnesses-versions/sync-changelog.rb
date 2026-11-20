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
  TOOLING_SCOPES = %w[ci deps ksai threat-model].freeze

  # The elements that the export knows how to write back. It refuses any other, such
  # as a footnote, math, raw HTML or an HTML comment, rather than guess.
  ELEMENTS = %i[root blank header p text ul ol li strong em codespan codeblock a img br hr
                blockquote smart_quote typographic_sym entity eob].freeze
  # The elements of a block that hold text, which an address can run across.
  INLINE = %i[strong em a].freeze

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
  # placeholder such as `<profile>` is text, not HTML. The writer escapes both, so the
  # site also shows them as text. An HTML comment or a tag that HTML knows, such as
  # `<del>`, is still read as HTML, so the export refuses it rather than show it.
  class Parser < Kramdown::Parser::GFM
    def initialize(source, options)
      super
      @block_parsers.delete(:table)
    end

    def parse_span_html
      tag = [HTML_TAG_RE, HTML_TAG_CLOSE_RE].filter_map { |pattern| @src[1] if @src.check(pattern) }.first
      html = [HTML_COMMENT_RE, HTML_INSTRUCTION_RE, HTML_CDATA_RE].any? { |pattern| @src.match?(pattern) } ||
             (tag && HTML_ELEMENT[tag.downcase])
      html ? super : add_text(@src.getch)
    end
  end

  # Kramdown's writer, which also escapes `<`, because the site reads `<name>` as HTML.
  class Writer < Kramdown::Converter::Kramdown
    # Kramdown's writer escapes a block marker only on the first line of a paragraph,
    # and a `=` or `-` line on the second line with a control character. After a hard
    # line break, any line of a paragraph can start a block.
    LINE_START = /\A( {0,3})(?:(#|>|[+-](?=\s|\z))|([=-])(?=[=\-\s]*\z))/
    # An entity stays as it was written. Kramdown's writer gives its character, which
    # can then start a table, emphasis or a code span, as `&#124;` would.
    def convert_entity(el, opts)
      el.options[:original] || super
    end

    # The GFM parser also reads `~~` as strikethrough, which kramdown's writer does not
    # escape.
    def convert_text(el, opts)
      result = super
      opts[:raw_text] ? result : result.gsub(/[<~]/) { |char| "\\#{char}" }
    end

    # A line break in a code span is held as a mark until the paragraph is done, so only
    # the lines of the paragraph get their start escaped.
    def convert_p(el, opts)
      lines = inner(el, opts).strip.split("\n").map do |line|
        line.sub(LINE_START) { "#{::Regexp.last_match(1)}\\#{::Regexp.last_match(2) || ::Regexp.last_match(3)}" }
            .sub(/\A( {0,3})(\d+)\.(?=\s|\z)/, '\1\2\\.')
            .sub(/\A( {0,3}):/, '\1\\:')
      end
      # Two backslashes at the end of a line are a line break.
      "#{lines.map { |line| line.sub(/\\\\\z/, '&#92;') }.join("\n")}\n".gsub(LINE_BREAK, "\n")
    end

    # Kramdown's writer ends a list in a list item with no blank line, so a block after
    # it in the item would go on in its last item.
    def convert(el, opts = { indent: 0 })
      result = super
      return result unless %i[ul ol].include?(el.type) && @stack.last&.type == :li

      later = @stack.last.children.drop(opts[:index].to_i + 1)
      later.any? { |sibling| sibling.type != :blank } ? "#{result}\n" : result
    end

    # Kramdown's writer indents every line of a list item, but kramdown does not take
    # that indent off a line of only white space, such as one in a code block.
    def convert_li(el, opts)
      width = @stack.last.type == :ul ? @list_indent : 4
      super.gsub(/^ {#{width}}(?=[ \t]*$)/, '')
    end

    # Kramdown's writer gives `* * *`, which after a list marker is a rule, not a list
    # item that holds one.
    def convert_hr(_el, _opts)
      "___\n"
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
    raise 'The changelog has raw HTML or a strikethrough, which the export cannot write back safely.' if %i[html_element xml_comment xml_pi].include?(element.type)
    raise "The changelog has #{element.type}, which the export cannot write back safely." unless ELEMENTS.include?(element.type)

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
      without_addresses(element) if %i[p header].include?(element.type)
      # A heading, paragraph or block quote with nothing left shows nothing, and the
      # writer cannot write an empty one.
      %i[header p blockquote].include?(element.type) && element.children.all? { |child| child.type == :blank } ? [] : [element]
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

  def joined(children)
    children.each_with_object([]) do |child, list|
      if child.type == :text && list.last&.type == :text
        list.last.value += child.value
      else
        list << (child.type == :text ? Kramdown::Element.new(:text, child.value.dup) : child)
      end
    end
  end

  # The pieces of a block's text, in order, that an address can run across: text,
  # entities and typographic symbols, also inside bold and emphasis. Code and line
  # breaks end a run.
  def runs(element, list = [[]])
    element.children.each do |child|
      case child.type
      when :text, :entity, :smart_quote, :typographic_sym then list.last << child
      when *INLINE then runs(child, list)
      else list << []
      end
    end
    list
  end

  def source_text(piece)
    case piece.type
    when :text then piece.value
    when :entity then piece.options[:original] || piece.value.char
    when :smart_quote then piece.value.to_s.include?('dquo') ? '"' : "'"
    else Writer::TYPOGRAPHIC_SYMS[piece.value]
    end
  end

  # Removes every bare address from a block, as a reader sees it across bold, emphasis
  # and entities, drops the brackets that held only removed links, and drops bold or
  # emphasis that is then empty. Each removed link takes one space with it.
  def without_addresses(block)
    runs(block).each do |run|
      offset = 0
      spans = run.map { |piece| [piece, offset, offset += source_text(piece).length] }
      addresses = run.map { |piece| source_text(piece) }.join.to_enum(:scan, WEB_ADDRESS).map { Regexp.last_match.offset(0) }
      spans.each do |piece, from, to|
        covered = addresses.select { |start, stop| start < to && stop > from }
        next if covered.empty?

        text = source_text(piece)
        kept = covered.reverse.reduce(text) do |value, (start, stop)|
          mark = start >= from ? REMOVED : ''
          value[0...[start - from, 0].max] + mark + value[[stop - from, text.length].min..]
        end
        piece.type = :text
        piece.value = kept
        piece.options.clear
      end
    end
    tidied(block)
    # The writer drops a line break at the start or the end of a block.
    block.children.shift while block.children.first&.type == :br
    block.children.pop while block.children.last&.type == :br
  end

  def tidied(element)
    element.children.each { |child| tidied(child) if INLINE.include?(child.type) }
    element.children = joined(element.children).each do |child|
      next unless child.type == :text

      child.value = child.value.gsub(/\(\s*(?:#{REMOVED}\s*)+\)/, REMOVED)
                         .gsub(/\(#{REMOVED}+ ?/, '(')
                         .gsub(/ ?#{REMOVED}+/, '')
    end
    element.children = element.children.reject do |child|
      (child.type == :text && child.value.empty?) || (INLINE.include?(child.type) && child.children.empty?)
    end
    children = joined(element.children.flat_map { |child| INLINE.include?(child.type) ? trimmed(child) : [child] })
    # White space next to a line break does not show, and the writer gives two line
    # breaks in a row as the end of the paragraph, so the export keeps only one.
    children = children.reject.with_index do |child, index|
      near = [index.zero? ? nil : children[index - 1], children[index + 1]]
      child.type == :text && child.value.strip.empty? && near.any? { |piece| piece.nil? || piece.type == :br }
    end
    element.children = children.each_with_object([]) do |child, list|
      list << child unless child.type == :br && list.last&.type == :br
    end
  end

  # Bold or emphasis cannot start or end with white space or a line break, so those go
  # before or after it.
  def trimmed(element)
    before = edges(element.children, :first, :shift, :lstrip, /\A\s/)
    after = edges(element.children, :last, :pop, :rstrip, /\s\z/).reverse
    [*before, *(element.children.empty? ? [] : [element]), *after]
  end

  def edges(children, edge, take, strip, space)
    moved = []
    while (piece = children.public_send(edge))
      if piece.type == :br
        moved << children.public_send(take)
      elsif piece.type == :text && piece.value.match?(space)
        moved << Kramdown::Element.new(:text, ' ')
        piece.value = piece.value.public_send(strip)
        children.public_send(take) if piece.value.empty?
      else
        break
      end
    end
    moved
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
        element.children = element.children.reject { |item| name != BREAKING_CHANGES && TOOLING_SCOPES.include?(scope(item)) }
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
    output = "#{output.sub(/\A\n+/, '').sub(/\n+\z/, '')}\n"
    written(output, root)
  end

  def types_of(element)
    [element.type, *element.children.flat_map { |child| types_of(child) }]
  end

  def code_of(element)
    return [element.value.chomp] if %i[codespan codeblock].include?(element.type)

    element.children.flat_map { |child| code_of(child) }
  end

  # What a reader sees of a tree: each element with its type, and the text that it shows.
  # An entity, a smart quote and a typographic symbol count as their text, and white
  # space counts as one space, as the page shows it.
  def shape(element)
    case element.type
    when :blank, :eob then nil
    when :text then element.value
    when :entity then element.value.char
    # The direction of a smart quote follows the text next to it.
    when :smart_quote then element.value.to_s.include?('dquo') ? '"' : "'"
    when :typographic_sym then Writer::TYPOGRAPHIC_SYMS[element.value]
    when :codespan then [:codespan, element.value]
    when :codeblock then [:codeblock, element.value.chomp, element.attr['class']]
    else
      children = shapes(element.children)
      # An empty paragraph shows nothing, and the writer leaves it out.
      [element.type, element.options[:level], *children] unless element.type == :p && children.empty?
    end
  end

  def shapes(children)
    list = children.filter_map { |child| shape(child) }.chunk_while { |a, b| a.is_a?(String) && b.is_a?(String) }
                   .map { |run| run.first.is_a?(String) ? run.join.gsub(/\s+/, ' ') : run.first }
    list[0] = list[0].lstrip if list.first.is_a?(String)
    list[-1] = list[-1].rstrip if list.last.is_a?(String)
    # White space next to a line break does not show.
    list.each_with_index do |item, index|
      next unless item.is_a?(Array) && item.first == :br

      list[index - 1] = list[index - 1].rstrip if index.positive? && list[index - 1].is_a?(String)
      list[index + 1] = list[index + 1].lstrip if list[index + 1].is_a?(String)
    end
    list.reject { |item| item == '' }
  end

  # The writer is not built for the GFM parser, so the export reads its own output again
  # with the parser and options of the site, tables and HTML too, and refuses it unless a
  # reader sees the same blocks, elements and text as in the tree that it wrote. So no
  # link, table, emphasis or code span can appear, and no code can change.
  def written(output, tree)
    reread, = Kramdown::Parser::GFM.parse(output, options)
    raise 'The export would write a link back, so it refuses the changelog.' if types_of(reread).intersect?(%i[a img])
    raise 'The export would change what a reader sees, so it refuses the changelog.' unless shape(reread) == shape(tree)

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
