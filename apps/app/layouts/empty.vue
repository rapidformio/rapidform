<template>
  <div>
    <div class="absolute z-20 top-0 inset-x-0 flex justify-center overflow-hidden pointer-events-none">
      <div class="w-[108rem] flex-none flex justify-end">
        <picture>
          <source
            srcset="../assets/media/docs.avif"
            type="image/avif"
          >
          <img
            src="../assets/media/docs@tinypng.png"
            alt=""
            class="w-[71.75rem] flex-none max-w-none"
          >
        </picture>
      </div>
    </div>

    <slot />
  </div>
</template>
