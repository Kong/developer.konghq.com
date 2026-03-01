# frozen_string_literal: true

require 'yaml'

DEFAULTS = {
  'gwapi_version' => 'v1',
  'name' => 'echo',
  'namespace' => 'kong',
  'route_type' => 'PathPrefix',
  'hostname' => 'kong.example',
  'gateway_namespace' => 'kong',
  'ingress_class' => 'kong'
}.freeze

module Jekyll
  class HttpRoute < Liquid::Block # rubocop:disable Style/Documentation, Metrics/ClassLength
    def initialize(tag_name, markup, tokens)
      super
      @name = markup.strip
    end

    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength, Metrics/CyclomaticComplexity
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      config = YAML.load(contents)

      DEFAULTS.each do |v|
        k = v[0].to_s
        config[k] = v[1] if config[k].nil? || config[k].empty?
      end

      unless config['disable_gateway']
        gateway_api = <<~YAML
          ```bash
          echo "
          #{format_yaml(to_gatewayapi(config).to_yaml)}" | kubectl apply -f -
          ```
          {: data-test-step="block" }
        YAML
      end

      unless config['disable_ingress']
        ingress = <<~YAML
          ```bash
          echo "
          #{format_yaml(to_ingress(config).to_yaml)}" | kubectl apply -f -
          ```
        YAML
      end

      gen_navtabs(config, { 'gatewayapi' => gateway_api, 'ingress' => ingress })
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% httproute %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end

    def format_yaml(yaml)
      yaml = yaml.gsub(/"([^"\n]*)"/) { "'#{::Regexp.last_match(1).gsub("'", "''").gsub('\\\\', '\\')}'" }
      yaml.lines.map { |line| line.gsub(/^---\s*\n/, '') }.compact.join
    end

    def to_gatewayapi(config) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      output = {
        'apiVersion' => "gateway.networking.k8s.io/#{config['gwapi_version']}",
        'kind' => 'HTTPRoute',
        'metadata' => {
          'name' => config['name'],
          'namespace' => config['namespace'],
          'annotations' => {
            'konghq.com/rewrite' => config['annotation_rewrite']&.gsub('$', '\$'),
            'konghq.com/plugins' => config['annotation_plugins']&.join(','),
            'konghq.com/strip-path' => 'true'
          }.compact
        },
        'spec' => {
          'parentRefs' => [
            {
              'name' => 'kong',
              'namespace' => config['gateway_namespace'],
              'section_name' => config['section_name']
            }.compact
          ],
          'rules' => config['matches'].each.map do |match|
            {
              'matches' => [
                {
                  'path' => {
                    'type' => match['route_type'] || DEFAULTS['route_type'],
                    'value' => match['path'].to_s
                  }
                }
              ],
              'backendRefs' => [
                {
                  'name' => match['service'],
                  'kind' => 'Service',
                  'port' => match['port']
                }
              ]
            }
          end
        }
      }

      output['spec']['hostnames'] = [config['hostname']] if config['hostname'] && !config['skip_host']
      output
    end

    def to_ingress(config) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      {
        'apiVersion' => 'networking.k8s.io/v1',
        'kind' => 'Ingress',
        'metadata' => {
          'name' => config['name'],
          'namespace' => config['namespace'],
          'annotations' => {
            'konghq.com/rewrite' => config['annotation_rewrite']&.gsub('$', '\$'),
            'konghq.com/strip-path' => 'true'
          }.compact
        },
        'spec' => {
          'ingressClassName' => config['ingress_class'],
          'tls' => if config['section_name'] == 'https'
                     [{
                       'secretName' => config['hostname'],
                       'hosts' => [config['hostname']]
                     }]
                   end,
          'rules' => config['matches'].each.map do |match|
            {
              'host' => config['skip_host'] ? nil : config['hostname'],
              'http' => {
                'paths' => [{
                  'path' => match['route_type'] == 'RegularExpression' ? "/~#{match['path']}" : match['path'],
                  'pathType' => 'ImplementationSpecific',
                  'backend' => {
                    'service' => {
                      'name' => match['service'],
                      'port' => {
                        'number' => match['port']
                      }
                    }
                  }
                }]
              }
            }.compact
          end
        }.compact
      }
    end

    def gen_navtabs(config, tabs) # rubocop:disable  Metrics/MethodLength
      httproute_tab = <<~TABS
        {% navtab "Gateway API" %}
        #{tabs['gatewayapi']}
        {% endnavtab %}
      TABS

      ingress_tab = <<~TABS
        {% navtab "Ingress" %}
        #{tabs['ingress']}
        {% endnavtab %}
      TABS

      tabs = <<~TABS
        {% navtabs "http-route" %}
        #{httproute_tab if tabs['gatewayapi']}
        #{ingress_tab if tabs['ingress']}
        {% endnavtabs %}
      TABS

      c = Liquid::Template.parse(tabs).render(@context)

      c.lines.map { |line| ' ' * config['indent'].to_i + line }.join
    end
  end
end

Liquid::Template.register_tag('httproute', Jekyll::HttpRoute)
