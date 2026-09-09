# frozen_string_literal: true

# Extracted from: https://github.com/kumahq/kuma-website/blob/master/jekyll-kuma-plugins/lib/jekyll/kuma-plugins/liquid/tags/policyyaml.rb
require_relative '../monkey_patch'
require_relative '../component_templates'
require_relative 'policy_yaml/deep_copy'
require_relative 'policy_yaml/condition'
require_relative 'policy_yaml/params'
require_relative 'policy_yaml/style'
require_relative 'policy_yaml/transforms/base'
require_relative 'policy_yaml/transforms/target_ref_transform'
require_relative 'policy_yaml/transforms/backend_ref_transform'
require_relative 'policy_yaml/transforms/dual_name_transform'
require_relative 'policy_yaml/transforms/kubernetes_root_transform'
require_relative 'policy_yaml/node_processor'
require_relative 'policy_yaml/terraform_renderer'
require_relative 'policy_yaml/style_renderer'
require_relative 'policy_yaml/code_block_formatter'

module Jekyll
  class RenderPolicyYaml < Liquid::Block
    TARGET_VERSION = Gem::Version.new('2.9')
    TF_TARGET_VERSION = Gem::Version.new('2.10')

    def initialize(tag_name, markup, options)
      super
      @params = PolicyYaml::Params.new(markup)
    end

    def render(context)
      content = super
      return '' if content == ''

      @page = context.environments.first['page']
      @params.resolve!(context)

      render_component(context, content)
    end

    private

    def render_component(context, content)
      release = context.registers[:page]['release']
      contents, terraform_content = render_styles(context, content)

      context.stack do
        assign_context(context, release, contents, terraform_content)
        ComponentTemplates.fetch('policy_yaml', 'markdown').render(context)
      end
    end

    def render_styles(context, content)
      namespace = @params['namespace'] || context.registers[:site].config['mesh_namespace']

      PolicyYaml::StyleRenderer.new(
        node_processor: node_processor,
        namespace: namespace
      ).render(extract_documents(content))
    end

    def assign_context(context, release, contents, terraform_content)
      tools = Array(@params['tools'])
      formatter = PolicyYaml::CodeBlockFormatter.new(raw: raw_body?)
      meshservice = use_meshservice?(release)

      context['additional_classes'] = meshservice ? nil : 'codeblock'
      context['use_meshservice'] = meshservice
      context['show_kubernetes'] = tools.empty? || tools.include?('kubernetes')
      context['show_universal'] = tools.empty? || tools.include?('universal')
      context['show_tf'] = show_terraform?(release, tools)
      context['terraform_content'] = formatter.hcl(terraform_content)
      context['kube_legacy'] = formatter.yaml(contents[:kube_legacy])
      context['kube'] = formatter.yaml(contents[:kube])
      context['uni_legacy'] = formatter.yaml(contents[:uni_legacy])
      context['uni'] = formatter.yaml(contents[:uni])
      context['heading_level'] = Jekyll::ClosestHeading.new(@page, @line_number, context).level
    end

    # remove ```yaml header and ``` footer and read each document one by one
    def extract_documents(content)
      YAML.load_stream(content.gsub(/`{3}yaml\n/, '').gsub(/`{3}/, ''))
    end

    def node_processor
      PolicyYaml::NodeProcessor.new([
                                      PolicyYaml::Transforms::TargetRefTransform.new,
                                      PolicyYaml::Transforms::BackendRefTransform.new,
                                      PolicyYaml::Transforms::DualNameTransform.new,
                                      PolicyYaml::Transforms::KubernetesRootTransform.new(@params['apiVersion'])
                                    ])
    end

    def use_meshservice?(release)
      @params['use_meshservice'] == true && version(release) >= TARGET_VERSION
    end

    def show_terraform?(release, tools)
      version(release) >= TF_TARGET_VERSION && (tools.empty? || tools.include?('terraform'))
    end

    def version(release)
      Gem::Version.new(release.number.dup.sub('x', '0'))
    end

    def raw_body?
      @body.nodelist.first { |x| x.has?('tag_name') and x.tag_name == 'raw' }
    end
  end
end

Liquid::Template.register_tag('policy_yaml', Jekyll::RenderPolicyYaml)
