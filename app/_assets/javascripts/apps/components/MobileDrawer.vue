<template>
    <div class="mobile-drawer flex" :class="{ 'hidden': !areFiltersOpen, 'md:flex': true }">
        <div class="mobile-drawer__panel"  :class="{ 'translate-y-0': areFiltersOpen, 'translate-y-full md:translate-y-0': !areFiltersOpen }">
            <div class="mobile-drawer__content">
                <slot></slot>
            </div>
            <div class="mobile-drawer__footer">
                <ais-clear-refinements class="rounded-md border border-brand py-2 px-3 text-primary text-sm" @click="toggleDrawer">
                    <template v-slot:resetLabel>Clear Filters</template>
                </ais-clear-refinements>

                <button class="flex items-center gap-2 rounded-md border py-2 px-4 border-brand-saturated/40 grow justify-center bg-brand text-primary text-sm" @click="toggleDrawer">
                    See Results
                </button>
            </div>
        </div>
    </div>
</template>

<script>
import { AisClearRefinements } from 'vue-instantsearch/vue3/es';

export default {
  props: {
    areFiltersOpen: Boolean,
  },
  components: {
    AisClearRefinements
  },
  emits: ["toggleDrawer"],
  methods: {
    toggleDrawer() {
      this.$emit("toggleDrawer");
    },
  },
}
</script>