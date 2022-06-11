import dotenv from "dotenv"
import { defineNuxtConfig } from "nuxt"

dotenv.config({ path: "../../.env" })

if (process.env.VERCEL_URL && !process.env.NUXT_PUBLIC_WEBAPP_URL) {
  process.env.NUXT_PUBLIC_WEBAPP_URL = "https://" + process.env.VERCEL_URL;
}

export default defineNuxtConfig({
  css: [
    '@/assets/css/tailwind.css',
    '@/assets/css/fonts.css',
  ],
  head: {
    title: 'Rapidform',
  },
  runtimeConfig: {
    public: {
      NUXT_PUBLIC_API_URL: process.env.NUXT_PUBLIC_API_URL || 'https://api.rapidform.io',
      NUXT_PUBLIC_AUTH_URL: process.env.NUXT_PUBLIC_AUTH_URL || 'https://auth.rapidform.io',
      NUXT_PUBLIC_DISABLE_TELEMETRY: process.env.NUXT_PUBLIC_DISABLE_TELEMETRY === '1',
    },
  },
  loading: {
    color: '#db2778',
    height: '2px',
  },
  build: {
    postcss: {
      postcssOptions: {
        plugins: {
          tailwindcss: {},
          autoprefixer: {},
        }
      }
    },
  },
})
