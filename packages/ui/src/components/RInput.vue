<template>
  <label class="block text-left">
    <span
      :class="{
        'after:content-[`*`] after:ml-0.5 after:text-pink-600': required,
        'block text-sm font-medium text-slate-600': true,
      }"
    >
      {{ label }}
    </span>

    <input
      :type="type"
      :name="name"
      :placeholder="placeholder"
      :value="value"
      class="mt-1.5 px-4 h-12 bg-white ring-1 ring-slate-300 hover:ring-slate-400 focus:ring-pink-600 focus:outline-none shadow-sm rounded-lg placeholder-slate-400 block w-full"
      @input="$emit('update:modelValue', ($event.target as any).value)"
    />
  </label>
</template>

<script lang="ts" setup>
import { computed } from "vue"

const props = defineProps({
  modelValue: {
    type: String,
    default: "",
  },
  label: {
    type: String,
    default: "",
  },
  name: {
    type: String,
    default: "",
  },
  type: {
    type: String,
    default: "text",
  },
  placeholder: {
    type: String,
    default: "",
  },
  required: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(["update:modelValue"])

const value = computed({
  get() {
    return props.modelValue
  },
  set(value) {
    emit("update:modelValue", value)
  },
})
</script>
