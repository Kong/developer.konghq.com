<template>
  <button aria-label="Search" class="cursor-pointer flex gap-4 items-center justify-between w-fit border rounded-md border-brand py-[7px] px-3 text-secondary bg-secondary border-b border-primary/5 leading-4" @click="openModal">
    <span class="flex items-center gap-2 flex-shrink-0">
      <span class="flex">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M19.6 21L13.3 14.7C12.8 15.1 12.225 15.4167 11.575 15.65C10.925 15.8833 10.2333 16 9.5 16C7.68333 16 6.14583 15.3708 4.8875 14.1125C3.62917 12.8542 3 11.3167 3 9.5C3 7.68333 3.62917 6.14583 4.8875 4.8875C6.14583 3.62917 7.68333 3 9.5 3C11.3167 3 12.8542 3.62917 14.1125 4.8875C15.3708 6.14583 16 7.68333 16 9.5C16 10.2333 15.8833 10.925 15.65 11.575C15.4167 12.225 15.1 12.8 14.7 13.3L21 19.6L19.6 21ZM9.5 14C10.75 14 11.8125 13.5625 12.6875 12.6875C13.5625 11.8125 14 10.75 14 9.5C14 8.25 13.5625 7.1875 12.6875 6.3125C11.8125 5.4375 10.75 5 9.5 5C8.25 5 7.1875 5.4375 6.3125 6.3125C5.4375 7.1875 5 8.25 5 9.5C5 10.75 5.4375 11.8125 6.3125 12.6875C7.1875 13.5625 8.25 14 9.5 14Z" fill="currentColor"/>
        </svg>
      </span>
      <span class="hidden xl:flex text-sm">Search</span>
    </span>
    <span class="hidden xl:flex items-center gap-1 flex-shrink-0">
      <span class="sr-only">Command or control key</span>
      <span aria-hidden="true" class="badge h-5 flex items-center">
        <div class="text-primary">
          <svg xmlns="http://www.w3.org/2000/svg" width="41" height="11" fill="none" viewBox="0 0 41 11"><path fill="currentColor" fill-rule="evenodd" d="M4.125 2.063V3h2.25v-.937a2.062 2.062 0 1 1 2.063 2.062H7.5v2.25h.938a2.062 2.062 0 1 1-2.063 2.063V7.5h-2.25v.938a2.062 2.062 0 1 1-2.062-2.063H3v-2.25h-.937a2.062 2.062 0 1 1 2.062-2.062m-2.062-.938a.937.937 0 1 0 0 1.875H3v-.937a.937.937 0 0 0-.937-.938M7.5 7.5v.938a.937.937 0 1 0 .938-.938zM6.375 6.375v-2.25h-2.25v2.25zM2.063 7.5H3v.938a.937.937 0 1 1-.937-.938M7.5 3h.938a.937.937 0 1 0-.938-.937z" clip-rule="evenodd"></path><path fill="currentColor" d="M15.09 10.5 18.085 0h-1.097L14 10.5zM26.387 5.308c-.183-1.445-1.263-2.534-3.05-2.534C21.264 2.774 20 4.247 20 6.61c0 2.41 1.27 3.89 3.344 3.89 1.76 0 2.86-1.034 3.043-2.5H25.02c-.184.808-.792 1.247-1.682 1.247-1.172 0-1.898-.994-1.898-2.637 0-1.61.72-2.583 1.898-2.583.942 0 1.518.555 1.681 1.281zM28.6 1.041v1.897h-1.133v1.178H28.6v4.281c0 1.432.622 2.007 2.186 2.007.275 0 .537-.034.766-.075V9.158c-.196.02-.32.034-.537.034-.7 0-1.008-.35-1.008-1.15V4.115h1.545V2.938h-1.545V1.041zM33.207 10.356h1.407V5.911c0-1.048.752-1.767 1.819-1.767.249 0 .667.048.785.082V2.842a3.372 3.372 0 0 0-.628-.054c-.93 0-1.721.527-1.924 1.26h-.105v-1.13h-1.354zM38.638 10.356h1.407V0h-1.407z"></path></svg>
        </div>
      </span>
      <span class="sr-only">K key</span>
      <span aria-hidden="true" class="badge h-5 flex items-center">
        <div class="text-primary">
          <svg xmlns="http://www.w3.org/2000/svg" width="8" height="10" fill="none" viewBox="0 0 8 10"><path fill="currentColor" d="M1.512 9.84v-3l.986-1.147L5.445 9.84h1.704L3.46 4.745 6.857.84H5.244L1.61 5.094h-.098V.84H.15v9z"></path></svg>
        </div>
      </span>
    </span>
  </button>

  <div v-if="showModal" class="modal-overlay" @click="showModal = false">
    <div class="modal-content-wrapper">
      <div class="modal-content" aria-modal="true" role="dialog" @click.stop>
        <div class="modal-content-inner" v-bind="autocomplete.getRootProps({})">
          <div class="flex flex-col p-4 border-b border-brand-saturated/40">
            <form class="w-full gap-2 flex items-center" v-bind="formProps" @submit="() => {this.inputElement.focus()}">
              <div class="flex items-center">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M19.6 21L13.3 14.7C12.8 15.1 12.225 15.4167 11.575 15.65C10.925 15.8833 10.2333 16 9.5 16C7.68333 16 6.14583 15.3708 4.8875 14.1125C3.62917 12.8542 3 11.3167 3 9.5C3 7.68333 3.62917 6.14583 4.8875 4.8875C6.14583 3.62917 7.68333 3 9.5 3C11.3167 3 12.8542 3.62917 14.1125 4.8875C15.3708 6.14583 16 7.68333 16 9.5C16 10.2333 15.8833 10.925 15.65 11.575C15.4167 12.225 15.1 12.8 14.7 13.3L21 19.6L19.6 21ZM9.5 14C10.75 14 11.8125 13.5625 12.6875 12.6875C13.5625 11.8125 14 10.75 14 9.5C14 8.25 13.5625 7.1875 12.6875 6.3125C11.8125 5.4375 10.75 5 9.5 5C8.25 5 7.1875 5.4375 6.3125 6.3125C5.4375 7.1875 5 8.25 5 9.5C5 10.75 5.4375 11.8125 6.3125 12.6875C7.1875 13.5625 8.25 14 9.5 14Z" fill="currentColor"/>
                </svg>
              </div>
              <div class="flex items-center border border-brand-saturated/40 rounded-3xl h-full gap-1 pl-2 w-fit" v-for="tag in state.context.tagsPlugin.tags">
                <span class="flex w-fit whitespace-nowrap text-secondary">{{ tag.label }}</span>
                <button
                  class="flex items-center w-fit text-secondary pr-1 self-stretch rounded-r-3xl hover:bg-brand-saturated/40"
                  title="Remove this filter"
                  type="button"
                  :value="tag.value"
                  @click="onRemoveFilter"
                >
                <svg width="8" height="8" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M6.4 19L5 17.6L10.6 12L5 6.4L6.4 5L12 10.6L17.6 5L19 6.4L13.4 12L19 17.6L17.6 19L12 13.4L6.4 19Z" fill="currentColor"/>
                </svg>
                </button>
              </div>

              <div class="relative w-full h-full items-center">
                <input class="text-secondary w-full h-full py-1 pl-2 pr-7 bg-transparent appearance-none rounded-md border-none" ref="inputElement" v-bind="inputProps" placeholder="Search docs..." />
                <div class="absolute flex top-0 right-0 bottom-0 items-center">
                  <button class="p-1" v-show="state.query" title="Clear the query" aria-label="Clear the query"  @click="onClearQuery" type="button">
                    <svg width="20" height="20" viewBox="0 0 20 20"><path d="M10 10l5.09-5.09L10 10l5.09 5.09L10 10zm0 0L4.91 4.91 10 10l-5.09 5.09L10 10z" stroke="currentColor" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                  </button>
                </div>

              </div>
            </form>
          </div>

          <div class="px-4 flex-grow flex-shrink overflow-y-auto" tabIndex="-1">
            <div class="flex w-full" v-bind="autocomplete.getPanelProps({})">
              <template v-if="state.isOpen">
                <div v-if="state.query" class="tabs flex flex-col w-full gap-4" ref="tabsElement">
                  <div class="tablist" role="tablist">
                    <button v-for="(source, key, index) in sources" :key="key" :id="key" :tabIndex="index === 0 ? 0 : -1" class="tab-button__horizontal items-center gap-[6px]" :class="{ 'tab-button__horizontal--active': activeTab === key }" :aria-controls="`navtab-tabpanel-${key}`" role="tab" :aria-selected="activeTab === key" @click="onTabClick(key, $event)" @keydown="onKeyDown(key, $event)">
                      <svg v-if="key === 'docs'" width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M8 18H16V16H8V18ZM8 14H16V12H8V14ZM6 22C5.45 22 4.97917 21.8042 4.5875 21.4125C4.19583 21.0208 4 20.55 4 20V4C4 3.45 4.19583 2.97917 4.5875 2.5875C4.97917 2.19583 5.45 2 6 2H14L20 8V20C20 20.55 19.8042 21.0208 19.4125 21.4125C19.0208 21.8042 18.55 22 18 22H6ZM13 9V4H6V20H18V9H13Z" fill="rgb(var(--color-text-terciary))"/>
                      </svg>

                      <svg v-if="key === 'how_tos'" width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M14 9.9V8.2C14.55 7.96667 15.1125 7.79167 15.6875 7.675C16.2625 7.55833 16.8667 7.5 17.5 7.5C17.9333 7.5 18.3583 7.53333 18.775 7.6C19.1917 7.66667 19.6 7.75 20 7.85V9.45C19.6 9.3 19.1958 9.1875 18.7875 9.1125C18.3792 9.0375 17.95 9 17.5 9C16.8667 9 16.2583 9.07917 15.675 9.2375C15.0917 9.39583 14.5333 9.61667 14 9.9ZM14 15.4V13.7C14.55 13.4667 15.1125 13.2917 15.6875 13.175C16.2625 13.0583 16.8667 13 17.5 13C17.9333 13 18.3583 13.0333 18.775 13.1C19.1917 13.1667 19.6 13.25 20 13.35V14.95C19.6 14.8 19.1958 14.6875 18.7875 14.6125C18.3792 14.5375 17.95 14.5 17.5 14.5C16.8667 14.5 16.2583 14.575 15.675 14.725C15.0917 14.875 14.5333 15.1 14 15.4ZM14 12.65V10.95C14.55 10.7167 15.1125 10.5417 15.6875 10.425C16.2625 10.3083 16.8667 10.25 17.5 10.25C17.9333 10.25 18.3583 10.2833 18.775 10.35C19.1917 10.4167 19.6 10.5 20 10.6V12.2C19.6 12.05 19.1958 11.9375 18.7875 11.8625C18.3792 11.7875 17.95 11.75 17.5 11.75C16.8667 11.75 16.2583 11.8292 15.675 11.9875C15.0917 12.1458 14.5333 12.3667 14 12.65ZM6.5 16C7.28333 16 8.04583 16.0875 8.7875 16.2625C9.52917 16.4375 10.2667 16.7 11 17.05V7.2C10.3167 6.8 9.59167 6.5 8.825 6.3C8.05833 6.1 7.28333 6 6.5 6C5.9 6 5.30417 6.05833 4.7125 6.175C4.12083 6.29167 3.55 6.46667 3 6.7V16.6C3.58333 16.4 4.1625 16.25 4.7375 16.15C5.3125 16.05 5.9 16 6.5 16ZM13 17.05C13.7333 16.7 14.4708 16.4375 15.2125 16.2625C15.9542 16.0875 16.7167 16 17.5 16C18.1 16 18.6875 16.05 19.2625 16.15C19.8375 16.25 20.4167 16.4 21 16.6V6.7C20.45 6.46667 19.8792 6.29167 19.2875 6.175C18.6958 6.05833 18.1 6 17.5 6C16.7167 6 15.9417 6.1 15.175 6.3C14.4083 6.5 13.6833 6.8 13 7.2V17.05ZM12 20C11.2 19.3667 10.3333 18.875 9.4 18.525C8.46667 18.175 7.5 18 6.5 18C5.8 18 5.1125 18.0917 4.4375 18.275C3.7625 18.4583 3.11667 18.7167 2.5 19.05C2.15 19.2333 1.8125 19.225 1.4875 19.025C1.1625 18.825 1 18.5333 1 18.15V6.1C1 5.91667 1.04583 5.74167 1.1375 5.575C1.22917 5.40833 1.36667 5.28333 1.55 5.2C2.31667 4.8 3.11667 4.5 3.95 4.3C4.78333 4.1 5.63333 4 6.5 4C7.46667 4 8.4125 4.125 9.3375 4.375C10.2625 4.625 11.15 5 12 5.5C12.85 5 13.7375 4.625 14.6625 4.375C15.5875 4.125 16.5333 4 17.5 4C18.3667 4 19.2167 4.1 20.05 4.3C20.8833 4.5 21.6833 4.8 22.45 5.2C22.6333 5.28333 22.7708 5.40833 22.8625 5.575C22.9542 5.74167 23 5.91667 23 6.1V18.15C23 18.5333 22.8375 18.825 22.5125 19.025C22.1875 19.225 21.85 19.2333 21.5 19.05C20.8833 18.7167 20.2375 18.4583 19.5625 18.275C18.8875 18.0917 18.2 18 17.5 18C16.5 18 15.5333 18.175 14.6 18.525C13.6667 18.875 12.8 19.3667 12 20Z" fill="rgb(var(--color-text-terciary))"/>
                      </svg>

                      <svg v-if="key === 'plugins'" width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M11.5 19H12.5V17.15L16 13.65V9H8V13.65L11.5 17.15V19ZM9.5 21V18L6 14.5V9C6 8.45 6.19583 7.97917 6.5875 7.5875C6.97917 7.19583 7.45 7 8 7H9L8 8V3H10V7H14V3H16V8L15 7H16C16.55 7 17.0208 7.19583 17.4125 7.5875C17.8042 7.97917 18 8.45 18 9V14.5L14.5 18V21H9.5Z" fill="rgb(var(--color-text-terciary))"/>
                      </svg>

                      {{ source.label }}
                    </button>
                  </div>
                  <div class="navtab-contents flex flex-col">
                    <div v-for="{ source, items } in state.collections" :key="`source-${source.sourceId}`" >
                      <div v-show="activeTab === source.sourceId" class="navtab-content flex flex-col gap-3" role="tabpanel" :id="`navtab-tabpanel-${source.sourceId}`" :aria-labelledby="source.sourceId">
                        <ul v-if="items.length > 0" v-bind="autocomplete.getListProps()" class="list-none gap-3 ml-0">
                          <li v-for="item in items" :key="item.handle" v-bind="autocomplete.getItemProps({item, source})">
                            <SearchModalResultItem :item="item" />
                          </li>
                        </ul>
                        <div v-else>
                          No matches for "{{ state.query  }}" were found.
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

              </template>
            </div>
          </div>

          <div class="md:flex w-full p-4 items-center flex-grow-0 flex-shrink-0 border-t border-brand-saturated/40 justify-between">
            <div class="hidden md:flex gap-2 items-center">
              <span class="sr-only">Tab key</span>
              <span aria-hidden="true" class="badge h-5 flex items-center text-primary">
                <span>Tab</span>
              </span>
              <span class="text_root__r0DFB hds-typography-body-100 hds-font-weight-regular">to navigate,</span>
              <span class="sr-only">Enter key</span>
              <span aria-hidden="true" class="badge h-5 flex items-center text-primary">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" viewBox="0 0 16 16" aria-hidden="true"><path fill="currentColor" d="M13.5 2.75a.75.75 0 00-1.5 0v4.5A1.75 1.75 0 0110.25 9H4.56l2.22-2.22a.75.75 0 00-1.06-1.06l-3.5 3.5a.748.748 0 000 1.06l3.5 3.5a.75.75 0 001.06-1.06L4.56 10.5h5.69a3.25 3.25 0 003.25-3.25v-4.5z"></path></svg>
              </span>
              <span class="text_root__r0DFB hds-typography-body-100 hds-font-weight-regular">to select,</span>
              <span class="sr-only">Escape key</span>
              <span aria-hidden="true" class="badge h-5 flex items-center text-primary">
                <span>Esc</span>
              </span>
              <span class="text_root__r0DFB hds-typography-body-100 hds-font-weight-regular">to exit</span>
           </div>
            <a href="/search" class="text-brand flex justify-self-end">Advanced search</a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, nextTick } from 'vue';
