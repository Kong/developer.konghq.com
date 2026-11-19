# frozen_string_literal: true

module Jekyll
  # Derives what the security index and the RSS feed show for one advisory, so
  # both read the same frontmatter the same way.
  #
  # Rules:
  # - An advisory where every CVE is `not_affected` shows severity "N/A" and
  #   fixed versions "All".
  # - A product entry marked `not_affected` is left out of the products and the
  #   fixed versions.
  # - When more than one product lists fixed versions, they are grouped by
  #   product, for example "Kong Gateway: 3.4.1.2; Kong Mesh: 2.13.8".
  class SecurityAdvisorySummary
    SEVERITIES = %w[low medium high critical].freeze
    NOT_AFFECTED = 'not_affected'

    PRODUCT_NAME_KEYS = {
      'gateway' => 'ee_product_name',
      'ai-gateway' => 'ai_gateway_name',
      'mesh' => 'mesh_product_name',
      'kic' => 'kic_product_name',
      'operator' => 'operator_product_name'
    }.freeze

    # doc: anything that answers [] for 'advisory' and 'products' (a Jekyll
    # document or its Liquid drop). config: the site config.
    def initialize(doc, config)
      @advisory = doc['advisory'] || {}
      @page_products = Array(doc['products'])
      @config = config
    end

    def to_h
      {
        'products' => products,
        'products_markdown' => products_markdown,
        'severity' => severity,
        'fixed' => fixed,
        'fixed_markdown' => fixed_markdown,
        'published' => published,
        'description' => description
      }
    end

    def not_affected?
      cves = Array(@advisory['cves'])
      cves.any? && cves.all? { |cve| cve['status'] == NOT_AFFECTED }
    end

    def products
      product_names.join(', ')
    end

    # Markdown for a table cell: a bulleted list when there is more than one product.
    def products_markdown
      bullets(product_names)
    end

    def severity
      return 'N/A' if not_affected?

      level = highest_cve_severity || @advisory['severity']
      level.to_s.capitalize
    end

    def fixed
      return 'All' if not_affected?

      groups = fixed_groups
      return groups.first[1].join(', ') if groups.size == 1
      return groups.map { |name, versions| "#{name}: #{versions.join(', ')}" }.join('; ') if groups.size > 1

      flat_fixed.join(', ')
    end

    # Markdown for a table cell: one bullet per version, or one bullet per
    # product with its versions nested when products have their own versions.
    def fixed_markdown
      return 'All' if not_affected?

      groups = fixed_groups
      if groups.size > 1
        groups.map { |name, versions| "- #{name}\n#{versions.map { |v| "  - #{v}" }.join("\n")}" }.join("\n")
      elsif groups.size == 1
        bullets(groups.first[1])
      else
        bullets(flat_fixed)
      end
    end

    def published
      @advisory['published'].to_s
    end

    # One line for the RSS feed item.
    def description
      parts = []
      parts << "Severity: #{severity}." unless severity.empty?
      parts << "Products: #{products}." unless products.empty?
      parts << "Fixed versions: #{fixed}." unless fixed.empty?
      parts.join(' ')
    end

    private

    def product_names
      slugs = affected_entries.map { |entry| entry['product'] }
      slugs = @page_products if slugs.empty?
      slugs.map { |slug| product_name(slug) }
    end

    def flat_fixed
      Array(@advisory['fixed_versions'])
    end

    # [[product name, versions], ...] for affected products that list fixed versions.
    def fixed_groups
      affected_entries.select { |entry| Array(entry['fixed_versions']).any? }
                      .map { |entry| [product_name(entry['product']), entry['fixed_versions']] }
    end

    def bullets(items)
      return items.first.to_s if items.size <= 1

      items.map { |item| "- #{item}" }.join("\n")
    end

    def affected_entries
      Array(@advisory['products']).reject { |entry| entry['status'] == NOT_AFFECTED }
    end

    def highest_cve_severity
      levels = Array(@advisory['cves'])
               .reject { |cve| cve['status'] == NOT_AFFECTED }
               .map { |cve| cve['severity'] }
               .compact
      levels.max_by { |level| SEVERITIES.index(level) || -1 }
    end

    def product_name(slug)
      key = PRODUCT_NAME_KEYS[slug]
      (key && @config[key]) || slug
    end
  end
end
