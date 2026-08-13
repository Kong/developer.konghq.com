# frozen_string_literal: true

RSpec.describe Jekyll::Raise do
  let(:page) { { 'path' => 'docs/guide.md' } }

  def render_raise(markup)
    render_liquid("{% raise #{markup} %}", page: page)
  end

  it 'raises a RuntimeError' do
    expect { render_raise('something went wrong') }.to raise_error(RuntimeError)
  end

  it 'includes the message in the error' do
    expect { render_raise('something went wrong') }.to raise_error(RuntimeError, /something went wrong/)
  end

  it 'appends the page path after "via"' do
    expect { render_raise('error') }.to raise_error(RuntimeError, %r{via docs/guide\.md})
  end

  it 'evaluates Liquid in the message param' do
    expect { render_raise('{{ page.path }} is broken') }.to raise_error(RuntimeError, /docs\/guide\.md is broken/)
  end
end
