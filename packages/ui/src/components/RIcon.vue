<template>
  <img :src="path">
</template>

<script lang="ts" setup>
import { computed } from "vue"

const props = defineProps({
  name: {
    type: String,
    default: "",
  },
})

const path = computed(() => {
  switch(props.name) {
    case "google":
      return "assets/media/icons/google.svg"
    default:
      // raw data
      return props.name
  }
})
</script>
