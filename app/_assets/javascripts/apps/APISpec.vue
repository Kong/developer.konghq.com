<template>
  <div class="flex w-full gap-16">
      <SpecRenderer
        v-if="specText"
        :spec="specText"
        navigation-type="hash"
        :base-path="basePath"
    />
  </div>
</template>

<script setup>
import { onBeforeMount, ref, watch } from 'vue';
import { SpecRenderer, parseSpecDocument } from '@kong/spec-renderer-dev';
import ApiService from '../services/api.js'

const { product_id, version_id } = window.apiSpec;
const versionsAPI = new ApiService().versionsAPI;
const productId = ref(product_id);
const productVersionId = ref(version_id);
const specText = ref('');
const basePath = window.location.pathname;

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
  let response = await versionsAPI.getProductVersionSpec({
    productId: productId.value,
    productVersionId: productVersionId.value,
  }).catch(e => {
    console.log(e)
  })
  specText.value = response.data.content
}
</script>