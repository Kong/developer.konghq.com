<template>
    <div class="product-icon" :class="[name, { 'product-icon--background': background, 'product-icon--bordered': bordered }]" :style="{ 'background-color': background && `rgb(var(--color-${name}-background))` }">
        <component :is="iconComponent" v-if="iconComponent" :class="customClass" />
    </div>
</template>

<script>
import observability from '@/icons/products/observability.svg'
import AIGateway from '@/icons/products/ai-gateway.svg'
import devPortal from '@/icons/products/dev-portal.svg'
import gateway from '@/icons/products/gateway.svg'
import insomnia from '@/icons/products/insomnia.svg'
import operator from '@/icons/products/operator.svg'
import kic from '@/icons/products/kic.svg'
import mesh from '@/icons/products/mesh.svg'
import catalog from '@/icons/products/catalog.svg'
import eventGateway from '@/icons/products/event-gateway.svg'
import konnect from '@/icons/products/konnect.svg'
import referencePlatform from '@/icons/products/konnect-reference-platform.svg'
import meteringBilling from '@/icons/products/metering-and-billing.svg'

const productIcons = {
  'observability': observability,
  'ai-gateway': AIGateway,
  'event-gateway': eventGateway,
  'dev-portal': devPortal,
  'gateway': gateway,
  'insomnia': insomnia,
  'catalog': catalog,
  'konnect': konnect,
  'konnect-reference-platform': referencePlatform,
  'metering-and-billing': meteringBilling,
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
