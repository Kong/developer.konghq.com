<template>
  <ais-refinement-list attribute="products" :transformItems="getStaticValues" />
</template>

<script>
import { AisRefinementList } from 'vue-instantsearch/vue3/es';

export default {
  props: {
    values: { type: Array, required: true }
  },
  components: {
    AisRefinementList
  },
  methods: {
    getStaticValues(items) {
      return this.values.map(staticItem => {
        const item = items.find(item => item.label === staticItem.label);

        return item || {
            label: staticItem.label,
            value: staticItem.value,
            count: 0,
            isRefined: false,
            highlighted: staticItem.value,
        };
      });
    }
  }
};
</script>
