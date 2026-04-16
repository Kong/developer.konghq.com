<template>
  <div>
    <main class="page-main">
      <SchemaRenderer
        v-if="schema"
        :schema="schema.data"
        :exampleVisible="false"
        :headerVisible="false"
        :enablePropertyLinks="true"
        :maxExpandedDepth="4"
      />
    </main>
  </div>
</template>

<script setup>
import { ref, toRaw, onMounted, watch, computed } from 'vue'

import { SchemaRenderer, parseSpecDocument, parsedDocument } from '@kong/spec-renderer'
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

watch(schema, (node) => {
  if (node) {
    annotateNode(toRaw(node.data))
  }
}, { once: true })

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

function annotateNode(obj) {
  if (Array.isArray(obj)) {
    obj.forEach(annotateNode)
  } else if (obj && typeof obj === 'object') {
    if (obj['x-referenceable'] === true) {
      const note = 'This field is [referenceable](/gateway/entities/vault/#how-do-i-reference-secrets-stored-in-a-vault).'
      obj.description = obj.description ? `${obj.description.trimEnd()}\n${note}` : note
    }
    if (obj['x-min-runtime-version']) {
      const note = `Min runtime version: \`${obj['x-min-runtime-version']}\``;
      obj.description = obj.description ? `${obj.description.trimEnd()}\n${note}` : note
    }
    Object.values(obj).forEach(annotateNode)
  }
}

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

:deep(.kui-icon.link-icon) {
  @apply w-5 h-5 !important;
}

:deep(.property-field-default-value),
:deep(.property-field-pattern-value),
:deep(.property-field-enum-value),
:deep(.property-field-example-value) {
  @apply border border-brand-saturated/40 !important;
}

:deep(.default-markdown a[href^="http://"]),
:deep(.default-markdown a[href^="https://"]) {
  @apply bg-none pr-0 !important;
}
</style>
