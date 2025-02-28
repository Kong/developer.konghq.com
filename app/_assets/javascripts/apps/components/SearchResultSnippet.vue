<script>
import { h } from 'vue';
import { parseAlgoliaHitSnippet } from '@algolia/autocomplete-preset-algolia';

export default {
  props: {
    item: Object,
    attribute: String
  },
  render() {
    return h(
      'span',
      {},
      parseAlgoliaHitSnippet({ hit: this.item, attribute: this.attribute }).map((x, index) =>
        x.isHighlighted
          ? h('strong', { key: index }, x.value)
          : x.value
      )
    );
  }
};
</script>