import { liteClient as algoliasearch } from 'algoliasearch/lite';
import { createAutocomplete } from '@algolia/autocomplete-core';
import { getAlgoliaResults } from '@algolia/autocomplete-preset-algolia';
import { createTagsPlugin } from '@algolia/autocomplete-plugin-tags';
import SearchModalResultItem from './components/SearchModalResultItem.vue';


export default {
  name: "Autocomplete",
  components: {
    SearchModalResultItem
  },
  data() {
    return {
      activeTab: 'all',
    }
  },
  mounted() {
    window.addEventListener("keydown", this.handleKeyPress);
  },
  beforeUnmount() {
    window.removeEventListener("keydown", this.handleKeyPress);
  },
  setup(props) {
    const inputElement = ref(null);
    const tabsElement = ref(null);
    const showModal = ref(false);
    const sources = ref(window.searchSources);

    const hitsPerPage = 20;
    const indexName = import.meta.env.VITE_ALGOLIA_INDEX_NAME;

    const state = ref({
      collections: [],
      completion: null,
      context: {},
      isOpen: false,
      query: "",
      activeItemId: null,
      status: "idle",
    });

    const formProps = computed(() =>
      autocomplete.value.getFormProps({
        inputElement: inputElement.value,
      })
    );

    const inputProps = computed(() => {
      const { onChange, value, type, ...rest } = autocomplete.value.getInputProps({
        inputElement: inputElement.value,
      });

      return {
        onInput: onChange,
        ...rest,
      };
    });

    const searchClient = algoliasearch(
      import.meta.env.VITE_ALGOLIA_APPLICATION_ID,
      import.meta.env.VITE_ALGOLIA_API_KEY
    );

    const initialTags = [];
    const searchFilters = window.searchFilters;
    const productMeta = document.querySelector('meta[name="algolia:products"]');
    const toolMeta = document.querySelector('meta[name="algolia:tools"]');

    if (productMeta !== null) {
      const products = productMeta.getAttribute('content').trim().split(',');
      const productsFilter = searchFilters.products.filter((f) => products.includes(f.value));
      if (productsFilter) {
        productsFilter.forEach((productFilter) => {
          initialTags.push({ label: productFilter.label, value: productFilter.value, facet: 'products' });
        })
      }
    } else  {
      if (toolMeta !== null) {
        const tools = toolMeta.getAttribute('content').trim().split(',');
        const toolsFilter = searchFilters.tools.filter((f) => tools.includes(f.value));
        if (toolsFilter && toolsFilter.length === 1) {
          const tool = toolsFilter[0];
          initialTags.push({ label: tool.label, value: tool.value, facet: 'tools' });
        }
      }
    }



    const originalTags = initialTags.slice();

    const tagsPlugin = createTagsPlugin({
      initialTags: initialTags,
      transformSource() {
        return undefined;
      }
    });

    const autocomplete = computed(() =>
      createAutocomplete({
        plugins: [tagsPlugin],
        onStateChange(params) {
          if (params.state.isOpen === false && params.state.query) {
            state.value = {...params.state, isOpen: true};
          } else {
            state.value = params.state;
          }
        },
        getSources({ query, state }) {
          function formatGroupedFilters(grouped) {
            return Object.entries(grouped)
              .map(([facet, items]) => items.map(item => `${facet}:${item.value}`).join(' OR '))
              .join(' OR ');
          }
          const applyFilter = (existingQuery) => {
            let query = existingQuery;
            const filtersByFacet = (items) => {
              return items.reduce((acc, item) => {
                (acc[item.facet] ||= []).push(item);
                return acc;
              }, {});
            }

            if (state.context.tagsPlugin.tags) {
              const filters = formatGroupedFilters(filtersByFacet(state.context.tagsPlugin.tags));

              if (filters.length > 0) {
                if (query === '') {
                  query += `(${filters})`;
                } else {
                  query += ` AND ${filters}`;
                }
              }
            }
            return query;
          }

          return Object.entries(sources.value).map(([sourceId, { filters }]) => ({
            sourceId,
            getItems() {
              return getAlgoliaResults({
                searchClient,
                queries: [
                  {
                    indexName,
                    params: {
                      query,
                      hitsPerPage,
                      filters: applyFilter(filters),
                    },
                  },
                ],
              });
            },
            onSelect({ setQuery }) {
              setQuery('');
              inputElement.value = '';
              showModal.value = false;
            },
          }));
        },
      })
    );

    return {
      inputElement,
      tabsElement,
      state,
      formProps,
      inputProps,
      autocomplete,
      tagsPlugin,
      showModal,
      sources,
      originalTags,
      tagsPlugin
    };
  },
  watch: {
    showModal(newValue) {
      if (newValue === false) {
        this.closeModal();
      }
    }
  },
  methods: {
    handleKeyPress(event) {
      if ((event.metaKey && event.key === 'k') || (event.ctrlKey && event.key === 'k')) {
        event.preventDefault();
        this.openModal();
      } else if (event.key === 'Escape' && this.showModal) {
        this.showModal = false;
      }
    },
    onTabClick(tabId, event) {
      event.preventDefault()
      event.stopPropagation();
      this.setActiveTab(tabId)
    },
    setActiveTab(tabId) {
      this.activeTab = tabId;
      this.updateTabIndexes(tabId);
    },
    updateTabIndexes(activeId) {
      const buttons = this.tabsElement.querySelectorAll('[role="tab"]');
      buttons.forEach(button => {
        if (button.id === activeId) {
            button.tabIndex = 0;
            button.focus();
        } else {
            button.tabIndex = -1;
        }
      });
    },
    onKeyDown(tabId, event) {
      const buttons = Array.from(this.tabsElement.querySelectorAll('[role="tab"]'));
      const currentIndex = buttons.findIndex(button => button.id === tabId);

      if (event.key === 'ArrowLeft') {
        event.preventDefault();
        const prevIndex = (currentIndex - 1 + buttons.length) % buttons.length;
        buttons[prevIndex].focus();
        this.setActiveTab(buttons[prevIndex].id);
      } else if (event.key === 'ArrowRight') {
        event.preventDefault();
        const nextIndex = (currentIndex + 1) % buttons.length;
        buttons[nextIndex].focus();
        this.setActiveTab(buttons[nextIndex].id);
      }
    },
    onRemoveFilter(event) {
      const button = event.target.closest('button')
      event.stopPropagation();
      this.tagsPlugin.data.setTags(
        this.state.context.tagsPlugin.tags.filter((t) => t.value !== button.value)
      );
    },
    onClearQuery(event) {
      event.preventDefault();
      event.stopPropagation();
      this.state.query = '';
      this.inputElement.value = '';
    },
    openModal() {
      this.showModal = true;
      document.body.style.setProperty("overflow", "hidden");
      document.body.style.setProperty("overscroll-behavior", "contain");
      document.body.style.setProperty("margin-right", "var(--removed-body-scroll-bar-size)");
      this.tagsPlugin.data.setTags(this.originalTags);

      nextTick(() => {
        document.activeElement?.blur();
        setTimeout(() => { this.inputElement.focus()}, 100);
      });
    },
    closeModal() {
      document.body.style.overflow = "";
      document.body.style.removeProperty("overscoll-behavior");
      document.body.style.removeProperty("margin-right");
    },
  },
};

</script>

<style>
.modal-overlay {
  @apply fixed top-0 right-0 bottom-0 left-0 flex items-center justify-center z-50 overflow-hidden bg-primary/70;
}

.modal-content-wrapper {
  @apply flex flex-col items-center h-screen w-screen md:p-6 mt-20;
}

.modal-content {
  @apply overflow-y-auto bg-secondary h-fit w-full md:max-w-3xl  md:min-w-[563px] rounded-md shadow-primary;
}

.modal-content-inner {
  @apply flex flex-col h-full min-h-80 max-h-[660px];
}
</style>
