<template>
  <ais-refinement-list :attribute="attribute" :transformItems="getStaticValues" />
</template>

<script>
import { AisRefinementList } from 'vue-instantsearch/vue3/es';

export default {
  props: {
    values: { type: Array, required: true },
    attribute: { type: String, required: true }
  },
  components: {
    AisRefinementList
  },
  methods: {
    getStaticValues(items, { results }) {
      return this.values.map(staticItem => {
        const item = items.find(item => item.value === staticItem.value);
        let selected = false;

        if (item) {
          item.highlighted = staticItem.label;
          item.label = staticItem.label;
        }

        const facet = results._state.disjunctiveFacetsRefinements[this.attribute];

        if (facet) {
            selected = facet.includes(staticItem.value)
        }

        return item || {
            label: staticItem.label,
            value: staticItem.value,
            count: 0,
            isRefined: selected || staticItem.isRefined,
            highlighted: staticItem.label,
        };
      });
    }
  }
};
</script>
