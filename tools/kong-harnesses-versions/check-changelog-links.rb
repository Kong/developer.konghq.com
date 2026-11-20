# frozen_string_literal: true

require 'cgi'
require 'json'
require 'jekyll'
require 'nokogiri'
require 'yaml'

# fetch-changelog.js removes every link from the kong-harnesses changelog, because the
# repository is internal. This check does not trust that: it renders the result with
# the site's own Markdown converter, reads the HTML with a real parser, and stops the
# sync when any attribute or text still names the repository in a form that a browser
# or git would follow.
module KongHarnessesChangelogLinks
  module_function

  ROOT = File.expand_path('../..', __dir__)
  DATA_FILE = File.join(ROOT, 'app/_data/kong-harnesses/changelog.json')

  # The hosts that serve the repository. A host matches only as a whole name, so
  # notgithub.com or github.com.example.com does not.
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

  def texts(markdown)
    document = Nokogiri::HTML5.fragment(html(markdown))
    values = [markdown]
    document.traverse do |node|
      values << node.content if node.text? || node.cdata? || node.comment?
      values.concat(node.attribute_nodes.map(&:value)) if node.element?
    end
    values
  end

  def internal_references(markdown)
    texts(markdown).select { |text| normalize(text).match?(REPOSITORY) }.uniq
  end

  def check(markdown)
    found = internal_references(markdown)
    return if found.empty?

    raise "The changelog still leads into the internal kong-harnesses repository: #{found.map { |text| text[0, 200].inspect }.join(', ')}"
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    KongHarnessesChangelogLinks.check(JSON.parse(File.read(ARGV.fetch(0, KongHarnessesChangelogLinks::DATA_FILE))).fetch('markdown'))
    puts 'The kong-harnesses changelog has no links into the internal repository.'
  rescue StandardError => e
    warn "Error: #{e.message}"
    exit 1
  end
end
