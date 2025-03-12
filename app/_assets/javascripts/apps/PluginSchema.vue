<template>
    <div>
      <SchemaRenderer
        v-if="schema"
        :schema="schema"
        :exampleVisible="false"
        :headerVisible="false"
        :enablePropertyLinks="true"
      />
    </div>
  </template>

<script setup>
import { SchemaRenderer } from '@kong/spec-renderer'

const schema = window.schema;
</script>

<style scoped>
:deep(.kui-icon.link-icon) {
  @apply w-5 h-5 !important;
}
</style>