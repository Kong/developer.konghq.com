<template>
    <div>
      <SchemaRenderer
        v-if="schema"
        :schema="schema"
        :exampleVisible="false"
        :headerVisible="false"
        :enablePropertyLinks="true"
        :maxExpandedDepth="10"
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
:deep(.property-field-default-value),
:deep(.property-field-pattern-value),
:deep(.property-field-enum-value),
:deep( .property-field-example-value) {
  @apply border border-brand-saturated/40 !important;
}

:deep(.default-markdown a[href^="http://"]),
:deep(.default-markdown a[href^="https://"]) {
  @apply bg-none pr-0 !important;
}
</style>
