import dotenv from "dotenv"
import { defineNuxtConfig } from "nuxt"

dotenv.config({ path: "../../.env" })

if (process.env.VERCEL_URL && !process.env.NUXT_PUBLIC_WEBAPP_URL) {
  process.env.NUXT_PUBLIC_WEBAPP_URL = "https://" + process.env.VERCEL_URL;
}

if (process.env.NUXT_PUBLIC_WEBAPP_URL) {
  process.env.NUXTAUTH_URL = process.env.NUXT_PUBLIC_WEBAPP_URL + "/api/auth";
}

if (!process.env.NUXT_PUBLIC_WEBSITE_URL) {
  process.env.NUXT_PUBLIC_WEBSITE_URL = process.env.NUXT_PUBLIC_WEBAPP_URL;
}


export default defineNuxtConfig({

})
