<template>
    <div class="product-icon" :class="[name, { 'product-icon--background': background, 'product-icon--bordered': bordered }]" :style="{ 'background-color': background && `rgb(var(--color-${name}-background))` }">
        <component :is="iconComponent" v-if="iconComponent" :class="customClass" />
    </div>
</template>

<script>
import advancedAnalytics from '@/icons/products/advanced-analytics.svg'
import AIGateway from '@/icons/products/ai-gateway.svg'
import devPortal from '@/icons/products/dev-portal.svg'
import gateway from '@/icons/products/gateway.svg'
import insomnia from '@/icons/products/insomnia.svg'
import operator from '@/icons/products/operator.svg'
import kic from '@/icons/products/kic.svg'
import mesh from '@/icons/products/mesh.svg'
import serviceCatalog from '@/icons/products/service-catalog.svg'
import eventGateway from '@/icons/products/event-gateway.svg'
import konnectPlatform from '@/icons/products/konnect-platform.svg'
import referencePlatform from '@/icons/products/reference-platform.svg'

const productIcons = {
  'advanced-analytics': advancedAnalytics,
  'ai-gateway': AIGateway,
  'event-gateway': eventGateway,
  'dev-portal': devPortal,
  'gateway': gateway,
  'insomnia': insomnia,
  'service-catalog': serviceCatalog,
  'konnect-platform': konnectPlatform,
  'reference-platform': referencePlatform,
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
