<template>
    <div class="product-icon" :class="[name, { 'product-icon--background': background, 'product-icon--bordered': bordered }]" :style="{ 'background-color': background && `rgb(var(--color-${name}-background))` }">
        <component :is="iconComponent" v-if="iconComponent" :class="customClass" />
    </div>
</template>

<script>
import advancedAnalytics from '@/icons/products/advanced-analytics.svg'
import AIGateway from '@/icons/products/ai-gateway.svg'
import APIOps from '@/icons/products/api-ops.svg'
import devPortal from '@/icons/products/dev-portal.svg'
import gateway from '@/icons/products/gateway.svg'
import insomnia from '@/icons/products/insomnia.svg'
import operator from '@/icons/products/operator.svg'
import kic from '@/icons/products/kic.svg'
import mesh from '@/icons/products/mesh.svg'
import orgManagement from '@/icons/products/org-management.svg'
import serviceCatalog from '@/icons/products/service-catalog.svg'
import eventGateway from '@/icons/products/event-gateway.svg'

const productIcons = {
  'advanced-analytics': advancedAnalytics,
  'ai-gateway': AIGateway,
  'event-gateway': eventGateway,
  'api-ops': APIOps,
  'dev-portal': devPortal,
  'gateway': gateway,
  'insomnia': insomnia,
  'org-management': orgManagement,
  'service-catalog': serviceCatalog,
  operator,
  kic,
  mesh
}

export default {
  name: 'Icon',
  props: {
      name: { type: String, required: true },
      customClass: { type: String, default: ''},
      background: { type: Boolean, default: true }
  },
  computed: {
      iconComponent() {
        return productIcons[this.name] || null
      },
      bordered() {
        return ['operator', 'kic'].includes(this.name);
      }
  },
}
</script>
