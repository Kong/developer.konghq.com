<template>
    <ais-refinement-list :attribute="attribute" :transformItems="getStaticValues" :sort-by="['name']" >
        <template v-slot="{ refine, items }">
            <ul class="ais-RefinementList-list">
                <li class="ais-RefinementList-item" v-for="item in items" :key="item.value" :class="{ 'ais-RefinementList-item--selected': item.isRefined }">
                    <label class="ais-RefinementList-label">
                        <input class="ais-RefinementList-checkbox" type="checkbox" :value="item.value" @click="refine(item.value)" :checked="item.isRefined">
                        <div class="flex gap-3 items-center">
                            <ProductIcon :name="item.value" />
                            <span class="ais-RefinementList-labelText">{{ item.label }}</span>
                        </div>
                    </label>
                </li>
            </ul>
        </template>
    </ais-refinement-list>
</template>

<script>
  import { AisRefinementList } from 'vue-instantsearch/vue3/es';
  import ProductIcon from './ProductIcon.vue';

  export default {
    props: {
      values: { type: Array, required: true },
      attribute: { type: String, required: true }
    },
    components: {
      AisRefinementList,
      ProductIcon
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

<style scoped>
.product-icon--background {
    @apply p-1;
}
</style>