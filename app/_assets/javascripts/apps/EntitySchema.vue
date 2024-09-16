<template>
  <div class="sandbox-container">
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
:deep(.default-markdown) {
  @apply text-secondary !important;
}
:deep(.property-type) {
  @apply text-secondary !important;
}
:deep(code) {
  @apply bg-code-block text-white !important;
}
:deep(.property-title-name) {
  @apply  text-brand !important;
}
</style>