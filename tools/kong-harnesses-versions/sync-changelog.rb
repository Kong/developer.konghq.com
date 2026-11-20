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
  GITHUB = 'https://github.com'
  # release-please links a user as the subject transform matches one (index.js:21259),
  # but not a name with a `/`.
  USER = /[a-z0-9](?:-?[a-z0-9]){0,38}/
  # A version as release-please reads one (index.js:59193), with a prerelease and a build
  # part made of the characters that semver allows.
  VERSION = /\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?/
  # The characters that kramdown's typographic symbols show, with a no-break space in the
  # two forms with a space.
  SYMBOLS = { mdash: '—', ndash: '–', hellip: '…', laquo: '«', raquo: '»', laquo_space: "«\u00a0", raquo_space: "\u00a0»" }.freeze
  QUOTES = { lsquo: '‘', rsquo: '’', ldquo: '“', rdquo: '”' }.freeze

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

  # The links that release-please can mean by an address, each with the label that it
  # gives that link: an issue of the repository (`#N`, also a pull request), a commit
  # (its short hash), an issue of any repository that the commit closes
  # (`[owner/]repo#N`, commit1.hbs:18-22), a user (`@name`, index.js:21259) and the
  # compare view of a release (header1.hbs:1-2). The address must be exactly
  # https://github.com and a path, with no port, user, query or fragment.
  def links_of(address)
    scheme, userinfo, host, port, registry, path, opaque, query, fragment = URI.split(address)
    return [] unless scheme == 'https' && host == 'github.com' && [userinfo, port, registry, opaque, query, fragment].all?(&:nil?)

    owner, repository = REPO.split('/').map { |part| Regexp.escape(part) }
    case path
    when %r{\A/#{owner}/#{repository}/commit/([0-9a-f]{40})\z} then [[:commit, Regexp.last_match(1)[0, 7]]]
    when %r{\A/#{owner}/#{repository}/compare/v#{VERSION}\.\.\.v(#{VERSION})\z} then [[:compare, Regexp.last_match(1)]]
    when %r{\A/(#{USER})\z} then [[:user, "@#{Regexp.last_match(1)}"]]
    when %r{\A/(?<other_owner>[\w.-]+)/(?<other>[\w.-]+)/issues/(?<number>\d+)\z}
      match = Regexp.last_match
      name = "#{match[:other_owner]}/#{match[:other]}"
      [([:issue, "##{match[:number]}"] if name == REPO), [:closes, "#{name}##{match[:number]}"],
       ([:closes, "#{match[:other]}##{match[:number]}"] if match[:other_owner] == REPO.split('/').first)].compact
    else []
    end
  rescue URI::InvalidURIError
    []
  end

  # What a link of the source is: the kind of the first link that its address can mean
  # and whose label is the one that release-please writes, element for element, so a
  # label with an image, code or an entity in it is no reference.
  def link_kind(element, address)
    links_of(address).find { |_, label| shape(element.children) == shape(label_children(label)) }
  end

  # The elements of a label as the site's parser reads it inside a link.
  def label_children(label)
    paragraph = parse("[#{label}](#{GITHUB})").children.first
    link = paragraph.children.first if paragraph&.type == :p && paragraph.children.length == 1
    link.children if link&.type == :a
  end

  def shape(elements)
    elements&.map { |element| [element.type, element.value.to_s, shape(element.children)] }
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

  # A release heading as release-please writes it links its version to the compare view
  # (header1.hbs:1-2). The version stays as text.
  def without_compare_link(heading, version)
    link = heading.children.first
    return heading unless link&.type == :a && link.children.map(&:type) == [:text] && link.children.first.value == version
    return heading unless links_of(link.attr['href'].to_s).include?([:compare, version])

    heading.children[0, 1] = link.children
    heading
  end

  # Refuses an element that the export cannot write back, and drops every attribute but
  # the language of a code block, so no attribute list reaches the page.
  def cleaned(element)
    raise 'The changelog has raw HTML or a strikethrough, which the export cannot write back safely.' if %i[html_element xml_comment xml_pi].include?(element.type)
    raise "The changelog has #{element.type}, which the export cannot write back safely." unless ELEMENTS.include?(element.type)

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
  # It also refuses code that holds a link, as the release-please subject transform
  # writes one for each `#N` and `@user`, also in code. A person then writes the entry
  # again at the source.
  def checked(element, entry)
    address = element.attr['href'].to_s
    cleaned(element)
    hidden(element, entry)
    case element.type
    when :a, :img
      kind, label = link_kind(element, address) if element.type == :a
      return [Kramdown::Element.new(:text, label)] if %i[issue user].include?(kind)

      raise "The changelog has a link in #{entry}, and the page shows no links. Only the references that release-please writes go. Write the entry without the link at the source."
    when :codespan, :codeblock
      raise 'The changelog has code with a line that starts a block, which the export cannot write back safely.' if element.type == :codespan && code_breaks_paragraph?(element)
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

  # Refuses a control, bidirectional or noncharacter code point, raw or as an entity, and
  # an entity that names no character.
  def hidden(element, entry)
    if element.type == :entity
      point = element.value.code_point
      raise "The changelog has a character reference to no character in #{entry}. Write the entry without it at the source." if point > 0x10ffff || (0xd800..0xdfff).cover?(point)
    end
    value = element.type == :entity ? element.value.char : element.value
    return unless %i[text codespan codeblock entity].include?(element.type) && value.match?(KongHarnessesChangelogLinks::HIDDEN)

    raise "The changelog has a control, bidirectional or noncharacter code point in #{entry}, which the page must not show. Write the entry without it at the source."
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
    when :entity then piece.value.char.scrub
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

  # The start of an entry, as the refusals name it.
  def name_of(element)
    text_of(element).gsub(/\s+/, ' ').strip[0, 120].inspect
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
        next [] if element.children.empty?

        sources << copy(element)
        # release-please writes its entries in a `*` list.
        element.children = element.children.flat_map do |item|
          checked(element.type == :ul && name != BREAKING_CHANGES ? without_references(item) : item, name_of(item))
        end
        [tightened(element)]
      else
        sources << copy(element)
        checked(element, name_of(element))
      end
    end
    kept.all? { |element| element.type == :blank } ? [[], []] : [[*checked(title, name.inspect), *kept], sources]
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
      raw[/\A\[?(#{VERSION})(?=[\]\s(]|\z)/, 1] ||
        raise("The changelog has a release heading with no version: #{raw}")
    end
    raise "The changelog has no section for #{highest}, the highest published release." unless versions.include?(highest)

    root = Kramdown::Element.new(:root, nil, nil, source.options.slice(:encoding))
    original = Kramdown::Element.new(:root, nil, nil, source.options.slice(:encoding))
    releases.zip(versions).each do |release, version|
      next unless published.include?(version) && published.include?(version[/\A\d+\.\d+\.\d+/])

      sections = release[:sections].map { |section| public_section(section[:title], section[:content]) }
      next if sections.all? { |kept, _| kept.empty? }

      original.children.concat([copy(release[:heading])], *sections.map(&:last))
      root.children.concat(checked(without_compare_link(release[:heading], version), name_of(release[:heading])), *sections.map(&:first))
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
  # run of white space as one space, and with the references that release-please writes
  # at the end of a `*` list entry taken out. It reads them from the HTML, not from the
  # tree of the export.
  def reading(fragment)
    section = nil
    fragment.children.each do |node|
      section = node.text.strip if node.name == 'h3'
      next unless node.name == 'ul'

      node.element_children.each { |item| without_rendered_references(item) } unless section == BREAKING_CHANGES
    end
    text = +''
    add = ->(value) { value.each_char { |char| text << (char.match?(/\s/) ? ' ' : char) unless char.match?(/\s/) && (text.empty? || text.end_with?(' ')) } }
    walk = lambda do |node|
      next add.call(node.text) if node.text?
      next add.call(node['alt'].to_s) if node.name == 'img'

      add.call(' ') if BLOCKS.include?(node.name)
      node.children.each(&walk)
      add.call(' ') if BLOCKS.include?(node.name)
    end
    fragment.children.each(&walk)
    text.strip
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

  # The kind of a reference at the end of an entry, read from the HTML with its own
  # string compares, apart from the export's reading of the address, so that a mistake
  # in one of them does not pass the other.
  def rendered_kind(link, address)
    site = 'https://github.com/'
    return unless address.start_with?(site)

    owner, repository, kind, id, *rest = address.delete_prefix(site).split('/', -1)
    return unless rest.empty? && [owner, repository].all? { |part| part.to_s.match?(/\A[\w.-]+\z/) }

    own = "#{owner}/#{repository}" == REPO
    label = ->(text) { html(parse("[#{text}](#{address})")).at_css('a')&.inner_html == link.inner_html }
    if kind == 'commit' && own && id.to_s.match?(/\A[0-9a-f]{40}\z/)
      :commit if label.call(id[0, 7])
    elsif kind == 'issues' && id.to_s.match?(/\A\d+\z/)
      return :issue if own && label.call("##{id}")

      :closes if ["#{owner}/#{repository}##{id}", ("#{repository}##{id}" if owner == REPO.split('/').first)].compact.any?(&label)
    end
  end

  # The writer is not built for the GFM parser, so the export renders its own output
  # again with the parser and options of the site, tables and HTML too, and refuses it
  # unless the HTML shows the same as that of the tree that it wrote. It also refuses the
  # tree unless a reader sees the same text in it as in the source, with only the
  # references at the end of an entry taken out, which it reads from a second rendering
  # of the source. It also refuses a code block that lost its language.
  def written(output, tree, source = nil)
    reread, = Kramdown::Parser::GFM.parse(output, options)
    raise 'The export would write a link back, so it refuses the changelog.' if types_of(reread).intersect?(%i[a img])
    raise 'The export would change what a reader sees, so it refuses the changelog.' unless page(html(reread)) == page(html(tree))
    return output unless source

    # The HTML parser reads a character reference in a link, which release-please never
    # writes, so Check B reads the HTML that kramdown writes for each link.
    if Kramdown::Converter::Html.convert(source, options).first.scan(%r{<a\b.*?</a>}m).any? { |link| link.include?('&') }
      raise 'The changelog has a character reference in a link, so the export refuses it.'
    end

    before = reading(html(source))
    after = reading(html(tree))
    unless before == after
      at = (0...before.length).find { |index| before[index] != after[index] } || before.length
      raise "The export would change the text that a reader sees near #{before[[at - 40, 0].max, 80].inspect}, so it refuses the changelog."
    end
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
                        .grep(/\Av#{VERSION}\z/)
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
