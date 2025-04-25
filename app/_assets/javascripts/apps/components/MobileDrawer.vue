<template>
    <div class="mobile-drawer flex" :class="{ 'hidden': !areFiltersOpen, 'md:flex': true }">
        <div class="mobile-drawer__panel"  :class="{ 'translate-y-0': areFiltersOpen, 'translate-y-full md:translate-y-0': !areFiltersOpen }">
            <div class="mobile-drawer__content">
                <slot></slot>
            </div>
            <div class="mobile-drawer__footer">
                <ais-clear-refinements class="button button--secondary">
                  <template v-slot="{ refine }">
                      <button @click="refine(); toggleDrawer();">
                        Clear Filters
                    </button>
                  </template>
                </ais-clear-refinements>

                <button class="button button--primary grow justify-center" @click="toggleDrawer">
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