<template>
    <ais-instant-search :search-client="searchClient" :index-name="indexName" :routing="routing" :future="{ preserveSharedStateOnUnmount: true }">
      <ais-configure :hits-per-page.camel="12" :filters="searchParameters"/>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-16">
          <div id="filters" class="filters md:flex" >
            <MobileDrawer :areFiltersOpen="areFiltersOpen" @toggleDrawer="toggleFilters">
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
                                <div class="text-sm text-brand font-semibold">Plugins</div>
                                <div class="flex flex-col gap-3">
                                    <ais-plugins-filter attribute="kong_plugins" :sort-by="['name']" :values="this.filters.kong_plugins" />
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
                <div :class="{ 'hidden': areFiltersOpen }">
                    <ais-hits v-show="hits.length > 0">
                        <template v-slot:item="{ item }">
                            <div class="flex hover:bg-hover-component/100 hover:first:rounded-t-md hover:last:rounded-b-md  border-b border-primary/5">
                                <a :href="getPath(item.url)" class="py-4 px-5 w-full text-primary flex justify-between hover:no-underline items-center gap-2">
                                    <div class="flex flex-col gap-1 w-full">
                                        <div class="flex items-center justify-between">
                                            <span class="text-primary font-bold text-base tracking-[-.01em]">{{ item.title }}</span>
                                            <div class="flex flex-wrap gap-2" v-if="item.products && item.products.length > 0">
                                                <ProductIcon v-for="product in item.products" :name="product" />
                                            </div>
                                        </div>
                                        <p class="text-sm line-clamp-1">
                                            {{ item.description }}
                                        </p>
                                    </div>
                                </a>
                            </div>
                        </template>
                    </ais-hits>
                    <div v-show="hits.length === 0">
                        No results found.
                    </div>
                </div>
                </template>
            </ais-state-results>
        </div>
        <ais-pagination :padding="2" :class-names="{ 'ais-Pagination-link': 'ais-Pagination-link no-icon'}"/>
      </div>

    </ais-instant-search>

</template>

<script>
import { liteClient as algoliasearch } from 'algoliasearch/lite';
import { routingConfig } from './search/routing.js';
import { AisInstantSearch, AisConfigure, AisSearchBox, AisRefinementList, AisHits, AisPagination, AisPanel, AisStateResults } from 'vue-instantsearch/vue3/es';
import AisStaticFilter from './components/AisStaticFilter.vue';
import AisStaticTagsFilter from './components/AisStaticTagsFilter.vue';
import AisProductsFilter from './components/AisProductsFilter.vue';
import AisPluginsFilter from './components/AisPluginsFilter.vue';
import MobileDrawer from './components/MobileDrawer.vue'
import ProductIcon from './components/ProductIcon.vue';

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
        AisStaticTagsFilter,
        AisProductsFilter,
        AisPluginsFilter,
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
            searchParameters: '',
            filters,
            areFiltersOpen: false,
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
    @apply flex flex-col bg-secondary shadow-primary rounded-md text-sm ml-0 gap-0;
}

:deep(.ais-Hits-list) {
    @apply gap-0;
}
</style>
