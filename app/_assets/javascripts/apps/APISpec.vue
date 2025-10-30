<template>
  <div v-if="tableOfContents" class="sticky top-16 flex md:hidden">
    <button
      class="px-3 md:px-6"
      type="button"
      @click="openSlideoutToc"
    >
      <MenuIcon />
    </button>
  </div>

  <div>
    <KSlideout
      v-if="!loading && tableOfContents"
      :title="parsedDocument?.name || 'Table of Contents'"
      :visible="slideoutTocVisible"
      @close="hideSlideout"
    >
      <SpecRendererToc
        v-if="slideoutTocVisible"
        navigation-type="hash"
        :base-path="basePath"
        :table-of-contents="tableOfContents"
        :control-address-bar="true"
        :current-path="currentPathTOC"
        @item-selected="itemSelected"
      />
    </KSlideout>

    <KSkeleton v-if="loading" type="spinner" class="mx-auto items-center justify-center min-h-52 flex"/>

    <div v-if="!loading" class="flex gap-10 w-full">
      <aside class="sticky top-24 left-0 flex-col gap-3 flex-shrink-0 w-64 hidden md:flex h-screen">
        <KSelect
          :items="versions"
          @selected="onVersionSelect"
          class="mt-2"
        />

        <SpecRendererToc
          v-if="!loading && tableOfContents && !slideoutTocVisible"
          navigation-type="hash"
          :base-path="basePath"
          :table-of-contents="tableOfContents"
          :control-address-bar="true"
          :current-path="currentPathTOC"
          @item-selected="itemSelected"
        />
      </aside>

      <div class="flex flex-col w-full">
        <SpecDocument
          v-if="!loading && parsedDocument"
          :document="parsedDocument"
          navigation-type="hash"
          :base-path="basePath"
          :control-address-bar="true"
          @content-scrolled="onDocumentScroll"
          :current-path="currentPathDOC"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { onBeforeMount, ref, watch } from 'vue';
import { SpecDocument, SpecRendererToc, parseSpecDocument,  parsedDocument, tableOfContents } from '@kong/spec-renderer';
import ApiService from '../services/api.js';
import { KSkeleton, KSelect, KSlideout } from '@kong/kongponents';
import { MenuIcon } from '@kong/icons'
import '@kong/kongponents/dist/style.css';
import axios from 'axios';


function sortVersionsDescending(versions) {
  const isVPrefixed = versions[0].label.startsWith('v');

  const toSegments = (v) =>
    (isVPrefixed ? v.label.slice(1) : v.label)
      .split('.')
      .map(Number);

  return versions.sort((a, b) => {
    const aParts = toSegments(a);
    const bParts = toSegments(b);

    for (let i = 0; i < Math.max(aParts.length, bParts.length); i++) {
      const aNum = aParts[i] || 0;
      const bNum = bParts[i] || 0;
      if (aNum !== bNum) return bNum - aNum;
    }
    return 0;
  });
}

const loading = ref(true);
const { product_id, version_id } = window.apiSpec;
const versionsAPI = new ApiService().versionsAPI;
const productId = ref(product_id);
const productVersionId = ref(version_id);
const specText = ref('');
const currentPathTOC = ref(window.location.hash.substring(1));
const currentPathDOC = ref(window.location.hash.substring(1));
const basePath = window.location.pathname;
const slideoutTocVisible = ref(false)

const versions = sortVersionsDescending(window.versions.map((v) => {
  return { ...v, selected: v.id === version_id };
}));

onBeforeMount(async () =>  {
  await fetchSpec();
})

watch((specText), async (newSpecText, oldSpecText) => {
  await parseSpecDocument(newSpecText, {
    traceParsing: false,
    specUrl: null,
    withCredentials: false,
  })
})

async function fetchSpec() {
  let response = await axios.get(`${import.meta.env.VITE_PORTAL_API_URL}api/v3/apis/${productId.value}/versions/${productVersionId.value}/`)
  .catch(e => {
    console.log(e)
  }).finally(() => {
    loading.value = false;
  });
  specText.value = response.data.content || response.data.spec.content;
}

const onDocumentScroll = (path) => {
  currentPathTOC.value = path
  // we need to re-calculate initiallyExpanded property based on the new path
  window.history.pushState({}, '', basePath + path)
}

const itemSelected = (id) => {
  currentPathTOC.value = id;
  currentPathDOC.value = id;

  slideoutTocVisible.value = false;
}

const onVersionSelect = (version) => {
  let path = version.value;
  if (window.location.hash !== '') {
    path += window.location.hash;
  }
  window.location.href = path;
  return;
}

const hideSlideout = () => {
  slideoutTocVisible.value = false
}

const openSlideoutToc = async () => {
  slideoutTocVisible.value = true
}
</script>

<style scoped>
.table-of-contents {
  height: 100%;
}

:deep(.overview-page-versions .label-badge.primary)   {
  @apply text-primary !important;
}

:deep(.overview-page-versions .label-badge.neutral)   {
  @apply bg-semantic-grey-secondary text-semantic-grey-primary !important;
}

:deep(.property-field-default-value),
:deep(.property-field-enum-value),
:deep( .property-field-example-value) {
  @apply border border-brand-saturated/40 !important;
}

:deep(.default-markdown a[href^="http://"]),
:deep(.default-markdown a[href^="https://"]) {
  @apply bg-none !important;
}

:deep(.overview-server-list button.secondary) {
  @apply !bg-brand !text-white;
}

:deep(.overview-server-list button.tertiary) {
  @apply !border !border-brand !text-primary;
}

:deep(.variable-container input) {
  @apply bg-secondary;
}
</style>