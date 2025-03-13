<template>
  <div class="flex w-full">
    <a :href="relativeUrl" class="flex w-full p-3 rounded-md bg-primary border border-primary/5 shadow-primary hover:no-underline hover:border-brand-saturated/40 hover:shadow-hover-card  focus:border-brand-saturated/40 focus:shadow-hover-card">
      <div class="flex flex-col w-full gap-2">
        <div class="text-terciary text-xs">
          {{ breadcrumbs }}
        </div>
        <div class="text-primary font-bold text-base">
          {{ heading }}
        </div>
        <div class="text-secondary text-sm">
          <SearchResultSnippet v-if="highlighetContent" :item="item" attribute="content" />
          <span v-else>{{ item.content }}</span>
        </div>
      </div>
    </a>
  </div>
</template>

<script>
import SearchResultSnippet from './SearchResultSnippet.vue';

export default {
  props: {
    item: Object,
  },
  components: {
    SearchResultSnippet
  },
  computed: {
    highlighetContent() {
      return this.item._highlightResult?.content?.matchLevel !== 'none';
    },
    heading() {
      if (this.item.content_type === 'plugin_example') {
        return this.item.title;
      }
      if (this.item.content_type === 'plugin') {
        return `${this.item.hierarchy.lvl1} Plugin`;
      }
      const levels = Object.entries(this.item.hierarchy)
        .filter(([key, value]) => key !== 'lvl0' && value !== null);

      if (levels.length > 0) {
        return levels[levels.length - 1][1];
      }
      return ''; // Or handle the case where there are no levels
    },
    breadcrumbs() {
      const levels = Object.entries(this.item.hierarchy)
        .filter(([key, value]) => key !== 'lvl0' && value !== null)
        .map(([key, value]) => value);

      if (this.item.content_type === 'plugin') {
        levels.unshift('Plugins')
      }
      if (this.item.content_type === 'how_to') {
        levels.unshift('How-to Guides')
      }
      return levels.join(' > ');
    },
    relativeUrl() {
      const urlObj = new URL(this.item.url);
      return `${urlObj.pathname}${urlObj.hash}`;
    },
  },
};
</script>