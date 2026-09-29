# frozen_string_literal: true

Jekyll::Hooks.register :site, :post_read do |site|
  site.pages.reject! do |page|
    next false unless page.relative_path.start_with?('assets/')

    # Page#relative_path drops the leading slash that StaticFileReader keeps in its dir,
    # and StaticFile#url is built from that dir, so restore it or the url loses its slash.
    absolute_path = "/#{page.relative_path}"

    site.static_files << Jekyll::StaticFile.new(
      site,
      site.source,
      File.dirname(absolute_path),
      File.basename(absolute_path)
    )

    true
  end
end
