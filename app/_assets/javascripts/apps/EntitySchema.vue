<template>
  <div class="sandbox-container">
    <main class="page-main">
      <SpecDocument
        v-if="parsedDocument"
        :allow-content-scrolling="false"
        :current-path="currentPath"
        :document="parsedDocument"
        :hide-insomnia-try-it="true"
        :hide-try-it="true"
      />
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'

import { SpecDocument, parseSpecDocument, parsedDocument } from '@kong/spec-renderer-dev'
import ApiService from '../services/api.js'

const { path, product, version } = window.entitySchema;

const versionsAPI = new ApiService().versionsAPI;
const specText = ref('');
const currentPath = ref(path);
const productId = ref(product.id);
const productVersionId = ref(version.id);

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
