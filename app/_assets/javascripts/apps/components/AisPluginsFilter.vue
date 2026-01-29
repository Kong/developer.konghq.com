<template>
    <ais-refinement-list :attribute="attribute" :transformItems="getStaticValues" :sort-by="['name']">
        <template v-slot="{ refine, items }">
            <ul class="ais-RefinementList-list flex flex-col max-h-72 overflow-auto h-full">
                <li class="ais-RefinementList-item" v-for="item in items" :key="item.value" :class="{ 'ais-RefinementList-item--selected': item.isRefined }">
                    <label class="ais-RefinementList-label">
                        <input class="ais-RefinementList-checkbox" type="checkbox" :value="item.value" @click="refine(item.value)" :checked="item.isRefined">
                        <div class="flex gap-3 items-center">
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

  export default {
    props: {
      values: { type: Array, required: true },
      attribute: { type: String, required: true }
    },
    components: {
      AisRefinementList
    },
    methods: {
      sortPlugins(a, b) {
        if (a.isRefined !== b.isRefined) {
            return a.isRefined ? -1 : 1;
        }
        return a.label > b.label ? 1 : -1;
      },
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
        }).sort(this.sortPlugins);
      }
    }
  };
</script>
