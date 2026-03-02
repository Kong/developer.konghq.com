# frozen_string_literal: true

module SupportedVersionAPI # rubocop:disable Style/Documentation
  def self.process(site) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    major_versions = site.data.dig('products', 'gateway', 'releases')
    release_dates = site.data.dig('products', 'gateway', 'release_dates')
    
    
    version_metadata = {}
    major_versions.each do |version|
      version_metadata[version['release']] = {
        eol: version['eol'],
        label: version['label']
      }
    end
    
    
    versions = []
    release_dates&.each do |full_version, date|
      # Extract major.minor from the full version (e.g., "3.12" from "3.12.0.1")
      major_minor = full_version.split('.')[0..1].join('.')
      
     
      metadata = version_metadata[major_minor]
      next unless metadata
      
      eol_date = nil
      sunset_date = nil
      unless metadata[:eol].nil?
        eol_date = metadata[:eol].to_s
        sunset_date = metadata[:eol].next_year.to_s
      end
      
      
      release_date = date&.gsub('/', '-')
      
      # Generate changelog URL (e.g., "3.12.0.2" becomes "#3-12-0-2")
      changelog_anchor = full_version.gsub('.', '-')
      changelog_url = "https://developer.konghq.com/gateway/changelog/##{changelog_anchor}"
      
      versions << {
        release: full_version,
        tag: full_version,
        releaseDate: release_date,
        endOfLifeDate: eol_date,
        endOfsunset_date: sunset_date,
        label: metadata[:label],
        changelogUrl: changelog_url
      }
    end
    
    
    # Sort by version numbers (latest first)
    versions.sort_by! do |v|
      # Split version into parts and convert to integers for proper numeric sorting
      v[:release].split('.').map(&:to_i)
    end.reverse!

    FileUtils.mkdir_p("#{site.dest}/_api")
    File.write("#{site.dest}/_api/gateway-versions.json", versions.to_json)
  end
end

module MarkdownPagesWriter # rubocop:disable Style/Documentation
  def self.process(site)
    site.config['markdown_pages_to_render'].each(&:write)
  end
end

Jekyll::Hooks.register :site, :post_write do |site, _|
  SupportedVersionAPI.process(site)
  MarkdownPagesWriter.process(site)
end
