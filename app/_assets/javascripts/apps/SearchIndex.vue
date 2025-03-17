<template>
    <ais-instant-search :search-client="searchClient" :index-name="indexName" :routing="routing" :future="{ preserveSharedStateOnUnmount: true }">
      <ais-configure :hits-per-page.camel="12" :filters="searchParameters"/>
      <div class="grid grid-cols-4 gap-16">
          <div id="filters" class="w-full flex flex-col gap-8 sticky top-24 self-start">
              <div class="flex flex-col gap-3">
                  <div class="text-sm text-brand font-semibold">Filter</div>
                  <ais-search-box>
                      <template v-slot="{ currentRefinement, isSearchStalled, refine }">
                          <div class="flex gap-2 bg-secondary rounded-md border border-brand-saturated/40 py-2 px-3 items-center w-full">
                              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                                  <path d="M19.6 21L13.3 14.7C12.8 15.1 12.225 15.4167 11.575 15.65C10.925 15.8833 10.2333 16 9.5 16C7.68333 16 6.14583 15.3708 4.8875 14.1125C3.62917 12.8542 3 11.3167 3 9.5C3 7.68333 3.62917 6.14583 4.8875 4.8875C6.14583 3.62917 7.68333 3 9.5 3C11.3167 3 12.8542 3.62917 14.1125 4.8875C15.3708 6.14583 16 7.68333 16 9.5C16 10.2333 15.8833 10.925 15.65 11.575C15.4167 12.225 15.1 12.8 14.7 13.3L21 19.6L19.6 21ZM9.5 14C10.75 14 11.8125 13.5625 12.6875 12.6875C13.5625 11.8125 14 10.75 14 9.5C14 8.25 13.5625 7.1875 12.6875 6.3125C11.8125 5.4375 10.75 5 9.5 5C8.25 5 7.1875 5.4375 6.3125 6.3125C5.4375 7.1875 5 8.25 5 9.5C5 10.75 5.4375 11.8125 6.3125 12.6875C7.1875 13.5625 8.25 14 9.5 14Z" fill="currentColor"/>
                              </svg>
                              <input type="search" class="w-full bg-secondary" placeholder="Search" :value="currentRefinement" @input="refine($event.currentTarget.value)">
                          </div>
                      </template>
                  </ais-search-box>
              </div>

              <ais-panel>
                  <template v-slot:default="{ hasRefinements }">
                      <div class="flex flex-col gap-3">
                          <div class="text-sm text-brand font-semibold">Tags</div>
                          <div class="flex flex-col gap-3">
                            <ais-static-tags-filter />
                          </div>
                      </div>
                  </template>
              </ais-panel>

              <ais-panel>
                  <template v-slot:default="{ hasRefinements }">
                      <div class="flex flex-col gap-3" v-if="hasRefinements">
                          <div class="text-sm text-brand font-semibold">Products</div>
                          <div class="flex flex-col gap-3">
                              <ais-static-filter attribute="products" :sort-by="['name']" :values="this.filters.products" />
                          </div>
                      </div>
                  </template>
              </ais-panel>

              <ais-panel>
                  <template v-slot:default="{ hasRefinements }">
                      <div class="flex flex-col gap-3" v-if="hasRefinements">
                          <div class="text-sm text-brand font-semibold">Tools</div>
                          <div class="flex flex-col gap-3">
                              <ais-static-filter attribute="tools" :sort-by="['name']" :values="this.filters.tools" />
                          </div>
                      </div>
                  </template>
              </ais-panel>

              <ais-panel>
                  <template v-slot:default="{ hasRefinements }">
                      <div class="flex flex-col gap-3" v-if="hasRefinements">
                          <div class="text-sm text-brand font-semibold">Works on</div>
                          <div class="flex flex-col gap-3">
                              <ais-static-filter attribute="works_on" :sort-by="['name']" :values="this.filters.works_on" />
                          </div>
                      </div>
                  </template>
              </ais-panel>
          </div>

          <ais-state-results>
            <template v-slot="{ results: { hits } }">
                <ais-hits v-show="hits.length > 0">
                    <template v-slot:item="{ item }">
                        <div class="flex hover:bg-hover-component/100 hover:first:rounded-t-md hover:last:rounded-b-md  border-b border-primary/5">
                            <a :href="getPath(item.url)" class="py-4 px-5 w-full text-primary flex justify-between hover:no-underline items-center gap-2">
                                <div class="flex flex-col gap-1">
                                    <span class="text-primary font-bold text-base tracking-[-.01em]">{{ item.title }}</span>
                                    <p class="text-sm line-clamp-1">
                                        {{ item.description }}
                                    </p>
                                </div>
                                <div class="flex w-fit shrink-0 badge">{{ getProductName(item.products[0]) }}</div>
                            </a>
                        </div>
                    </template>
                </ais-hits>
                <div v-show="hits.length === 0">
                    No results found.
                </div>
            </template>
        </ais-state-results>
        <ais-pagination :padding="2" />
      </div>
    </ais-instant-search>
</template>

<script>
import { liteClient as algoliasearch } from 'algoliasearch/lite';
import { routingConfig } from './search/routing.js';
import { AisInstantSearch, AisConfigure, AisSearchBox, AisRefinementList, AisHits, AisPagination, AisPanel, AisStateResults } from 'vue-instantsearch/vue3/es';
import AisStaticFilter from './components/AisStaticFilter.vue';
import AisStaticTagsFilter from './components/AisStaticTagsFilter.vue';

import 'instantsearch.css/themes/reset.css';

const filters = window.searchFilters;
const indexName = import.meta.env.VITE_ALGOLIA_INDEX_NAME;

export default {
    components: {
        AisInstantSearch,
        AisConfigure,
        AisSearchBox,
        AisRefinementList,
        AisHits,
        AisPagination,
        AisPanel,
        AisStateResults,
        AisStaticFilter,
        AisStaticTagsFilter
    },
    data() {
        return {
            searchClient: algoliasearch(
                import.meta.env.VITE_ALGOLIA_APPLICATION_ID,
                import.meta.env.VITE_ALGOLIA_API_KEY
            ),
            indexName: indexName,
            routing: routingConfig(indexName),
            searchParameters: '',
            filters
        };
    },
    mounted() {
        const contentType = document.getElementById('search-index-app');
        if (contentType !== undefined && contentType.dataset.contentType) {
            this.searchParameters = `content_type:${contentType.dataset.contentType}`;
        }
    },
    methods: {
        getPath(url) {
            const urlObj = new URL(url);

            return `${urlObj.pathname}${urlObj.hash}`;
        },
        getProductName(slug) {
            const product = this.filters.products.find((p) => p.value === slug);
            return product.label;
        }
    }
};
</script>

<style scoped>
.ais-Hits {
    @apply flex flex-col bg-secondary shadow-primary rounded-md text-sm ml-0 gap-0;
}

:deep(.ais-Hits-list) {
    @apply gap-0;
}
</style>
