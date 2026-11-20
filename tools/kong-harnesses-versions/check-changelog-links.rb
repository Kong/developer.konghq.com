# frozen_string_literal: true

require 'cgi'
require 'json'
require 'jekyll'
require 'nokogiri'
require 'yaml'

# fetch-changelog.js removes every link from the kong-harnesses changelog, because the
# page has none. This check does not trust that: it renders the result with the site's
# own Markdown converter, reads the HTML with a real parser, and stops the sync when the
# page would hold anything that a browser could follow. It allows only plain elements
# with plain attributes, so no form of an address in an attribute can pass, and no `//`
# in text outside a code span. Text in a code span is not a link, but it still must not
# name the kong-harnesses repository.
module KongHarnessesChangelogLinks
  module_function

  ROOT = File.expand_path('../..', __dir__)
  DATA_FILE = File.join(ROOT, 'app/_data/kong-harnesses/changelog.json')

  HEADING = %w[id].freeze
  ELEMENTS = {
    'h1' => HEADING, 'h2' => HEADING, 'h3' => HEADING, 'h4' => HEADING, 'h5' => HEADING, 'h6' => HEADING,
    'p' => [], 'ul' => [], 'ol' => [], 'li' => [], 'strong' => [], 'em' => [], 'code' => [], 'pre' => [],
    'blockquote' => [], 'br' => [], 'hr' => [], 'del' => []
  }.freeze

  # The hosts that serve the repository, matched only as a whole name, so notgithub.com
  # or github.com.example.com does not match.
  HOSTS = %w[github.com www.github.com api.github.com raw.githubusercontent.com codeload.github.com].freeze
  REPOSITORY = /
    (?<![a-z0-9.\-])(?:#{HOSTS.map { |host| Regexp.escape(host) }.join('|')})\.?
    (?::\d*)?[\/:]+(?:repos\/+)?kong\/+kong-harnesses(?:\.git)?
    (?![a-z0-9_\-]|\.[a-z0-9_\-])
  /x

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
    found = []
    Nokogiri::HTML5.fragment(html(markdown)).traverse do |node|
      if node.element?
        allowed = ELEMENTS[node.name]
        if allowed.nil?
          found << "the element <#{node.name}>"
        else
          node.attribute_nodes.each do |attribute|
            found << "the attribute #{attribute.name} on <#{node.name}>" unless allowed.include?(attribute.name)
          end
        end
      elsif node.text?
        text = normalize(node.content)
        in_code = node.ancestors.any? { |parent| parent.name == 'code' }
        found << "the address in #{node.content[0, 200].inspect}" if !in_code && text.include?('//')
        found << "the kong-harnesses repository in #{node.content[0, 200].inspect}" if text.match?(REPOSITORY)
      elsif !node.fragment?
        found << "a #{node.class.name.split('::').last} node"
      end
    end
    found.uniq
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
