# frozen_string_literal: true

require 'cgi'
require 'json'
require 'jekyll'
require 'nokogiri'
require 'yaml'

# sync-changelog.rb removes every link from the kong-harnesses changelog, because the
# page has none. This check does not trust that: it renders the result with the site's
# own Markdown converter, reads the HTML with a real parser, and stops the sync when the
# page would hold anything that a browser could follow. It allows only plain elements
# with plain attributes, so no form of an address in an attribute can pass. It reads the
# text of each element as a reader sees it, joined across inline markup such as bold,
# and refuses any `//` outside code. Text in code is not a link, but it still must not
# name the kong-harnesses repository.
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
    'blockquote' => {}, 'br' => {}, 'hr' => {}, 'code' => {}
  }.freeze
  # A reader sees the text of these apart from the text around them.
  BLOCKS = %w[h1 h2 h3 h4 h5 h6 p ul ol li pre blockquote br hr].freeze

  # The hosts that serve the repository, matched only as a whole name, so notgithub.com
  # or github.com.example.com does not match.
  HOSTS = %w[github.com www.github.com api.github.com raw.githubusercontent.com codeload.github.com].freeze
  REPOSITORY = /
    (?<![a-z0-9.\-])(?:#{HOSTS.map { |host| Regexp.escape(host) }.join('|')})\.?
    (?::\d*)?[\/:]+(?:repos\/+)?kong\/+kong-harnesses(?:\.git)?
    (?![a-z0-9_\-]|\.[a-z0-9_\-])
  /x

  # The languages that the site's Shiki highlighter loads or maps to one, and text.
  # Shiki stops the site build on any other language of a code block.
  def languages
    @languages ||= begin
      source = File.read(SHIKI)
      loaded = source[/langs:\s*\[(.*?)\]/m, 1].to_s.scan(/"([^"]+)"/).flatten
      mapped = source[/languageMap\s*=\s*\{(.*?)\}/m, 1].to_s.scan(/^\s*"?([\w+-]+)"?\s*:/).flatten
      raise "#{SHIKI} has no list of languages that this check can read." if loaded.empty? || mapped.empty?

      [*loaded, *mapped, 'text'].to_set
    end
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
  # tabs and line breaks, invisible characters and letter case.
  def normalize(text)
    value = text
    loop do
      decoded = CGI.unescapeHTML(value).b.gsub(/%(\h\h)/n) { Regexp.last_match(1).hex.chr }.force_encoding('UTF-8').scrub
      break if decoded == value

      value = decoded
    end
    value.unicode_normalize(:nfkc).tr("。．｡", '...').tr('\\', '/')
         .delete("\t\n\r­​‌‍⁠﻿").downcase
  end

  def problems(markdown)
    html_problems(html(markdown))
  end

  # Outside the site build, kramdown renders a code block as plain <pre><code>. The site
  # highlights it with its own template, which adds no address from the changelog text.
  def html_problems(html)
    found = []
    Nokogiri::HTML5.fragment(html).traverse do |node|
      if node.element?
        allowed = ELEMENTS[node.name]
        if allowed.nil?
          found << "the element <#{node.name}>"
        else
          node.attribute_nodes.each do |attribute|
            next if allowed[attribute.name]&.match?(attribute.value) || language?(node, attribute)

            found << "the attribute #{attribute.name} on <#{node.name}>"
          end
        end
      elsif !node.text? && !node.fragment?
        found << "a #{node.class.name.split('::').last} node"
      end
      next unless node.fragment? || BLOCKS.include?(node.name)

      seen = visible(node)
      found << "the address in #{seen.strip[0, 200].inspect}" if normalize(visible(node, code: false)).include?('//')
      found << "the kong-harnesses repository in #{seen.strip[0, 200].inspect}" if normalize(seen).match?(REPOSITORY)
    end
    found.uniq
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
