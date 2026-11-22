# frozen_string_literal: true

require 'cgi'
require 'json'
require 'jekyll'
require 'nokogiri'
require 'yaml'

# sync-changelog.rb takes out or refuses every link of the kong-harnesses changelog,
# because the page has none. This check does not trust that: it renders the result with
# the site's own Markdown converter, reads the HTML with a real parser, and stops the
# sync when the page would hold anything that a browser could follow. It allows only
# plain elements with plain attributes, so no form of an address in an attribute can
# pass. It reads the text of each element as a reader sees it, joined across inline
# markup such as bold, and refuses `//`, `www.`, `mailto:`, `xmpp:` and an `@` between
# two characters of a name, as in `user@host`, outside code. Text in code is not a link,
# but it still must not name the repository that publishes the releases, also with a
# `.` or `..` segment in a GitHub address. It also refuses a hidden code point, which
# shows nothing or changes the order of the text around it.
module KongHarnessesChangelogLinks
  module_function

  ROOT = File.expand_path('../..', __dir__)
  DATA_FILE = File.join(ROOT, 'app/_data/kong-harnesses/changelog.json')
  SHIKI = File.join(ROOT, 'app/_plugins/converters/shiki.rb')

  # Each element maps the attributes it may have to the values they may take.
  HEADING = { 'id' => /\A[\w-]*\z/ }.freeze
  ELEMENTS = {
    'h1' => HEADING, 'h2' => HEADING, 'h3' => HEADING, 'h4' => HEADING, 'h5' => HEADING, 'h6' => HEADING,
    'p' => {}, 'ul' => {}, 'ol' => {}, 'li' => {}, 'strong' => {}, 'em' => {}, 'pre' => {},
    'blockquote' => {}, 'br' => {}, 'hr' => {}, 'code' => {}, 'del' => {}
  }.freeze
  # A reader sees the text of these apart from the text around them.
  BLOCKS = %w[h1 h2 h3 h4 h5 h6 p ul ol li pre blockquote br hr].freeze

  # The hosts that serve the repository, matched only as a whole name, so notgithub.com
  # or github.com.example.com does not match.
  HOSTS = %w[github.com www.github.com api.github.com raw.githubusercontent.com codeload.github.com].freeze
  REPO_VARIABLE = 'KONG_HARNESSES_RELEASES_REPO'

  # No file of this public repository names the repository that publishes the
  # releases: the sync job sets it from a repository secret. The same rule
  # as parseRepo in tools/lib/tool-versions.js: an owner can't hold a dot, and a name
  # of . or .. would point the API request at another path.
  def repo
    name = ENV.fetch(REPO_VARIABLE, '')
    return name if name.match?(%r{\A[A-Za-z0-9-]+/(?!\.\.?\z)[A-Za-z0-9._-]+\z})

    raise "Set #{REPO_VARIABLE} to the <owner>/<name> of the repository that publishes the kong-harnesses releases."
  end

  # The repository in an address of those hosts, in the lower case that `normalize` gives.
  def repository_pattern
    owner, name = repo.downcase.split('/').map { |part| Regexp.escape(part) }
    /
      (?<![a-z0-9.\-])(?:#{HOSTS.map { |host| Regexp.escape(host) }.join('|')})\.?
      (?::\d*)?[\/:]+(?:repos\/+)?#{owner}\/+#{name}(?:\.git)?
      (?![a-z0-9_\-]|\.[a-z0-9_\-])
    /x
  end
  # A `.` or `..` segment in an address of those hosts, which a browser resolves to
  # another path, so the address can name the repository in a form that the pattern
  # above does not match.
  DOT_SEGMENT = %r{(?<![a-z0-9.-])(?:#{HOSTS.map { |host| Regexp.escape(host) }.join('|')})\.?(?::\d*)?[/:]\S*?(?<=[/:])\.{1,2}(?=[/?#]|\s|\z)}

  # The languages that the site's Shiki highlighter loads or maps to one, and text.
  # Shiki stops the site build on any other language of a code block.
  def languages
    @languages ||= languages_in(File.read(SHIKI))
  end

  # Reads every entry of the one `langs` list and every key of the one `languageMap`, and
  # refuses an entry or a form that it cannot read, so a new form in the file cannot drop
  # a language or add one that Shiki does not load.
  def languages_in(source)
    loaded = entries(source, /\blangs\s*:/, /\blangs:\s*\[(.*?)\](?=\s*[,}])/m) { |entry| entry[/\A(["'])([\w+-]+)\1\z/, 2] }
    loaded << 'text'
    mapped = entries(source, /\blanguageMap\s*=/, /\blanguageMap\s*=\s*\{(.*?)\}(?=\s*;)/m) do |entry|
      key, value = entry.match(/\A(["']?)([\w+-]+)\1\s*:\s*(["'])([\w+-]+)\3\z/)&.values_at(2, 4)
      key if loaded.include?(value)
    end
    [*loaded, *mapped].to_set
  end

  def entries(source, name, list)
    raise "#{SHIKI} has more than one list of languages, so this check cannot read them." if source.scan(name).length > 1

    body = source[list, 1] or raise "#{SHIKI} has no list of languages that this check can read."
    items = body.split(',').map(&:strip).reject(&:empty?)
    raise "#{SHIKI} has an empty list of languages." if items.empty?

    items.map { |item| yield(item) || raise("#{SHIKI} has a language entry that this check cannot read: #{item}") }
  end

  # The language of a fenced code block, such as ```sh in an upgrade step.
  def language?(node, attribute)
    node.name == 'code' && attribute.name == 'class' && attribute.value.start_with?('language-') &&
      languages.include?(attribute.value.delete_prefix('language-'))
  end

  def html(markdown)
    config = Jekyll::Configuration.from(YAML.safe_load_file(File.join(ROOT, 'jekyll.yml')))
    Jekyll::Converters::Markdown.new(config).convert(markdown)
  end

  # Undoes what a browser undoes before it follows an address: character references,
  # percent-encoding (until nothing changes, so a double encoding cannot hide a name),
  # full-width forms, the dots that host names accept in place of ".", backslashes,
  # tabs and line breaks, also U+2028 and U+2029, the characters that show nothing by
  # default, the format characters, such as U+FFF9 or U+13430, and letter case.
  def normalize(text)
    value = text
    loop do
      decoded = CGI.unescapeHTML(value).b.gsub(/%(\h\h)/n) { Regexp.last_match(1).hex.chr }.force_encoding('UTF-8').scrub
      break if decoded == value

      value = decoded
    end
    value.unicode_normalize(:nfkc).tr("。．｡", '...').tr('\\', '/')
         .delete("\t\n\r").gsub(/[\p{Default_Ignorable_Code_Point}\p{Cf}]/, '').downcase
  end

  # GFM links a web address with `//` or `www.`, a `mailto:` or `xmpp:` address and a mail
  # address. This rule is wider, so no text that GFM would link can pass: it takes any
  # `@` between two characters of a name, with or without a dot after it.
  ADDRESS = %r{//|www\.|(?:mailto|xmpp):|[[:alnum:]._%+-]@[[:alnum:]]}

  def address?(text)
    normalize(text).match?(ADDRESS)
  end

  # Every control character but a tab and a line break, the line and paragraph
  # separators, every character that shows nothing by default and every format
  # character, such as a variation selector, a Hangul filler or a character that
  # changes the order of text, as in a Trojan Source attack, and the noncharacters, as
  # the text or an attribute holds them after the HTML parser read its character
  # references. A soft hyphen, the zero width characters, the word joiner and U+FEFF
  # change no order and show at most a hyphen, and normalize takes them out before the
  # address check. Tag characters and the emoji variation selectors have their own rule.
  HIDDEN = /[[\p{Cc}&&[^\t\n]]\p{Zl}\p{Zp}[[\p{Default_Ignorable_Code_Point}\p{Cf}]&&[^\u00ad\u200b-\u200d\u2060\ufeff\u{e0000}-\u{e007f}]]\p{Noncharacter_Code_Point}]/
  # One text or emoji variation selector right after an emoji picks how it shows.
  EMOJI_STYLE = /(?<=\p{Emoji})[\ufe0e\ufe0f]/
  # A tag character shows nothing outside the flag of a subdivision. Unicode recommends
  # only the flags of England, Scotland and Wales, each a black flag, the tag characters
  # of its code and a cancel tag, so any other run of tag characters is hidden text.
  TAG = /[\u{e0000}-\u{e007f}]/
  FLAGS = Regexp.union(%w[gbeng gbsct gbwls].map { |code| "\u{1f3f4}#{code.chars.map { |char| (char.ord + 0xe0000).chr(Encoding::UTF_8) }.join}\u{e007f}" })

  def hidden_text?(text)
    text = text.gsub(EMOJI_STYLE, '')
    text.match?(HIDDEN) || text.gsub(FLAGS, '').match?(TAG)
  end

  def hidden?(node)
    node.text? ? hidden_text?(node.content) : node.element? && node.attribute_nodes.any? { |attribute| hidden_text?(attribute.value) }
  end

  def problems(markdown)
    html_problems(html(markdown))
  end

  # Outside the site build, kramdown renders a code block as plain <pre><code>. The site
  # highlights it with its own template, which adds no address from the changelog text.
  def html_problems(html)
    repository = repository_pattern
    fragment = Nokogiri::HTML5.fragment(html)
    found = []
    fragment.traverse do |node|
      found << "a hidden code point in #{place(node)}" if hidden?(node)
      if node.element?
        allowed = ELEMENTS[node.name]
        if allowed.nil?
          found << "an element other than plain text markup in #{place(node)}"
        else
          node.attribute_nodes.each do |attribute|
            next if allowed[attribute.name]&.match?(attribute.value) || language?(node, attribute)

            found << "an attribute that plain text markup does not have in #{place(node)}"
          end
        end
      elsif !node.text? && !node.fragment?
        found << "a #{node.class.name.split('::').last} node in #{place(node)}"
      end
      next unless node.fragment? || BLOCKS.include?(node.name)

      seen = visible(node)
      found << "an address in #{place(node)} (a value such as `go@1.21` can go in backticks)" if address?(visible(node, code: false))
      found << "the releases repository in #{place(node)}" if normalize(seen).match?(repository)
      found << "a dot segment in a GitHub address in #{place(node)}" if normalize(seen).match?(DOT_SEGMENT)
    end
    found.uniq
  end

  # The sections that sync-changelog.rb keeps, the only section titles that a place names.
  SECTIONS = ['⚠ BREAKING CHANGES', 'Features', 'Bug Fixes', 'Performance'].freeze
  # A version as release-please reads one (index.js:59193), with a prerelease and a build
  # part made of the characters that semver allows.
  VERSION = /\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?/
  # The version at the start of a release heading, as the export reads it from the line
  # of the heading and the page check from its text, so the page check finds the
  # version of every heading that the export takes.
  HEADING_VERSION = /\A\[?(#{VERSION})(?=[\]\s(]|\z)/

  # Where a node is on the page, as its release, section and entry number. An error
  # names no text of the changelog: GitHub masks only the exact text of a secret, so
  # the job log would show the repository in another letter case. The numbers count
  # what the page holds, which has no tooling entries, so they say "on the page".
  # `releases` are the release headings of the source, as `release_of` takes them.
  def place(node, releases = nil)
    top = top_of(node)
    return 'the page' if top.fragment?

    release, section, before = heading_of(top, releases)
    where = release ? "release #{release}" : 'the text before the first release'
    return "the heading of #{where}" if top.name == 'h2'
    return "the heading of section #{section} of #{where}" if top.name == 'h3'

    where += ", section #{section}" if section
    if %w[ul ol].include?(top.name)
      item = node.ancestors.find { |ancestor| ancestor.parent == top } || node
      entries = before.select { |sibling| %w[ul ol].include?(sibling.name) }.sum { |list| list.element_children.length }
      index = item == top ? 0 : top.element_children.index(item).to_i
      "#{where}, entry #{entries + index + 1} on the page"
    else
      "#{where}, block #{before.length + 1} on the page"
    end
  end

  # The release and section of a node, as `place` names them.
  def section_of(node, releases = nil)
    top = top_of(node)
    return 'the page' if top.fragment?

    release, section, = heading_of(top, releases)
    where = release ? "release #{release}" : 'the text before the first release'
    section ? "#{where}, section #{section}" : where
  end

  def top_of(node)
    top = node
    top = top.parent until top.fragment? || top.parent.nil? || top.parent.fragment?
    top
  end

  # The release and section that the top-level element `top` is in, and the elements
  # between the section heading and `top`. A heading is its own release or section.
  def heading_of(top, releases = nil)
    return [release_of(top, releases), nil, []] if top.name == 'h2'

    before = []
    section = top.name == 'h3' ? top : nil
    sibling = top.previous_element
    while sibling
      if sibling.name == 'h2'
        return [release_of(sibling, releases), section ? section_name(section, sibling) : nil, before]
      elsif sibling.name == 'h3' && section.nil?
        section = sibling
      elsif section.nil?
        before.unshift(sibling)
      end
      sibling = sibling.previous_element
    end
    [nil, section ? section_name(section, nil) : nil, before]
  end

  # The release of a release heading of the page. A caller that has the source passes
  # `releases`, each release heading of the source as the version that the source writes
  # and the version that the heading shows, and a heading names the release that shows
  # the same version, because kramdown shows `--` in a heading as a dash. The export
  # refuses a heading that does not show exactly its version, so no two releases show
  # the same one. The heading text names a release only when none matches.
  def release_of(heading, releases = nil)
    shown = shown_version(heading)
    same = releases.to_a.select { |_, version| version == shown }
    return same.first.first if same.length == 1

    written_version(heading.text.strip)[HEADING_VERSION, 1] || 'with no version'
  end

  # The version that a heading shows, written back as the source writes it.
  def shown_version(heading)
    written_version(heading.text.strip[SHOWN_VERSION, 1].to_s)
  end

  # The version at the start of a heading, after an optional `[` as in HEADING_VERSION,
  # with the dashes and the ellipsis that kramdown makes of `--`, `---` and `...`.
  SHOWN_VERSION = /\A\[?([0-9A-Za-z.+\-–—…]+)/

  def written_version(shown)
    shown.gsub('—', '---').gsub('–', '--').gsub('…', '...')
  end

  def section_name(section, release)
    name = section.text.strip
    return name if SECTIONS.include?(name)

    count = 0
    sibling = section
    while sibling && sibling != release
      count += 1 if sibling.name == 'h3'
      sibling = sibling.previous_element
    end
    count.to_s
  end

  # The text of a block as a reader sees it: inline elements join their text, and a block
  # inside it stands apart, so a space takes its place, as it does for code without `code`.
  def visible(node, code: true)
    node.children.map do |child|
      if child.text?
        child.content
      elsif !child.element? || BLOCKS.include?(child.name) || (!code && child.name == 'code')
        ' '
      else
        visible(child, code: code)
      end
    end.join
  end

  def check(markdown)
    found = problems(markdown)
    return if found.empty?

    raise "The changelog page would hold a link or an address: #{found.join(', ')}"
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    KongHarnessesChangelogLinks.check(JSON.parse(File.read(ARGV.fetch(0, KongHarnessesChangelogLinks::DATA_FILE))).fetch('markdown'))
    puts 'The kong-harnesses changelog page holds no links or addresses.'
  rescue StandardError => e
    warn "Error: #{e.message}"
    exit 1
  end
end
