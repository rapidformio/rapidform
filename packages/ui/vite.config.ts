import * as path from "path"
import { defineConfig } from "vite"
import vue from "@vitejs/plugin-vue"

const resolvePath = (str: string) => path.resolve(__dirname, str)

export default defineConfig({
  plugins: [vue()],
  build: {
    lib: {
      entry: resolvePath("./src/index.ts"),
      name: "RapidformUi",
      fileName: (format) => `rapidform-ui.${format}.js`,
    },
    rollupOptions: {
      external: ["vue"],
      output: {
        globals: {
          vue: "Vue",
        },
      },
    },
  },
})
