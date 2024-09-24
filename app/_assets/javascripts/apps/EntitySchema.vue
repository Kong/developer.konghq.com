<template>
  <div>
    <main class="page-main">
      <SpecModelNode
        v-if="schema"
        :schema="schema.data"
      />
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue'

import { SpecModelNode, parseSpecDocument, parsedDocument } from '@kong/spec-renderer-dev'
import ApiService from '../services/api.js'

const { path, product, version } = window.entitySchema;

const versionsAPI = new ApiService().versionsAPI;
const specText = ref('');
const currentPath = ref(path);
const productId = ref(product.id);
const productVersionId = ref(version.id);

const schema = computed(() => {
  if (parsedDocument.value !== undefined) {
    return parsedDocument.value.children.find((child) => child.uri === currentPath.value)
  }
})

onMounted(async () => {
  await fetchSpec()
})

watch((specText), async (newSpecText, oldSpecText) => {
  await parseSpecDocument(newSpecText, {
    hideSchemas: true,
    hideInternal: true,
    traceParsing: false,
    specUrl: null,
    withCredentials: false,
  })
})

async function fetchSpec() {
  let response = await versionsAPI.getProductVersionSpec({
    productId: productId.value,
    productVersionId: productVersionId.value,
  }).catch(e => {
    console.log(e)
  })
  specText.value = response.data.content
}
</script>

<style scoped>
:deep(code) {
  @apply bg-secondary rounded border border-brand-saturated/40 text-xs py-0 px-1 !important;
}

:deep(.property-field-default-value) {
  @apply bg-secondary rounded border border-brand-saturated/40 text-xs py-0 px-1 shadow-none !important;
}

:deep(.model-node-container:not(.nested-model-node) > .model-node-property) {
  @apply border-t border-primary/5 !important;
}

</style>