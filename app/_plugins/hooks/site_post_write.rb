# frozen_string_literal: true

module SupportedVersionAPI # rubocop:disable Style/Documentation
  def self.process(site) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    versions = site.data.dig('products', 'gateway', 'releases')
    versions = versions.map do |version|
      date = nil
      sunset_date = nil
      unless version['eol'].nil?
        date = version['eol'].to_s
        sunset_date = version['eol'].next_year.to_s
      end

      {
        release: "#{version['release']}.x",
        tag: version['release'],
        endOfLifeDate: date,
        endOfsunset_date: sunset_date,
        label: version['label']
      }
    end

    FileUtils.mkdir_p("#{site.dest}/_api")
    File.write("#{site.dest}/_api/gateway-versions.json", versions.to_json)
  end
end

Jekyll::Hooks.register :site, :post_write do |site, _|
  SupportedVersionAPI.process(site)
end
