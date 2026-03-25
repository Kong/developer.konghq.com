# frozen_string_literal: true

module Jekyll
  class EventGatewayPoliciesGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    POLICIES_FOLDER = '_event_gateway_policies'

    def generate(site) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      site.data['event_gateway_policies'] ||= {}

      unless Utils::Incremental.enabled?
        Jekyll::EventGatewayPolicyPages::Generator.run(site)
        return
      end

      @policy_cache ||= {}
      skipped = 0
      generator = Jekyll::EventGatewayPolicyPages::Generator.new(site)

      Dir.glob(File.join(site.source, "#{POLICIES_FOLDER}/*/")).each do |folder|
        slug = folder.gsub("#{site.source}/#{POLICIES_FOLDER}/", '').chomp('/')
        current_mtimes = Utils::Incremental.collect_mtimes("#{folder}**/*")
        cached = @policy_cache[slug]

        if cached && !Utils::Incremental.mtimes_changed?(current_mtimes, cached[:mtimes])
          site.pages.concat(cached[:pages])
          Utils::Incremental.skip_regeneration(site, cached[:pages])
          site.data['event_gateway_policies'][slug] = cached[:data]
          skipped += 1
        else
          before = site.pages.size
          policy = Jekyll::EventGatewayPolicyPages::Policy.new(folder:, slug:)
          generator.generate_pages(policy)
          new_pages = site.pages[before..]
          @policy_cache[slug] = { mtimes: current_mtimes, pages: new_pages, data: site.data['event_gateway_policies'][slug] }
        end
      end

      Jekyll.logger.info 'IncrementalGen:', "EventGatewayPoliciesGenerator: #{skipped} policies restored from cache" if skipped.positive?
    end
  end
end
