<template>
  <button aria-label="Search" class="cursor-pointer flex gap-4 items-center justify-between w-fit border rounded-md border-brand py-1 px-2 text-terciary" @click="openModal">
    <span class="flex items-center gap-2 flex-shrink-0">
      <span class="flex">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M19.6 21L13.3 14.7C12.8 15.1 12.225 15.4167 11.575 15.65C10.925 15.8833 10.2333 16 9.5 16C7.68333 16 6.14583 15.3708 4.8875 14.1125C3.62917 12.8542 3 11.3167 3 9.5C3 7.68333 3.62917 6.14583 4.8875 4.8875C6.14583 3.62917 7.68333 3 9.5 3C11.3167 3 12.8542 3.62917 14.1125 4.8875C15.3708 6.14583 16 7.68333 16 9.5C16 10.2333 15.8833 10.925 15.65 11.575C15.4167 12.225 15.1 12.8 14.7 13.3L21 19.6L19.6 21ZM9.5 14C10.75 14 11.8125 13.5625 12.6875 12.6875C13.5625 11.8125 14 10.75 14 9.5C14 8.25 13.5625 7.1875 12.6875 6.3125C11.8125 5.4375 10.75 5 9.5 5C8.25 5 7.1875 5.4375 6.3125 6.3125C5.4375 7.1875 5 8.25 5 9.5C5 10.75 5.4375 11.8125 6.3125 12.6875C7.1875 13.5625 8.25 14 9.5 14Z" fill="currentColor"/>
        </svg>
      </span>
      <span class="text-sm">Search</span>
    </span>
    <span class="flex items-center gap-1 flex-shrink-0">
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

  <div v-if="showModal" class="modal-overlay" @click="closeModal">
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
                  class="flex items-center w-fit text-secondary pr-2 self-stretch rounded-r-3xl hover:bg-brand-saturated/40"
                  title="Remove this filter"
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

          <div class="px-4 flex-grow flex-shrink overflow-y-auto">
            <div class="flex w-full" v-bind="autocomplete.getPanelProps({})">
              <template v-if="state.isOpen">
                <div v-if="state.query" class="tabs flex flex-col w-full gap-4" ref="tabsElement">
                  <div class="tablist" role="tablist">
                      <button tabIndex = "0" id="docs" class="tab-button__horizontal" :class="{ 'tab-button__horizontal--active': activeTab === 'docs' }" aria-controls="navtab-tabpanel-docs" role="tab" :aria-selected="activeTab === 'docs'" @click="onTabClick('docs', $event)" @keydown="onKeyDown('docs', $event)">
                        Docs
                      </button>
                      <button tabIndex = "-1" id="how_tos" class="tab-button__horizontal" :class="{ 'tab-button__horizontal--active': activeTab === 'how_tos' }" aria-controls="navtab-tabpanel-how_tos" role="tab" :aria-selected="activeTab === 'how_tos'" @click="onTabClick('how_tos', $event)" @keydown="onKeyDown('how_tos', $event)">
                        How-to Guides
                      </button>
                      <button tabIndex = "-1" id="plugins" class="tab-button__horizontal" :class="{ 'tab-button__horizontal--active': activeTab === 'plugins' }" aria-controls="navtab-tabpanel-plugins" role="tab" :aria-selected="activeTab === 'plugins'" @click="onTabClick('plugins', $event)" @keydown="onKeyDown('plugins', $event)">
                        Plugins
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

          <div class="hidden md:flex w-full gap-2 p-4 items-center flex-grow-0 flex-shrink-0">
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
      activeTab: 'docs',
      showModal: false,
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

    const hitsPerPage = 20;
    const indexName = 'kongdeveloper';

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
      'Z2JDSBZWKU',
      '7eaf59d4529f8b3bb44e5a8556aac227',
    );

    const initialTags = [];
    const productMeta = document.querySelector('meta[name="algolia:products"]');
    if (productMeta !== null) {
      const product = productMeta.getAttribute('content').trim();
      initialTags.push({ label: product, facet: 'products' });
    }

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
        getSources({ query, state, setContext }) {
          const applyProductFilter = (existingQuery) => {
            let query = existingQuery;
            if (state.context.tagsPlugin.tags) {
              state.context.tagsPlugin.tags.forEach(tag => {
                query += ` AND products:'${tag.label}'`;
              });
            }
            return query;
          }

          return [
            {
              sourceId: "docs",
              getItems() {
                return getAlgoliaResults({
                  searchClient,
                  queries: [
                    {
                      indexName: indexName,
                      params: {
                        query,
                        hitsPerPage: hitsPerPage,
                        filters: applyProductFilter('NOT content_type:how_to AND NOT content_type:plugin')
                      },
                    },
                  ]
                })
              },

              onSelect({ item, setQuery }) {
                setQuery('');
                inputElement.value = '';
              },
            },
            {
              sourceId: 'how_tos',
              getItems() {
                return getAlgoliaResults({
                  searchClient,
                  queries: [
                    {
                      indexName: indexName,
                      params: {
                        query,
                        hitsPerPage: hitsPerPage,
                        filters: applyProductFilter('content_type:how_to')
                      },
                    },
                  ]
                })
              }
            },
            {
              sourceId: 'plugins',
              getItems() {
                return getAlgoliaResults({
                  searchClient,
                  queries: [
                    {
                      indexName: indexName,
                      params: {
                        query,
                        hitsPerPage: hitsPerPage,
                        filters: applyProductFilter('content_type:plugin')
                      },
                    },
                  ]
                })
              }
            }
          ];
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
      tagsPlugin
    };
  },
  methods: {
    handleKeyPress(event) {
      if ((event.metaKey && event.key === 'k') || (event.ctrlKey && event.key === 'k')) {
        event.preventDefault();
        this.openModal();
      } else if (event.key === 'Escape' && this.showModal) {
        this.closeModal();
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
      event.stopPropagation();
      this.tagsPlugin.data.setTags([]);
    },
    onClearQuery(event) {
      event.preventDefault();
      event.stopPropagation();
      this.state.query = '';
      this.inputElement.value = '';
    },
    openModal() {
      this.showModal = true;
      document.body.style.overflow = "hidden";
      nextTick(() => {
        document.activeElement?.blur();
        setTimeout(() => { this.inputElement.focus()}, 100);
      });
    },
    closeModal() {
      this.showModal = false;
      document.body.style.overflow = "";
    },
  },
};

</script>

<style>
.modal-overlay {
  @apply fixed top-0 right-0 bottom-0 left-0 flex items-center justify-center z-50 overflow-hidden bg-primary/70;
}

.modal-content-wrapper {
  @apply flex flex-col items-center h-screen w-screen p-6 mt-20;
}

.modal-content {
  @apply overflow-y-auto bg-secondary h-fit w-full max-w-3xl  min-w-[563px] rounded-md shadow-primary;
}

.modal-content-inner {
  @apply flex flex-col h-full min-h-80 max-h-[660px];
}
</style>
