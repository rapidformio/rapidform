<template>
  <div
    :class="{
      'w-full': full,
    }"
  >
    <component
      :is="componentType"
      :class="{
        'font-semibold w-full outline-none': true,
        'bg-slate-800 hover:bg-slate-700': secondary && !flat,
        'bg-pink-600 hover:bg-pink-700': !secondary && !flat,
        'px-3 py-1': slim,
        'h-12 px-6': !slim && !flat,
        'focus:outline-none focus:ring-1 focus:ring-slate-100 focus:ring-offset-2 focus:ring-offset-slate-100 text-white rounded-lg flex items-center justify-center': !flat,
        'text-pink-600 hover:text-pink-700': flat && !secondary,
        'text-slate-800 hover:text-slate-700': flat && secondary,
      }"
      :to="to"
      @click="$emit('click')"
      :type="type"
    >
      <svg v-show="loading" class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>

      <slot />
    </component>
  </div>
</template>

<script lang="ts" setup>
import { computed } from "vue"
// import { NuxtLink } from "~~/.nuxt/components"

const props = defineProps({
  loading: {
    type: Boolean,
    default: false,
  },
  flat: {
    type: Boolean,
    default: false,
  },
  slim: {
    type: Boolean,
    default: false,
  },
  type: {
    type: String,
    default: "button",
  },
  to: {
    type: String,
    default: "",
  },
  full: {
    type: Boolean,
    default: true,
  },
  secondary: {
    type: Boolean,
    default: false,
  },
})

const emits = defineEmits(["click"])

// returns the component type to render
const componentType = computed(() => {
  return props.to ? "NuxtLink" : "button"
})
</script>
