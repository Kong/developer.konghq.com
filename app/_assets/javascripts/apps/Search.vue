<template>
  <ais-instant-search :search-client="searchClient" :index-name="indexName" :routing="routing" :future="{ preserveSharedStateOnUnmount: true }">
    <ais-configure :hits-per-page.camel="12" :filters="contentTypeFilters" />

    <div class="grid grid-cols-1 md:grid-cols-4 gap-16">
        <div id="filters" class="filters md:flex">
            <MobileDrawer :areFiltersOpen="areFiltersOpen" @toggleDrawer="toggleFilters">

            <ais-panel>
                <template  v-slot:default>
                    <div class="flex flex-col gap-3">
                        <div class="text-sm text-brand font-semibold">Filter by type</div>
                        <div class="flex flex-col gap-3">
                            <div class="ais-RefinementList">
                                <ul class="ais-RefinementList-list tabcolumn">
                                    <li v-for="(source, key) in sources" :key="key" class="tab-ais-RefinementList-item">
                                        <label class="tab-button__vertical py-2" :class="{ 'tab-button__vertical--active': selectedContentType === key }" :for="key">
                                            <input :id="key" type="radio" name="content_type" :checked="selectedContentType === key" :value="key" @change="handleContentTypeSelection(key)" class="sr-only">
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
                            <ais-products-filter attribute="products" :values="this.filters.products" />
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

        </MobileDrawer>
        </div>

        <div class="searchbox-results-container">
            <div class="flex md:flex-col md:col-span-3 w-full justify-between gap-2">
                <ais-search-box>
                    <template v-slot="{ currentRefinement, isSearchStalled, refine }">
                        <div class="filter-results-field">
                            <svg class="filter-results-field__image" width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                <path d="M10 18V16H14V18H10ZM6 13V11H18V13H6ZM3 8V6H21V8H3Z" fill="rgb(var(--color-text-terciary))"/>
                            </svg>
                            <input type="search" class="filter-results-field__input" placeholder="Filter results" :value="currentRefinement" @input="refine($event.currentTarget.value)">
                        </div>
                    </template>
                </ais-search-box>
                <button class="button button--secondary button--filters flex md:hidden" @click="toggleFilters">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M10 18V16H14V18H10ZM6 13V11H18V13H6ZM3 8V6H21V8H3Z" fill="rgb(var(--color-text-terciary))"/>
                    </svg>
                    Filters
                </button>
            </div>

            <ais-state-results>
                <template v-slot="{ results: { hits } }">
                    <ais-hits v-show="hits.length > 0">
                        <template v-slot:item="{ item }">
                            <div class="card card__bordered min-h-[260px]">
                                <a :href="getPath(item.url)" class="flex flex-col gap-5 hover:no-underline text-secondary w-full p-6">
                                    <div class="flex flex-col gap-3 flex-grow">
                                        <h4 v-if="item.content_type === 'plugin' && item.products && item.products.includes('mesh')"> {{ item.title }} Policy</h4>
                                        <h4 v-else-if="item.content_type === 'plugin' && item.products && item.products.includes('gateway')"> {{ item.title }} Plugin</h4>
                                        <h4 v-else>{{ item.title }}</h4>

                                        <span class="text-sm">{{getLowestHierarchyLevel(item.hierarchy)}}</span>
                                        <p class="text-sm line-clamp-3">
                                            {{ item.content }}
                                        </p>
                                    </div>

                                    <div class="flex flex-wrap gap-2" v-if="item.tier && item.tier.length > 0">
                                        <span class="badge">{{ item.tier }}</span>
                                    </div>

                                    <div class="flex flex-wrap gap-2" v-if="item.products && item.products.length > 0">
                                        <ProductIcon v-for="product in item.products" :name="product" />
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
        </div>
        <ais-pagination :padding="2" :class-names="{ 'ais-Pagination-link': 'ais-Pagination-link no-icon'}"/>
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
import MobileDrawer from './components/MobileDrawer.vue';
import ProductIcon from './components/ProductIcon.vue';
import AisProductsFilter from './components/AisProductsFilter.vue';

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
    AisStaticTagsFilter,
    AisProductsFilter,
    MobileDrawer,
    ProductIcon
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
      selectedContentType: null,
      areFiltersOpen: false
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
    },
    toggleFilters() {
        this.areFiltersOpen = !this.areFiltersOpen;
        document.body.classList.toggle('modal-overflow')
    },
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
