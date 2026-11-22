# frozen_string_literal: true

require 'cgi'
require 'json'
require 'net/http'
require 'jekyll'
require 'kramdown'
require 'kramdown-parser-gfm'
require 'nokogiri'
require 'yaml'
require_relative 'check-changelog-links'

# Writes the kong-harnesses changelog page data from CHANGELOG.md on the main branch of
# the repository that publishes the kong-harnesses releases. The export parses the
# changelog with the parser that the site uses, changes the tree, and writes it back
# with kramdown's own Markdown writer, so it never rewrites Markdown text with patterns.
# check-changelog-links.rb then checks the result as the site renders it.
module KongHarnessesChangelog
  module_function

  ROOT = File.expand_path('../..', __dir__)
  DATA_FILE = File.join(ROOT, 'app/_data/kong-harnesses/changelog.json')

  def repo
    KongHarnessesChangelogLinks.repo
  end

  # GitHub owner and repository names are not case-sensitive, so the value of the
  # secret can differ in letter case from the addresses that release-please writes.
  def own?(name)
    name.casecmp?(repo)
  end

  def own_owner?(owner)
    owner.casecmp?(repo.split('/').first)
  end

  # Readers of the site need what changed for them, not the repository's own build, CI
  # and docs work, so only these sections are published.
  USER_SECTIONS = ['⚠ BREAKING CHANGES', 'Features', 'Bug Fixes', 'Performance'].freeze
  BREAKING_CHANGES = '⚠ BREAKING CHANGES'
  # Scopes of changes to the repository's own tooling and dependency pins.
  # The release notes of the kong-harnesses releases use the same scopes; change both
  # together.
  TOOLING_SCOPES = %w[ci deps ksai threat-model].freeze

  # The elements that the export knows how to write back. It refuses any other, such
  # as a footnote, math, raw HTML or an HTML comment, rather than guess. A strikethrough
  # is an HTML element with its own mark (`strikethrough?`).
  ELEMENTS = %i[root blank header p text ul ol li strong em codespan codeblock a img br hr
                blockquote smart_quote typographic_sym entity eob].freeze
  # The export refuses every control character in what it writes, so this one can stand
  # for a line break in code while the writer writes a paragraph.
  LINE_BREAK = "\u0001"
  # Marks for the links of a paragraph, while the export reads the end of an entry: a
  # reference to an issue of the repository, a commit, an issue of any repository, and
  # any other piece that is not text. Text is read as `x`, apart from the characters
  # that the end of an entry has, so no character of the changelog can act as a mark.
  MARKS = { issue: 'I', commit: 'C', closes: 'R' }.freeze
  OTHER = 'O'
  TEXT = /[^ (),closes\t\n\v\f\r]/
  # The end of an entry as the pinned release-please writes it
  # (googleapis/release-please-action 45996ed1, dist/): the subject's own `(#N)`, which
  # the subject transform links (index.js:21247), then ` ([abc1234](…/commit/…))`
  # (commit1.hbs:8-9) and `, closes [#N](…)` for each issue that the commit closes
  # (commit1.hbs:15-28). A subject is one line, so these end the entry. A breaking change
  # note has no such end (template1.hbs:9): its first `(#N)`, which release-please links
  # (index.js:45963), is the author's text and stays as text.
  TAIL = /(?: \(I\))?(?: \(C\))?(?:, closes(?: [IR])+)?\z/
  # release-please links a user as the subject transform matches one (index.js:21259),
  # but not a name with a `/`.
  USER = /[a-z0-9](?:-?[a-z0-9]){0,38}/
  VERSION = KongHarnessesChangelogLinks::VERSION
  # The tag of a final release, as STABLE_TAG in tools/lib/tool-versions.js and the
  # versions job read it, so the page and the release data name the same latest
  # release. Change them together.
  STABLE_TAG = /\Av(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\z/
  # The characters that kramdown's typographic symbols show, with a no-break space in the
  # two forms with a space.
  SYMBOLS = { mdash: '—', ndash: '–', hellip: '…', laquo: '«', raquo: '»', laquo_space: "«\u00a0", raquo_space: "\u00a0»" }.freeze
  QUOTES = { lsquo: '‘', rsquo: '’', ldquo: '“', rdquo: '”' }.freeze

  # The site's parser, but a line with a `|` in an entry is text, not a table, and a
  # placeholder such as `<profile>` is text, not HTML, also at the start of a line. The
  # writer escapes both, so the site also shows them as text. An HTML comment or a tag
  # that HTML knows, such as `<del>`, is still read as HTML, so the export refuses it
  # rather than show it, but a `~~` strikethrough stays.
  class Parser < Kramdown::Parser::GFM
    def initialize(source, options)
      super
      @block_parsers.delete(:table)
    end

    # A reference link, a link in angle brackets or one with a title gives the same
    # element as the form that release-please writes, so each link keeps its source.
    def parse_link
      start = @src.pos
      super
      link = @tree.children.last
      link.options[:source] = @src.string.byteslice(start, @src.pos - start) if link && %i[a img].include?(link.type) && !link.options.key?(:source)
    end

    # A placeholder at the start of a line is text too. A comment or a tag that HTML
    # knows is still read as HTML.
    # A strikethrough is an HTML element in kramdown's tree, so it is marked apart from
    # raw HTML, which the export refuses.
    def parse_strikethrough_gfm
      super.tap { |element| element.options[:strikethrough] = true }
    end

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
    # The parser reads a `&` before text such as `#8212;` as a character reference, so
    # a `&` in text is never before one, but the label of a link that went can be.
    def convert_text(el, opts)
      result = super
      return result if opts[:raw_text]

      siblings = @stack.last.children
      after = siblings.drop(siblings.index { |sibling| sibling.equal?(el) } + 1).take_while { |sibling| sibling.type == :text }.map(&:value).join
      result = "#{result.delete_suffix('&')}&amp;" if result.end_with?('&') && after.match?(/\A#?[0-9A-Za-z]+;/)
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

    # release-please writes a `~~` strikethrough of a subject as it is, so the writer
    # writes it back as `~~`.
    def convert_html_element(el, opts)
      el.options[:strikethrough] ? "~~#{inner(el, opts)}~~" : super
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

  # The links that release-please can mean by an address, each with the label that it
  # gives that link: an issue of the repository (`#N`, also a pull request), a commit
  # (its short hash), an issue of any repository that the commit closes
  # (`[owner/]repo#N`, commit1.hbs:18-22), a user (`@name`, index.js:21259) and the
  # compare view of a release (header1.hbs:1-2). The address must be exactly
  # https://github.com and a path, with no port, user, query, fragment or `.` or `..`
  # segment, which a browser resolves to another path.
  def links_of(address)
    scheme, userinfo, host, port, registry, path, opaque, query, fragment = URI.split(address)
    return [] unless scheme == 'https' && host == 'github.com' && [userinfo, port, registry, opaque, query, fragment].all?(&:nil?)
    return [] if path.split('/', -1).intersect?(%w[. ..])

    own = "(?i:#{Regexp.escape(repo)})"
    case path
    when %r{\A/#{own}/commit/([0-9a-f]{40})\z} then [[:commit, Regexp.last_match(1)[0, 7]]]
    when %r{\A/#{own}/compare/v#{VERSION}\.\.\.v(#{VERSION})\z} then [[:compare, Regexp.last_match(1)]]
    when %r{\A/(#{USER})\z} then [[:user, "@#{Regexp.last_match(1)}"]]
    when %r{\A/(?<other_owner>[\w.-]+)/(?<other>[\w.-]+)/issues/(?<number>\d+)\z}
      match = Regexp.last_match
      name = "#{match[:other_owner]}/#{match[:other]}"
      [([:issue, "##{match[:number]}"] if own?(name)), [:closes, "#{name}##{match[:number]}"],
       ([:closes, "#{match[:other]}##{match[:number]}"] if own_owner?(match[:other_owner]))].compact
    else []
    end
  rescue URI::InvalidURIError
    []
  end

  # What a link of the source is: the kind of the first link that its address can mean,
  # when its source is `[label](address)` exactly as release-please writes it, with no
  # title or attribute list. So a reference link, a link in angle brackets and a label
  # with an image, code or an entity in it are no reference.
  def link_kind(element, address)
    return unless element.attr.keys == ['href'] && element.options[:ial].nil?

    links_of(address).find { |_, label| element.options[:source] == "[#{label}](#{address})" }
  end

  # The marks of the pieces of a paragraph, each as long as the text that it stands for.
  # A piece is text, a link as its text and address, which the block gives the kind of,
  # or nil for any other piece.
  def marks_of(pieces)
    pieces.map do |piece|
      next piece.gsub(TEXT, 'x') if piece.is_a?(String)

      (piece && MARKS[yield(*piece)]) || OTHER
    end
  end

  # Where the references that release-please writes at the end of an entry start, in
  # the joined marks, or nil when there are none.
  def tail_start(marks)
    joined = marks.join.rstrip
    start = joined.index(TAIL)
    start unless start == joined.length
  end

  # Takes off the references that release-please writes at the end of a list entry of
  # one paragraph. The text before them stays as it is.
  def without_references(item)
    blocks = item.children.reject { |child| child.type == :blank }
    return item unless blocks.length == 1 && blocks.first.type == :p

    paragraph = blocks.first
    pieces = paragraph.children.map do |child|
      next visible_text(child) if %i[text entity smart_quote typographic_sym].include?(child.type)

      [child, child.attr['href'].to_s] if child.type == :a
    end
    marks = marks_of(pieces) { |link, address| link_kind(link, address)&.first }
    start = tail_start(marks) or return item

    offset = 0
    paragraph.children = paragraph.children.zip(marks).filter_map do |child, mark|
      from = offset
      offset += mark.length
      next child if offset <= start
      next if from >= start
      # Only text can be longer than one character before the end that release-please
      # writes starts.
      next child unless child.type == :text

      child.value = child.value[0, start - from]
      child unless child.value.empty?
    end
    item
  end

  # The source text of the typographic symbols that a version can hold.
  VERSION_SYMBOLS = { ndash: '--', mdash: '---', hellip: '...' }.freeze

  # A release heading shows its version as its tag writes it, not with the dashes that
  # kramdown makes of `--`. release-please links the version to the compare view
  # (header1.hbs:1-2), and that link goes.
  def with_source_version(heading, version)
    link = heading.children.first
    address = link&.attr.to_h['href'].to_s
    if link&.type == :a && link.attr.keys == ['href'] && link.options[:ial].nil? && link.options[:source] == "[#{version}](#{address})"
      heading.children[0, 1] = [Kramdown::Element.new(:text, version)] if links_of(address).include?([:compare, version])
      return heading
    end

    # A heading with no link, as release-please writes the first release.
    source = +''
    taken = heading.children.take_while do |child|
      piece = child.type == :text ? child.value : VERSION_SYMBOLS[child.value] if %i[text typographic_sym].include?(child.type)
      next false if piece.nil? || source.length >= version.length

      source << piece
    end
    return heading unless source.start_with?(version)

    rest = source.delete_prefix(version)
    heading.children[0, taken.length] = [Kramdown::Element.new(:text, version), *(Kramdown::Element.new(:text, rest) unless rest.empty?)]
    heading
  end

  def strikethrough?(element)
    element.type == :html_element && element.options[:strikethrough] == true
  end

  # Refuses an element that the export cannot write back, and drops every attribute but
  # the language of a code block, so no attribute list reaches the page.
  def cleaned(element, entry)
    unless strikethrough?(element)
      raise "The changelog has raw HTML in #{entry}, which the export cannot write back safely." if %i[html_element xml_comment xml_pi].include?(element.type)
      raise "The changelog has #{element.type} in #{entry}, which the export cannot write back safely." unless ELEMENTS.include?(element.type)
    end

    language = element.attr['class'].to_s[/(?:\A|\s)language-(\S+)/, 1] if element.type == :codeblock
    element.attr.clear
    # The site's highlighter stops the build on a language that it does not know.
    element.attr['class'] = "language-#{KongHarnessesChangelogLinks.languages.include?(language) ? language : 'text'}" if language
    element.options.delete(:ial)
  end

  # Kramdown makes the paragraph of a list item loose when a blank line comes after it,
  # also when only a reference definition follows the blank line. The writer writes no
  # blank line after the last item. Kramdown's list parser then reads that item as tight
  # only when the list has one item or an item before it does not start with a loose
  # paragraph.
  def tightened(list)
    blocks = list.children.last&.children.to_a.reject { |child| child.type == :blank }
    earlier = list.children[0...-1].map { |item| item.children.first }
    tight = earlier.empty? || earlier.any? { |first| first.nil? || first.type != :p || first.options[:transparent] }
    blocks.first.options[:transparent] = tight if blocks.length == 1 && blocks.first.type == :p
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

  # Checks an element of an entry and its children: the page has no links, so a link
  # that release-please writes in running text, to an issue as `#N` or to a user as
  # `@name`, becomes its label as text. The export refuses any other link or image that
  # is left after the references at the end of the entry went, and an address in text.
  # The release-please subject transform also links each `#N` in code, as in `&#8212;`,
  # so a link to an issue there becomes `#N` again. The export refuses code that holds
  # any other link. A person then writes the entry again at the source.
  def checked(element, entry)
    address = element.attr['href'].to_s
    kind, label = link_kind(element, address) if element.type == :a
    cleaned(element, entry)
    hidden(element, entry)
    case element.type
    when :a, :img
      return [Kramdown::Element.new(:text, label)] if %i[issue user].include?(kind)

      raise "The changelog has a link in #{entry}, and the page shows no links. Only the references that release-please writes go. Write the entry without the link at the source."
    when :codespan, :codeblock
      element.value = without_subject_links(element.value) if element.type == :codespan
      raise "The changelog has code with a line that starts a block in #{entry}, which the export cannot write back safely." if element.type == :codespan && code_breaks_paragraph?(element)
      raise "The changelog has a link in the code of #{entry}. Write the code without the link at the source." if types_of(parse(element.value)).intersect?(%i[a img])
      # The writer writes nothing for a code block of only white space.
      return [] if element.type == :codeblock && element.value.strip.empty?
    else
      children = element.children.flat_map { |child| checked(child, entry) }
      element.children = separated(children.flat_map { |child| %i[strong em].include?(child.type) ? trimmed(child) : [child] })
      if %i[p header].include?(element.type) && KongHarnessesChangelogLinks.address?(prose_of(element))
        raise "The changelog has an address in the text of #{entry}. The page shows no addresses, so write the entry without it at the source. A value such as `go@1.21` can go in backticks."
      end
      without_loose_breaks(element) if %i[p header strong em].include?(element.type)
      tightened(element) if %i[ul ol].include?(element.type)
      # A paragraph or block quote with nothing in it shows nothing, and the writer
      # cannot write an empty one.
      return [] if %i[p blockquote].include?(element.type) && element.children.all? { |child| child.type == :blank }
    end
    [element]
  end

  # The links that the release-please subject transform writes in code, to an issue
  # (index.js:21247) and to a user (index.js:21259), each with its own number or name as
  # its label.
  def without_subject_links(code)
    code.gsub(%r{\[#(\d+)\]\(https://github\.com/(?i:#{Regexp.escape(repo)})/issues/(\d+)\)|\[@(#{USER})\]\(https://github\.com/(#{USER})\)}) do
      match = Regexp.last_match
      if match[1] then match[1] == match[2] ? "##{match[1]}" : match[0]
      else match[3] == match[4] ? "@#{match[3]}" : match[0]
      end
    end
  end

  # Refuses an entity of a hidden code point, as KongHarnessesChangelogLinks.hidden_text?
  # reads one, and an entity that names no character. `raw_checked` reads the raw text.
  def hidden(element, entry)
    return unless element.type == :entity

    point = element.value.code_point
    raise "The changelog has a character reference to no character in #{entry}. Write the entry without it at the source." if point > 0x10ffff || (0xd800..0xdfff).cover?(point)

    hidden_in(entry) if KongHarnessesChangelogLinks.hidden_text?(element.value.char)
  end

  def hidden_in(entry)
    raise "The changelog has a hidden code point in #{entry}, which the page must not show. Write the entry without it at the source."
  end

  # Kramdown changes line ends and drops white space at the end of a paragraph before
  # the tree has them, so the export also reads the lines of each element that it keeps
  # in the source as it came. `lines` are those lines, each with its line end.
  def raw_checked(element, lines, entry)
    from = element.options[:location] or return
    hidden_in(entry) if lines[(from - 1)...element.options.fetch(:last_line)].to_a.any? { |line| KongHarnessesChangelogLinks.hidden_text?(line.delete_suffix("\n")) }
  end

  # Gives each element of a list that is not blank the last line of its source, the
  # line before the next one, or `last` for the last element.
  def with_last_lines(elements, last)
    placed = elements.select { |element| element.options[:location] }
    placed.each_cons(2) { |element, after| element.options[:last_line] = after.options[:location] - 1 }
    placed.last&.options&.store(:last_line, last)
    elements
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

  # White space next to a line break does not show, the writer gives two line breaks in
  # a row as the end of the paragraph, and it drops a line break at the start or the end
  # of a block, so the export keeps only what shows. Bold or emphasis moves its line
  # breaks at the edges out to the block, through `trimmed`.
  def without_loose_breaks(block)
    children = block.children
    children = children.reject.with_index do |child, index|
      near = [index.zero? ? nil : children[index - 1], children[index + 1]]
      child.type == :text && child.value.strip.empty? && near.any? { |piece| piece.nil? || piece.type == :br }
    end
    children = children.each_with_object([]) { |child, list| list << child unless child.type == :br && list.last&.type == :br }
    if %i[p header].include?(block.type)
      children.shift while children.first&.type == :br
      children.pop while children.last&.type == :br
    end
    block.children = children
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

  # The text that a reader sees of a piece.
  def visible_text(piece)
    case piece.type
    when :text then piece.value
    # Kramdown has no character for a code point above U+10FFFF, which `hidden` refuses.
    when :entity then piece.value.char&.scrub || "\uFFFD"
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
  #
  # A refusal names the place of an entry, as its release, section and entry number, and
  # no text of it: GitHub masks only the exact text of a secret, so the job log would
  # show the repository in another letter case. The numbers count the source, also the
  # tooling entries that the page drops, because a person fixes the entry there.
  def public_section(title, content, lines, release)
    name = text_of(title).strip
    return [[], []] unless USER_SECTIONS.include?(name)

    where = "#{release}, section #{name}"
    entries = 0
    blocks = 0
    sources = [copy(title)]
    kept = content.flat_map do |element|
      blocks += 1 unless element.type == :blank
      if %i[ul ol].include?(element.type)
        cleaned(element, where)
        with_last_lines(element.children, element.options[:last_line])
        numbers = element.children.each_with_index.to_h { |item, index| [item, entries + index + 1] }.compare_by_identity
        entries += element.children.length
        # An upgrade step stays whatever its scope, because a user must still do it.
        element.children = element.children.reject { |item| name != BREAKING_CHANGES && TOOLING_SCOPES.include?(scope(item)) }
        next [] if element.children.empty?

        sources << copy(element)
        # release-please writes its entries in a `*` list.
        element.children = element.children.flat_map do |item|
          entry = "#{where}, entry #{numbers.fetch(item)}"
          raw_checked(item, lines, entry)
          checked(element.type == :ul && name != BREAKING_CHANGES ? without_references(item) : item, entry)
        end
        [tightened(element)]
      else
        sources << copy(element)
        raw_checked(element, lines, "#{where}, block #{blocks}")
        checked(element, "#{where}, block #{blocks}")
      end
    end
    return [[], []] if kept.all? { |element| element.type == :blank }

    raw_checked(title, lines, "the heading of section #{name} of #{release}")
    [[*checked(title, "the heading of section #{name} of #{release}"), *kept], sources]
  end

  def prerelease?(version)
    version.match?(/\A\d+\.\d+\.\d+-/)
  end

  # Why a published release that is no prerelease by its version is no final release.
  def not_final(version)
    "v#{version}".match?(STABLE_TAG) ? 'is marked as a pre-release' : 'has no vX.Y.Z tag'
  end

  def core(version)
    version[/\A\d+\.\d+\.\d+/]
  end

  # Only text of a published release reaches the site. release-please writes a section
  # when the release pull request merges, before the release job publishes it, and a
  # prerelease can be published before its final release, or for a final release that
  # never comes. So a section stays only when its heading names a final release
  # (`finals`, a STABLE_TAG release that is not a draft and not marked as a prerelease,
  # without the v), or a prerelease (`published`, any release that is not a draft) once
  # a final release of the same X.Y.Z is out. The prerelease's section stays after that,
  # because release-please takes the version in its manifest, the prerelease, as the
  # last release, so the final section lists only the commits after it. The export
  # writes each release that it leaves out, and why, to `log`, and each final release
  # that has no section. Text before the first heading goes. A heading with no version,
  # or no heading for `highest`, the highest final release, stops the sync, so a
  # changelog that lost its sections cannot empty the page. So does a changelog with no
  # entries for users left.
  def export(markdown, published:, highest:, finals: published.select { |version| "v#{version}".match?(STABLE_TAG) }, log: $stderr)
    releases = []
    # The lines as kramdown counts them, which also ends a line at a lone CR.
    lines = markdown.scan(/[^\r\n]*(?:\r\n?|\n)|[^\r\n]+\z/)
    source = parse(markdown)
    with_last_lines(source.children, lines.length)
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

    # The export refuses a release heading that does not show exactly the version of its
    # line, and a second release heading with the version of an earlier one, so a place
    # on the page names one release for each heading.
    shown = release_headings(source).map { |node| KongHarnessesChangelogLinks.shown_version(node) }
    versions = []
    releases.zip(shown).each do |release, version_shown|
      line = release[:heading].options[:location]
      version = version_of(release[:heading], lines) or raise("The changelog has a release heading with no version on line #{line}.")
      raise "The changelog has a release heading on line #{line} that does not show exactly its version, so the export refuses it." unless version_shown == version
      raise "The changelog has a second release heading for #{version} on line #{line}, so the export refuses it." if versions.include?(version)

      versions << version
    end
    raise "The changelog has no section for #{highest}, the highest final release." unless finals.include?(highest) && versions.include?(highest)

    root = Kramdown::Element.new(:root, nil, nil, source.options.slice(:encoding))
    original = Kramdown::Element.new(:root, nil, nil, source.options.slice(:encoding))
    kept = []
    releases.zip(versions).each do |release, version|
      reason = if finals.include?(version) then nil
               elsif !published.include?(version) then 'is not published'
               elsif !prerelease?(version) then not_final(version)
               elsif !published.include?(core(version)) then "is a pre-release, and no #{core(version)} release is published"
               elsif !finals.include?(core(version)) then "is a pre-release, and the #{core(version)} release #{not_final(core(version))}"
               end
      sections = reason ? [] : release[:sections].map { |section| public_section(section[:title], section[:content], lines, "release #{version}") }
      reason ||= 'has no entries for users' if sections.all? { |kept, _| kept.empty? }
      next log.puts("Left out the changelog section for #{version}, which #{reason}.") if reason

      raw_checked(release[:heading], lines, "the heading of release #{version}")
      original.children.concat([copy(release[:heading])], *sections.map(&:last))
      root.children.concat(checked(with_source_version(release[:heading], version), "the heading of release #{version}"), *sections.map(&:first))
      kept << version
    end
    raise 'The changelog has no entries for users in its published releases.' if root.children.empty?

    (finals - versions).sort_by { |version| Gem::Version.new(version) }.reverse_each do |version|
      log.puts("The changelog has no section for #{version}, a published final release.")
    end

    output, = Writer.convert(root, options)
    output = "#{output.sub(/\A\n+/, '').sub(/\n+\z/, '')}\n"
    written(output, root, original, lines, releases: kept)
  end

  # The version of a release heading as its line in the source writes it, because
  # kramdown shows `--` in a heading as a dash, or nil.
  def version_of(heading, lines)
    location = heading.options[:location] or return
    raw = lines[location - 1].to_s.sub(/\A {0,3}\#{2}[ \t]+/, '').rstrip
    raw[KongHarnessesChangelogLinks::HEADING_VERSION, 2]
  end

  # The release headings of the source, as KongHarnessesChangelogLinks.release_of takes
  # them: each as its version, read from its line, and the version that it shows. With
  # no source, each of `releases` shows its own version. A heading with no version on
  # its line names its release by the version that it shows, and only by a version, so
  # no text of the changelog reaches an error.
  def releases_of(source, lines, releases)
    return releases.map { |version| [version, version] } unless source

    release_elements(source).zip(release_headings(source)).map do |heading, node|
      shown = KongHarnessesChangelogLinks.shown_version(node)
      [version_of(heading, lines) || shown || 'with no version', shown]
    end
  end

  def release_elements(source)
    source.children.select { |element| element.type == :header && element.options[:level] == 2 }
  end

  # The release headings of the source as the page shows them, one for each of
  # `release_elements`.
  def release_headings(source)
    root = Kramdown::Element.new(:root, nil, nil, encoding: Encoding::UTF_8)
    root.children.concat(release_elements(source))
    html(root).element_children
  end

  def types_of(element)
    [element.type, *element.children.flat_map { |child| types_of(child) }]
  end

  def code_of(element)
    return [element.value.chomp] if %i[codespan codeblock].include?(element.type)

    element.children.flat_map { |child| code_of(child) }
  end

  BLOCKS = %w[p li ul ol h1 h2 h3 h4 h5 h6 blockquote pre hr br].freeze

  # Kramdown's HTML converter as the sync job loads it. The site and its specs also load
  # app/_plugins/kramdown_external_links.rb, which gives a link `target` and `rel` and
  # writes them into the tree.
  class Html < Kramdown::Converter::Html
    def convert_a(element, indent)
      respond_to?(:orig_convert_a, true) ? orig_convert_a(element, indent) : super
    end
  end

  def html(tree)
    Nokogiri::HTML5.fragment(Html.convert(tree, options).first)
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
  # run of white space as one space, and with the references that release-please writes
  # at the end of a `*` list entry taken out. It reads them from the HTML, not from the
  # tree of the export.
  def reading(fragment)
    # A release heading shows its version as its tag writes it, so `--` in the version
    # reads the same as the dash that kramdown makes of it in the source.
    fragment.css('h2').each do |heading|
      heading.content = heading.text.sub(KongHarnessesChangelogLinks::HEADING_START) { |version| KongHarnessesChangelogLinks.written_version(version) }
    end
    section = nil
    fragment.children.each do |node|
      section = node.text.strip if node.name == 'h3'
      next unless node.name == 'ul'

      node.element_children.each { |item| without_rendered_references(item) } unless section == BREAKING_CHANGES
    end
    text = +''
    add = ->(value) { value.each_char { |char| text << (char.match?(/\s/) ? ' ' : char) unless char.match?(/\s/) && (text.empty? || text.end_with?(' ')) } }
    walk = lambda do |node|
      next add.call(code_without_subject_links(node.text)) if node.text? && node.parent&.name == 'code' && node.parent.parent&.name != 'pre'
      next add.call(node.text) if node.text?
      next add.call(node['alt'].to_s) if node.name == 'img'

      add.call(' ') if BLOCKS.include?(node.name)
      node.children.each(&walk)
      add.call(' ') if BLOCKS.include?(node.name)
    end
    fragment.children.each(&walk)
    text.strip
  end

  # The release whose text the export would change, which a refusal names in place of
  # the text. When the two have other releases, it names the first block that reads
  # differently.
  def changed_release(source, tree, releases)
    parts = [html(source), html(tree)].map { |fragment| releases_in(fragment) }
    unless parts.map(&:length).uniq == [releases.length]
      return changed_block(html(source), html(tree), releases) { |before, after| reading(in_section(before)) == reading(in_section(after)) } || 'the changelog'
    end

    index = parts[0].zip(parts[1]).index { |before, after| reading(before) != reading(after) }
    index ? "release #{KongHarnessesChangelogLinks.release_of(release_headings(source)[index], releases)}" : 'the changelog'
  end

  # The first block of `expected` that `actual` does not show the same by `same`, and in
  # a list its first entry that differs, named as the page check names a place, or nil.
  # A block that only `actual` has is named there.
  def changed_block(expected, actual, releases = nil, &same)
    pairs = lambda do |nodes|
      runs = nodes.map { |list| list.reject { |node| node.text? && node.text.strip.empty? } }
      (0...runs.map(&:length).max).lazy.map { |index| runs.map { |run| run[index] } }.find { |pair| pair.include?(nil) || !same.call(*pair) }
    end
    pair = pairs.call([expected, actual].map(&:children)) or return

    if pair.none?(&:nil?) && %w[ul ol].include?(pair[0].name) && pair[0].name == pair[1].name
      pair = pairs.call(pair.map(&:element_children)) || pair
    end
    KongHarnessesChangelogLinks.place(pair.compact.first, releases)
  end

  # A block, or a list entry in a list of its own, with the heading of its section, so
  # that `reading` takes the same references off it as off the whole page.
  def in_section(node)
    top = KongHarnessesChangelogLinks.top_of(node)
    heading = top.previous_element
    heading = heading.previous_element while heading && !%w[h2 h3].include?(heading.name)
    Nokogiri::HTML5.fragment('').tap do |part|
      part.add_child(heading.dup) if heading&.name == 'h3' && top.name != 'h3'
      part.add_child(node.name == 'li' ? node.parent.dup(0).tap { |list| list.add_child(node.dup) } : node.dup)
    end
  end

  def releases_in(fragment)
    fragment.children.slice_before { |node| node.name == 'h2' }.select { |run| run.first.name == 'h2' }.map do |run|
      Nokogiri::HTML5.fragment('').tap { |part| run.each { |node| part.add_child(node.dup) } }
    end
  end

  # The end of a list item of one paragraph: of all its nodes, where a block after the
  # text is a piece that is not a reference, or of its one `p` when the list is loose.
  def without_rendered_references(item)
    first = item.children.find { |node| node.element? || !node.text.strip.empty? }
    run = item.children.to_a
    if first&.name == 'p'
      return unless item.element_children.length == 1

      run = first.children.to_a
    end
    pieces = run.map do |node|
      next node.text if node.text?

      [node, node['href'].to_s] if node.name == 'a'
    end
    marks = marks_of(pieces) { |link, address| rendered_kind(link, address) }
    start = tail_start(marks) or return

    offset = 0
    run.zip(marks).each do |node, mark|
      from = offset
      offset += mark.length
      next if offset <= start

      from >= start ? node.remove : node.content = node.text[0, start - from]
    end
  end

  # The text of a code span with each `[#N](…/issues/N)` of the repository as `#N` and
  # each `[@name](https://github.com/name)` as `@name`, read with its own string
  # compares, apart from `without_subject_links`.
  def code_without_subject_links(code)
    [['[#', repo, '/issues/', /\A\d+\z/], ['[@', '', '', /\A[a-z0-9](?:-?[a-z0-9]){0,38}\z/]].reduce(code) do |text, (open, own, path, label)|
      text.split(open, -1).each_with_index.map do |part, index|
        next part if index.zero?

        name, rest = part.split('](https://github.com/', 2)
        # GitHub names are not case-sensitive, so the owner and the name match in any
        # letter case. The path keeps the case that release-please writes.
        next "#{open}#{part}" unless rest && name.match?(label) && rest[0, own.length].casecmp?(own) && rest[own.length, path.length] == path

        rest = rest[(own.length + path.length)..]
        next "#{open}#{part}" unless rest.start_with?("#{name})")

        "#{open[1]}#{name}#{rest.delete_prefix("#{name})")}"
      end.join
    end
  end

  # The kind of a reference at the end of an entry, read from the HTML with its own
  # string compares, apart from the export's reading of the address, so that a mistake
  # in one of them does not pass the other.
  def rendered_kind(link, address)
    site = 'https://github.com/'
    # A title or an attribute list is no reference.
    return unless address.start_with?(site) && link.attributes.keys == ['href']

    owner, repository, kind, id, *rest = address.delete_prefix(site).split('/', -1)
    return unless rest.empty? && [owner, repository].all? { |part| part.to_s.match?(/\A[\w.-]+\z/) && !part.match?(/\A\.\.?\z/) }

    own = "#{owner}/#{repository}".casecmp?(repo)
    label = ->(text) { html(parse("[#{text}](#{address})")).at_css('a')&.inner_html == link.inner_html }
    if kind == 'commit' && own && id.to_s.match?(/\A[0-9a-f]{40}\z/)
      :commit if label.call(id[0, 7])
    elsif kind == 'issues' && id.to_s.match?(/\A\d+\z/)
      return :issue if own && label.call("##{id}")

      :closes if ["#{owner}/#{repository}##{id}", ("#{repository}##{id}" if owner.casecmp?(repo.split('/').first))].compact.any?(&label)
    end
  end

  # The writer is not built for the GFM parser, so the export renders its own output
  # again with the parser and options of the site, tables and HTML too, and refuses it
  # unless the HTML shows the same as that of the tree that it wrote. It also refuses the
  # tree unless a reader sees the same text in it as in the source, with only the
  # references at the end of an entry taken out, which it reads from a second rendering
  # of the source. It also refuses a code block that lost its language.
  def written(output, tree, source = nil, lines = [], releases: [])
    releases = releases_of(source, lines, releases)
    reread, = Kramdown::Parser::GFM.parse(output, options)
    if types_of(reread).intersect?(%i[a img])
      link = html(reread).at_css('a, img')
      raise "The export would write a link back in #{link ? KongHarnessesChangelogLinks.place(link, releases) : 'the page'}, so it refuses the changelog."
    end
    unless page(html(reread)) == page(html(tree))
      raise "The export would change what a reader sees in #{changed_block(html(tree), html(reread), releases) { |before, after| page(before) == page(after) } || 'the page'}, so it refuses the changelog."
    end
    return output unless source

    link = unwritten_link(source, lines, releases)
    raise "The changelog has a link that release-please does not write so in #{link}, and the export refuses it." if link

    before = reading(html(source))
    after = reading(html(tree))
    raise "The export would change the text that a reader sees in #{changed_release(source, tree, releases)}, so it refuses the changelog." unless before == after
    code = [html(source), html(tree)].map { |fragment| code_blocks(fragment) }
    expected = code[0].map { |block| language_of(block) }.map { |language| language && (KongHarnessesChangelogLinks.languages.include?(language) ? language : 'text') }
    index = (0...code.map(&:length).max).find { |number| code.any? { |blocks| blocks[number].nil? } || expected[number] != language_of(code[1][number]) }
    raise "The export would change the language of the code block in #{code_block_place(code.find { |blocks| blocks[index] }, index, releases)}, so it refuses the changelog." if index

    output
  end

  # A reference link, a link in angle brackets, an escaped label or a character
  # reference in a label or an address gives the same HTML as `[label](address)`, the form that
  # release-please writes. So each link of an element must have that form in its own
  # text, the span that kramdown parsed for it, and that span must be on its line of the
  # source, so no other text of the line counts for it. `lines` are the lines of the
  # source, with their line ends.
  #
  # It gives the place of the first such element, as its first line in the source and its
  # release, or nil.
  def unwritten_link(source, lines, releases)
    headings = release_headings(source)
    count = 0
    source.children.each do |element|
      count += 1 if element.type == :header && element.options[:level] == 2
      items = %i[ul ol].include?(element.type) ? element.children : [element]
      found = items.find { |item| unwritten_link_in?(item, lines) } or next

      release = count.zero? ? 'the text before the first release' : "release #{KongHarnessesChangelogLinks.release_of(headings[count - 1], releases)}"
      return "the entry or block on line #{found.options[:location]}, in #{release}"
    end
    nil
  end

  def unwritten_link_in?(element, lines)
    links = links_in(element)
    # Raw HTML gives an anchor with no parsed link, so it has no source span to check.
    # The HTML parser drops a link inside some elements, such as `<select>`, so the
    # count alone lets such a link stand in for a raw anchor.
    return true if raw_anchor_in?(element) || anchors_in(element) != links.length

    links.any? do |link|
      source = link.options[:source]
      line = lines[link.options[:location] - 1] if link.options[:location]
      # release-please writes no attribute list, also none that gives no attribute. The
      # parser tells one from the same characters as text, which the lines cannot.
      next true if link.options[:ial] || source.nil? || !line.to_s.include?(source)

      # A label that release-please writes has no `\` or `&`, and its address is the one
      # that a browser follows, with no character reference.
      address = source[/\A\[[^\[\]\\&\n]*\]\((\S+)\)\z/, 1] or next true
      paragraph = Kramdown::Element.new(:p).tap { |p| p.children << link }
      address != html(Kramdown::Element.new(:root, nil, nil, encoding: Encoding::UTF_8).tap { |root| root.children << paragraph }).at_css('a')['href']
    end
  end

  def links_in(element)
    [*(element if element.type == :a), *element.children.flat_map { |child| links_in(child) }]
  end

  def raw_anchor_in?(element)
    (element.type == :html_element && element.value.to_s.casecmp?('a')) || element.children.any? { |child| raw_anchor_in?(child) }
  end

  # The anchors in the HTML of an element, a list item in a list of its own.
  def anchors_in(element)
    root = Kramdown::Element.new(:root, nil, nil, encoding: Encoding::UTF_8)
    root.children << (element.type == :li ? Kramdown::Element.new(:ul).tap { |list| list.children << element } : element)
    html(root).css('a').length
  end

  def code_blocks(fragment)
    # A code block of only white space goes.
    fragment.css('pre code').reject { |code| code.text.strip.empty? }
  end

  def language_of(code)
    code['class'].to_s[/(?:\A|\s)language-(\S+)/, 1]
  end

  # A code block as its number in its section on the page, with the release and section.
  def code_block_place(blocks, index, releases)
    sections = blocks[0..index].map { |code| KongHarnessesChangelogLinks.section_of(code, releases) }
    "#{sections.last}, code block #{sections.count(sections.last)} on the page"
  end

  # `get` takes a path of the GitHub API and an Accept type, and gives the status code
  # and the body.
  def fetch(get)
    releases = []
    (1..).each do |page|
      status, body = get.call("/repos/#{repo}/releases?per_page=100&page=#{page}", 'application/vnd.github+json')
      raise "GitHub API request for #{repo} releases failed (#{status}). Pass a GitHub token in the GH_TOKEN environment variable." unless status == 200

      batch = JSON.parse(body)
      releases.concat(batch)
      break if batch.length < 100
    end
    # The highest final release, not the newest or the one marked latest: an older
    # release can be marked as the latest by hand, and a backport published after a newer
    # release must not replace it.
    finals = releases.reject { |release| release['draft'] || release['prerelease'] }
                     .map { |release| release['tag_name'] }
                     .grep(STABLE_TAG)
                     .map { |tag| tag.delete_prefix('v') }
    highest = finals.max_by { |version| Gem::Version.new(version) }
    raise "#{repo} has no published vX.Y.Z release." unless highest

    # Every published release, prereleases too, but no draft.
    published = releases.reject { |release| release['draft'] }
                        .map { |release| release['tag_name'] }
                        .grep(/\Av#{VERSION}\z/)
                        .map { |tag| tag.delete_prefix('v') }
    # main, not the tag, so a correction to an earlier entry reaches the page.
    status, changelog = get.call("/repos/#{repo}/contents/CHANGELOG.md?ref=main", 'application/vnd.github.raw')
    raise "GitHub API request for #{repo} CHANGELOG.md on main failed (#{status})." unless status == 200

    ["v#{highest}", export(changelog.force_encoding('UTF-8'), published: published, finals: finals, highest: highest)]
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
