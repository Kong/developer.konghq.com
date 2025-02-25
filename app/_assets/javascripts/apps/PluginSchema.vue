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
  import { SchemaRenderer } from '@kong/spec-renderer-dev'

  const schema = window.schema;
  </script>