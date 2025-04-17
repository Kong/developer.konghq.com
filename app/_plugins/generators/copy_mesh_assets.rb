# frozen_string_literal: true

module Jekyll
  class CopyMeshAssetsGenerator < Generator # rubocop:disable Style/Documentation
    priority :lowest

    def generate(site)
      used_assets = Set.new

      # Scan kuma pages for assets
      site.pages.select { |p| p.relative_path.start_with? 'app/.repos/kuma' }.each do |page|
        content = page.content || ''
        content.scan(%r{#{Regexp.escape(asset_url_prefix)}[\w.\-/@]+}) do |match|
          used_assets << match
        end
      end

      copy_kuma_assets_to_dist(site, used_assets)
    end

    def copy_kuma_assets_to_dist(site, used_assets)
      used_assets.each do |asset_path|
        relative_path = asset_path.sub(asset_url_prefix, '')
        source_path = File.join(kuma_assets_dir(site), relative_path)
        dest_path = File.join(dest_assets_dir(site), relative_path)

        next unless File.exist?(source_path)

        FileUtils.mkdir_p(File.dirname(dest_path))
        FileUtils.cp(source_path, dest_path)
      end
    end

    def asset_url_prefix
      @asset_url_prefix ||= '/assets/images/'
    end

    def kuma_assets_dir(site)
      @kuma_assets_dir ||= File.join(site.source, '.repos/kuma/app/assets/images')
    end

    def dest_assets_dir(site)
      @dest_assets_dir ||= File.join(site.dest, 'assets/images')
    end
  end
end
