<template>
  <div
    v-if="pictogram"
    class="font-extrabold text-pink-600"
  >
    R
  </div>

  <div
    v-else
    class="font-extrabold text-pink-600"
  >
    Rapidform
  </div>
</template>

<script lang="ts" setup>
const props = defineProps({
  pictogram: {
    type: Boolean,
    default: false,
  },
})
</script>
