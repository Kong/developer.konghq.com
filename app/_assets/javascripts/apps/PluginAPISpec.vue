<template>
  <SpecRenderer
   navigation-type="hash"
   :allowContentScrolling="true"
   :base-path="basePath"
   :control-address-bar="true"
   :current-path="currentPathDOC || '/'"
   :hide-insomnia-try-it="true"
   :hide-try-it="true"
   :spec="specText"
   />
</template>

<script setup>
import { ref } from 'vue';
import { SpecRenderer } from '@kong/spec-renderer-dev';

const specText = ref(JSON.stringify(window.apiSpec));
const basePath = window.location.pathname;
const currentPathDOC = ref(window.location.hash.substring(1));
</script>

<style scoped>
:deep(.spec-renderer-small-screen-header) {
  @apply top-16 !important;
}
</style>