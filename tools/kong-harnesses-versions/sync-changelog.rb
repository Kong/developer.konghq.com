# frozen_string_literal: true

require 'json'
require 'net/http'
require 'jekyll'
require 'kramdown'
require 'kramdown-parser-gfm'
require 'nokogiri'
require 'yaml'
require_relative 'check-changelog-links'

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
  # The elements of a block that hold text.
  INLINE = %i[strong em a].freeze

  REMOVED = "\u0000"
  LINE_BREAK = "\u0001"
  # The characters that kramdown's typographic symbols show, with a no-break space in the
  # two forms with a space.
  SYMBOLS = { mdash: '—', ndash: '–', hellip: '…', laquo: '«', raquo: '»', laquo_space: "«\u00a0", raquo_space: "\u00a0»" }.freeze
  QUOTES = { lsquo: '‘', rsquo: '’', ldquo: '“', rdquo: '”' }.freeze
  # The release-please preset links an issue number and a user name even inside a code
  # span, so the export puts the plain text back in code.
  PRESET_LINKS = [
    %r{\[(\#\d+)\]\(https://github\.com/Kong/kong-harnesses/issues/\d+\)},
    %r{\[(@[\w-]+)\]\(https://github\.com/[\w-]+\)}
  ].freeze

  # The site's parser, but a line with a `|` in an entry is text, not a table, and a
  # placeholder such as `<profile>` is text, not HTML, also at the start of a line. The
  # writer escapes both, so the site also shows them as text. An HTML comment or a tag
  # that HTML knows, such as `<del>`, is still read as HTML, so the export refuses it
  # rather than show it.
  class Parser < Kramdown::Parser::GFM
    def initialize(source, options)
      super
      @block_parsers.delete(:table)
    end

    # A placeholder at the start of a line is text too. A comment or a tag that HTML
    # knows is still read as HTML.
    def parse_block_html
      tag = [/^#{OPT_SPACE}#{HTML_TAG_RE}/o, /^#{OPT_SPACE}#{HTML_TAG_CLOSE_RE}/o].filter_map { |pattern| @src[1] if @src.check(pattern) }.first
      @src.check(/^#{OPT_SPACE}#{HTML_COMMENT_RE}/o) || HTML_ELEMENT[tag.to_s.downcase] ? super : false
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

    # The GFM parser also reads `~~` as strikethrough, and kramdown reads `--`, `...`
    # and `>>` as dashes, an ellipsis and a quote mark. Kramdown's writer escapes none of
    # them. The table parser of the site does not see an escaped backtick as text, so it
    # can pair it with the backtick of a code span and split a line at a `|` in the code.
    def convert_text(el, opts)
      result = super
      return result if opts[:raw_text]

      result.gsub(/\\(.)/m) { ::Regexp.last_match(1) == '`' ? '&#96;' : ::Regexp.last_match(0) }
            .gsub(/[<~]|([->.])(?=\1)|(?<=([->.]))\2/) { |char| "\\#{char}" }
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

    # Kramdown gives a quote mark its direction from the characters next to it, which
    # the export can change, and reads `-` and `.` runs next to a symbol as a longer
    # one. The character itself shows the same and stays as it is.
    def convert_smart_quote(el, _opts)
      QUOTES.fetch(el.value)
    end

    def convert_typographic_sym(el, _opts)
      SYMBOLS.fetch(el.value)
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
    case element.type
    when :text, :codespan then element.value.to_s
    when :entity, :smart_quote, :typographic_sym then visible_text(element)
    else element.children.map { |child| text_of(child) }.join
    end
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
    language = attributes['class'].to_s[/(?:\A|\s)language-(\S+)/, 1] if element.type == :codeblock
    element.attr.clear
    # The site's highlighter stops the build on a language that it does not know.
    element.attr['class'] = "language-#{KongHarnessesChangelogLinks.languages.include?(language) ? language : 'text'}" if language
    element.options.delete(:ial)
    attributes
  end

  # Kramdown makes the paragraph of a list item loose when a blank line comes after it,
  # also when only a reference definition follows the blank line. The writer writes no
  # blank line after the last item, so that item is tight unless an item before it is
  # loose.
  def tightened(list)
    blocks = list.children.last&.children.to_a.reject { |child| child.type == :blank }
    loose = list.children[0...-1].any? { |item| item.children.any? { |child| child.type == :p && !child.options[:transparent] } }
    blocks.first.options[:transparent] = true if blocks.length == 1 && blocks.first.type == :p && !loose
    list
  end

  # The site's parser ends a paragraph at a line that starts a block, also inside code,
  # where the writer cannot escape it. The export asks the parser whether the code that
  # it writes reads back as the same code.
  def code_breaks_paragraph?(element)
    return false unless element.value.include?("\n")

    root = Kramdown::Element.new(:root, nil, nil, encoding: Encoding::UTF_8)
    root.children << Kramdown::Element.new(:p).tap { |paragraph| paragraph.children << Kramdown::Element.new(:codespan, element.value) }
    reread, = Kramdown::Parser::GFM.parse(Writer.convert(root, options).first, options)
    blocks = reread.children.reject { |child| child.type == :blank }
    !(blocks.map(&:type) == [:p] && blocks.first.children.map(&:type) == [:codespan] && blocks.first.children.first.value == element.value)
  end

  # A link that the parser gives with its own web or mail address as its text.
  def own_address?(text, address)
    address.match?(/\A(?:https?|mailto):/i) && [address, address.sub(/\Amailto:/i, '')].include?(text)
  end

  # Every link goes and keeps its text, and an image gives its alt text, so the page has
  # no links. A link whose text is a reference or its own address goes with its text.
  # Code stays as it is, but for the links that the release-please preset adds inside
  # it. An address in plain text stays text, as the site's parser shows it, so the
  # export refuses it: only the parser can say where an address ends.
  def without_links(element)
    attributes = cleaned(element)
    raise 'The changelog has code with a line that starts a block, which the export cannot write back safely.' if element.type == :codespan && code_breaks_paragraph?(element)
    # The writer writes nothing for a code block of only white space.
    return [] if element.type == :codeblock && element.value.strip.empty?
    if %i[codespan codeblock].include?(element.type)
      element.value = PRESET_LINKS.reduce(element.value) { |value, link| value.gsub(link, '\1') }
      return [element]
    end
    children = element.children.flat_map { |child| without_links(child) }
    case element.type
    when :a
      address = attributes.fetch('href', '').to_s
      text = text_of(element)
      return [removed] if reference?(text, address) || own_address?(text, address)

      children
    when :img
      [Kramdown::Element.new(:text, attributes.fetch('alt', '').to_s)]
    else
      element.children = merged(separated(joined(children)))
      if %i[p header].include?(element.type)
        clear_of_addresses(element)
        tidied_block(element)
      end
      tightened(element) if %i[ul ol].include?(element.type)
      # A heading, paragraph or block quote with nothing left shows nothing, and the
      # writer cannot write an empty one.
      %i[header p blockquote].include?(element.type) && element.children.all? { |child| child.type == :blank } ? [] : [element]
    end
  end

  # The writer gives a code block as indented code, which goes on a paragraph right
  # before it unless a blank line is between them, and a paragraph goes on the one
  # before it too, as it can when a reference definition was between them. A tight
  # list item writes no line break after its paragraph, so that paragraph is no longer
  # tight.
  def separated(children)
    children.each_with_object([]) do |child, list|
      if %i[codeblock p].include?(child.type) && list.last && list.last.type != :blank && (child.type == :codeblock || list.last.type == :p)
        list.last.options[:transparent] = false if list.last.type == :p
        list << Kramdown::Element.new(:blank, "\n")
      end
      list << child
    end
  end

  # Two lists of the same kind with only blank lines between them read back as one, as
  # when the export drops an empty list between them, so the export makes them one.
  def merged(children)
    children.each_with_object([]) do |child, list|
      index = list.rindex { |element| element.type != :blank }
      if index && %i[ul ol].include?(child.type) && list[index].type == child.type
        list[index].children.concat(child.children)
        list.pop(list.length - index - 1)
      else
        list << child
      end
    end
  end

  # Joins text next to text, and code next to code, because no Markdown can write two
  # code spans with no character between them: their backticks would run together.
  def joined(children)
    children.each_with_object([]) do |child, list|
      if %i[text codespan].include?(child.type) && list.last&.type == child.type
        list.last.value += child.value
      else
        list << (child.type == :text ? Kramdown::Element.new(:text, child.value.dup) : child)
      end
    end
  end

  # The text that a reader sees of a piece.
  def visible_text(piece)
    case piece.type
    when :text then piece.value
    when :entity then piece.value.char
    when :smart_quote then QUOTES.fetch(piece.value)
    else SYMBOLS.fetch(piece.value)
    end
  end

  # The text of a block outside code, with a space for code and a line break.
  def prose_of(element)
    case element.type
    when :text, :entity, :smart_quote, :typographic_sym then visible_text(element)
    when :codespan, :br then ' '
    else element.children.map { |child| prose_of(child) }.join
    end
  end

  # Refuses a block with an address in its text, which the page cannot show, and a
  # removed link right before a word, or a quote mark and a word, as `[#1](...)'s`,
  # because the text would then lose what the link held.
  def clear_of_addresses(block)
    prose = prose_of(block)
    entry = prose.delete(REMOVED).strip[0, 120].inspect
    raise "The changelog has an address in the text of #{entry}. The page shows no addresses, so write it as a link at the source." if KongHarnessesChangelogLinks.normalize(prose).include?('//')
    raise "The changelog has a link right before a word in #{entry}. Put a space or a punctuation mark after the link at the source." if prose.match?(/#{REMOVED}(?=[[:alnum:]]|['"‘’“”][[:alnum:]])/o)
  end

  # Drops the brackets that held only removed links, and bold or emphasis that is then
  # empty. The writer drops a line break at the start or the end of a block.
  def tidied_block(block)
    tidied(block)
    block.children.shift while block.children.first&.type == :br
    block.children.pop while block.children.last&.type == :br
  end

  def tidied(element)
    element.children.each { |child| tidied(child) if INLINE.include?(child.type) }
    element.children = joined(element.children).each do |child|
      next unless child.type == :text

      child.value = child.value.gsub(/\(\s*(?:#{REMOVED}\s*)+\)/, REMOVED)
                         .gsub(/\(#{REMOVED}+ ?/, '(')
    end
    element.children = joined(without_empty_quotes(element.children))
    element.children.each_with_index do |child, index|
      next unless child.type == :text

      following = element.children[index + 1] ? text_of(element.children[index + 1]) : ''
      # A removed link takes the space before it, but not before a word or a quote, as
      # the words on each side would then join.
      child.value = child.value.gsub(/( ?)#{REMOVED}+(?=(.?))/m) do
        space, after = ::Regexp.last_match(1), ::Regexp.last_match(2)
        after = following[0].to_s if after.empty?
        space.empty? || after.empty? || after.match?(/[[:space:].,;:!?)\]}]/) ? '' : ' '
      end
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

  # Quotes that held only a removed link go with it.
  def without_empty_quotes(children)
    children.each_with_object([]) do |child, list|
      opening, inside = list.last(2)
      # Kramdown can turn either quote of the pair, so any two of the same kind count.
      if child.type == :smart_quote && inside&.type == :text && !inside.options[:quoted] && inside.value.match?(/\A\s*#{REMOVED}+\s*\z/) &&
         opening&.type == :smart_quote && child.value.to_s[1] == opening.value.to_s[1]
        list.pop(2)
        # A quote of a pair that went cannot open another pair.
        list << Kramdown::Element.new(:text, REMOVED, nil, quoted: true)
      else
        list << child
      end
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

  def copy(element)
    Marshal.load(Marshal.dump(element))
  end

  # Gives the elements of a section that the page shows, and a copy of them as they were
  # in the source, which the export checks its text against.
  def public_section(title, content)
    name = text_of(title).strip
    return [[], []] unless USER_SECTIONS.include?(name)

    sources = [copy(title)]
    kept = content.flat_map do |element|
      if %i[ul ol].include?(element.type)
        cleaned(element)
        # An upgrade step stays whatever its scope, because a user must still do it.
        element.children = element.children.reject { |item| name != BREAKING_CHANGES && TOOLING_SCOPES.include?(scope(item)) }
        sources << copy(element)
        element.children = element.children.flat_map { |item| without_links(item) }.reject { |item| entry_text_empty?(item) }
        element.children.empty? ? [] : [tightened(element)]
      else
        sources << copy(element)
        without_links(element)
      end
    end
    kept.all? { |element| element.type == :blank } ? [[], []] : [[without_links(title).first, *merged(kept)], sources]
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
    original = Kramdown::Element.new(:root, nil, nil, source.options.slice(:encoding))
    releases.zip(versions).each do |release, version|
      next unless published.include?(version) && published.include?(version.split('-').first)

      sections = release[:sections].map { |section| public_section(section[:title], section[:content]) }
      next if sections.all? { |kept, _| kept.empty? }

      original.children.concat([copy(release[:heading])], *sections.map(&:last))
      root.children.concat(without_links(release[:heading]), *sections.map(&:first))
    end
    raise 'The changelog has no entries for users in its published releases.' if root.children.empty?

    output, = Writer.convert(root, options)
    output = "#{output.sub(/\A\n+/, '').sub(/\n+\z/, '')}\n"
    written(output, root, original)
  end

  def types_of(element)
    [element.type, *element.children.flat_map { |child| types_of(child) }]
  end

  def code_of(element)
    return [element.value.chomp] if %i[codespan codeblock].include?(element.type)

    element.children.flat_map { |child| code_of(child) }
  end

  BLOCKS = %w[p li ul ol h1 h2 h3 h4 h5 h6 blockquote pre hr br].freeze

  def html(tree)
    Nokogiri::HTML5.fragment(Kramdown::Converter::Html.convert(tree, options).first)
  end

  # The page as a reader sees it: each element with its attributes, and its text with
  # white space as one space, but code as it is.
  def page(node, code: false)
    return code ? node.text : node.text.gsub(/\s+/, ' ') if node.text?
    return [] unless node.element? || node.fragment?

    code ||= %w[pre code].include?(node.name)
    pieces = node.children.flat_map { |child| [page(child, code: code)] }.reject { |piece| piece == [] }
                 .chunk_while { |a, b| a.is_a?(String) && b.is_a?(String) }.map { |run| run.first.is_a?(String) ? run.join : run.first }
    # White space at the edge of a block, or next to one, does not show.
    unless code
      pieces = pieces.each_with_index.map do |piece, index|
        next piece unless piece.is_a?(String)

        before = index.zero? || BLOCKS.include?(pieces[index - 1].first.to_s)
        after = index == pieces.length - 1 || (pieces[index + 1].is_a?(Array) && BLOCKS.include?(pieces[index + 1].first))
        piece = piece.lstrip if before && (index.zero? || pieces[index - 1].is_a?(Array))
        after ? piece.rstrip : piece
      end.reject { |piece| piece == '' }
    end
    # The GFM parser gives a heading its id from the text, which the compare checks.
    attributes = node.attributes.transform_values(&:value).reject { |name, _| name == 'id' && node.name.match?(/\Ah[1-6]\z/) }
    [node.fragment? ? '' : node.name, attributes.sort, *pieces]
  end

  # The text that a reader sees, with an image as its alt text and each block edge and
  # run of white space as one space, and the spans of it that the export may take out:
  # a whole link that is a reference or its own address, as the parser gives it, and
  # the brackets and quotes next to it.
  def reading(fragment)
    text = +''
    spans = []
    codes = []
    add = ->(value) { value.each_char { |char| text << (char.match?(/\s/) ? ' ' : char) unless char.match?(/\s/) && (text.empty? || text.end_with?(' ')) } }
    walk = lambda do |node|
      next add.call(node.text) if node.text?
      next add.call(node['alt'].to_s) if node.name == 'img'

      add.call(' ') if BLOCKS.include?(node.name)
      from = text.length
      node.children.each(&walk)
      spans << [from, text.length] if node.name == 'a' && removable_link?(text[from..].strip, node['href'].to_s)
      codes << [from, text.length] if node.name == 'code'
      add.call(' ') if BLOCKS.include?(node.name)
    end
    fragment.children.each(&walk)
    codes.each { |from, to| spans.concat(code_link_spans(text[from...to]).map { |start, stop| [from + start, from + stop] }) }
    [text, spans + beside(text, spans)]
  end

  # A link that the check lets the export take out whole: its text is a number, an
  # issue number, a hash or its own web or mail address.
  def removable_link?(label, address)
    label.match?(/\A#?\d+\z|\A\h{7,40}\z/) || (address.match?(/\A(?:https?|mailto):/i) && [address, address.sub(/\Amailto:/i, '')].include?(label))
  end

  # In code, the link syntax around an issue number or a user name, where the parser
  # finds such a link when it reads the code as Markdown.
  def code_link_spans(code)
    links = html(Parser.parse(code, options).first).css('a').select { |link| link.text.match?(/\A[#@][\w-]+\z/) }
    links.flat_map do |link|
      written = "[#{link.text}](#{link['href']})"
      starts = (0..code.length).select { |index| code[index, written.length] == written }
      starts.flat_map { |start| [[start, start + 1], [start + 1 + link.text.length, start + written.length]] }
    end
  end

  # The brackets and quote marks next to a span, with only white space between, which
  # the export takes out with a removed link.
  def beside(text, spans)
    spans.flat_map do |from, to|
      before = from - 1
      before -= 1 while before >= 0 && text[before] == ' '
      after = to
      after += 1 while after < text.length && text[after] == ' '
      # Kramdown can turn a quote either way, so either form counts on each side.
      [(before if before >= 0 && '([{‘’“”\'"'.include?(text[before])), (after if after < text.length && ')]}‘’“”\'"'.include?(text[after]))]
        .compact.map { |index| [index, index + 1] }
    end
  end

  # Whether a reader sees all of the source text in the kept text, with only its spans
  # taken out. The kept text can have one more space, and it can lose a space next to a
  # span, but not one between two words.
  def all_kept?(source, kept)
    text, spans = source
    ends = spans.group_by(&:first).transform_values { |list| list.map(&:last) }
    edges = spans.flat_map { |from, to| [from - 1, to] }.to_set
    word = /[[:alnum:]]/
    seen = Set.new
    todo = [[0, 0]]
    until todo.empty?
      i, j = todo.pop
      next unless seen.add?([i, j])
      return true if i == text.length && j == kept.length

      todo << [i + 1, j + 1] if i < text.length && text[i] == kept[j]
      todo << [i, j + 1] if kept[j] == ' '
      if text[i] == ' '
        joins = j.positive? && kept[j - 1].match?(word) && kept[j].to_s.match?(word)
        todo << [i + 1, j] if j.zero? || j == kept.length || kept[j - 1] == ' ' || kept[j] == ' ' || (edges.include?(i) && !joins)
      end
      ends.fetch(i, []).each { |stop| todo << [stop, j] }
    end
    false
  end

  # The writer is not built for the GFM parser, so the export renders its own output
  # again with the parser and options of the site, tables and HTML too, and refuses it
  # unless the HTML shows the same as that of the tree that it wrote. It also refuses the
  # tree unless a reader sees all the text of the source in it, with only whole links
  # that the parser gives as a reference or their own address, and the brackets and
  # quotes next to them, taken out, and no two words joined. It reads that text from a
  # second rendering, with no rule of the export. It also refuses a code block that
  # lost its language.
  def written(output, tree, source = nil)
    reread, = Kramdown::Parser::GFM.parse(output, options)
    raise 'The export would write a link back, so it refuses the changelog.' if types_of(reread).intersect?(%i[a img])
    raise 'The export would change what a reader sees, so it refuses the changelog.' unless page(html(reread)) == page(html(tree))
    return output unless source

    raise 'The export would leave out text that a reader sees, so it refuses the changelog.' unless all_kept?(reading(html(source)), reading(html(tree)).first)
    raise 'The export would change the language of a code block, so it refuses the changelog.' unless code_languages(html(source)).map { |language| language && (KongHarnessesChangelogLinks.languages.include?(language) ? language : 'text') } == code_languages(html(tree))

    output
  end

  def code_languages(fragment)
    # A code block of only white space goes.
    fragment.css('pre code').reject { |code| code.text.strip.empty? }.map { |code| code['class'].to_s[/(?:\A|\s)language-(\S+)/, 1] }
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
