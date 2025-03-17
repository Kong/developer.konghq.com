<template>
  <ais-instant-search :search-client="searchClient" :index-name="indexName" :routing="routing" :future="{ preserveSharedStateOnUnmount: true }">
    <ais-configure :hits-per-page.camel="12" :filters="contentTypeFilters" />
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
                <template  v-slot:default>
                    <div class="flex flex-col gap-3">
                        <div class="text-sm text-brand font-semibold">Content</div>
                        <div class="flex flex-col gap-3">
                            <div class="ais-RefinementList">
                                <ul class="ais-RefinementList-list">
                                    <li v-for="(source, key) in sources" :key="key" class="tab-ais-RefinementList-item">
                                        <label class="ais-RefinementList-label">
                                            <input type="radio" name="content_type" :checked="selectedContentType === key" :value="key" @change="handleContentTypeSelection(key)">
                                            <span class="ais-RefinementList-labelText">{{ source.label }}</span>
                                        </label>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </template>
            </ais-panel>


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
                        <div class="card card__bordered min-h-[260px]">
                            <a :href="getPath(item.url)" class="flex flex-col gap-5 hover:no-underline text-secondary w-full p-6">
                                <div class="flex flex-col gap-3 flex-grow">
                                    <h4 v-if="item.content_type === 'plugin'"> {{ item.title }} Plugin</h4>
                                    <h4 v-else>{{ item.title }}</h4>

                                    <span class="text-sm">{{getLowestHierarchyLevel(item.hierarchy)}}</span>
                                    <p class="text-sm line-clamp-3">
                                        {{ item.content }}
                                    </p>
                                </div>

                                <div class="flex flex-wrap gap-2" v-if="item.tier && item.tier.length > 0">
                                    <span class="badge">{{ item.tier }}</span>
                                </div>
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
import { ref } from 'vue';
import { liteClient as algoliasearch } from 'algoliasearch/lite';
import { routingConfig } from './search/routing.js';
import { AisInstantSearch, AisConfigure, AisCurrentRefinements, AisSearchBox, AisRefinementList, AisHits, AisPagination, AisPanel, AisStateResults } from 'vue-instantsearch/vue3/es';
import AisStaticFilter from './components/AisStaticFilter.vue';
import AisStaticTagsFilter from './components/AisStaticTagsFilter.vue';

import 'instantsearch.css/themes/reset.css';

const filters = window.searchFilters;
const indexName = import.meta.env.VITE_ALGOLIA_INDEX_NAME;

export default {
  components: {
    AisInstantSearch,
    AisConfigure,
    AisCurrentRefinements,
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
      filters,
      selectedContentType: null
    };
  },
  setup() {
    const sources = ref(window.searchSources);


    return { sources };
  },
  mounted() {
    this.setInitialFilters();
  },
  computed: {
    contentTypeFilters() {
        if (this.selectedContentType === null) {
            return '';
        } else {
            return this.sources[this.selectedContentType].filters;
        }
    }
  },
  methods: {
    getPath(url) {
        const urlObj = new URL(url);

        return `${urlObj.pathname}${urlObj.hash}`;
    },
    getLowestHierarchyLevel(hierarchy) {
        const levels = Object.entries(hierarchy)
            .filter(([key, value]) => key !== 'lvl0' & key !== 'lvl1' && value !== null);

        if (levels.length > 0) {
            return levels[levels.length - 1][1];
        } else {
            return '';
        }
    },
    handleContentTypeSelection(value) {
        this.selectedContentType = value;
    },
    setInitialFilters() {
        const urlParams = new URLSearchParams(window.location.search)
        if (urlParams.size > 0 && urlParams.get('content')) {
            this.selectedContentType = urlParams.get('content');
        } else {
            this.selectedContentType = 'all';
        }
    }
  }
};
</script>

<style scoped>
.ais-Hits {
    @apply flex flex-col col-span-3 w-full gap-16;
}

:deep(.ais-Hits-list) {
    @apply grid auto-rows-fr grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8;
}
</style>
