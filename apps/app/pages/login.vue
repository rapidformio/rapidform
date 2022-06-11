<template>
  <main class="h-screen relative z-10 flex-auto flex items-center justify-center text-sm text-center text-gray-600 py-16 px-4 sm:px-6 lg:px-8">
    <div class="w-full max-w-md flex flex-col items-center">
      <r-logo class="text-4xl" />

      <p class="my-6 text-lg text-slate-600 text-center max-w-4xl mx-auto">
        Build strong relationship with your audience one <span class="font-mono font-medium text-pink-600">question</span> at a time.
      </p>

      <div class="mt-4 w-full flex flex-col">
        <span v-if="authSettings.external.email">
          <div>
            <r-form
              class="flex flex-col space-y-4"
              @submit.prevent="handleSubmit"
            >
              <r-input
                v-model="email"
                label="Email"
                type="email"
                name="email"
                placeholder="name@acme.com"
              />

              <r-input
                v-model="password"
                label="Password"
                type="password"
                name="password"
                placeholder="Password"
              />

              <r-button
                secondary
                flat
                :full="false"
                to="/recover"
                class="text-left"
              >
                Forgot password?
              </r-button>

              <div class="h-4" />

              <r-button
                type="submit"
                :loading="loading"
              >
                Login
              </r-button>
            </r-form>

            <r-button
              secondary
              flat
              :full="false"
              to="signup"
              class="mt-3"
            >
              Don't have an account yet? <span class="text-pink-600">Register for free</span>
            </r-button>

            <div
              v-show="formError.length"
              class="text-red-600 font-semibold mt-8"
            >
              {{ formError }} 😢
            </div>
          </div>

          <div
            v-if="activeProviders.length"
            class="my-6 border-b border-slate-300/30 mx-20"
          />
        </span>

        <div
          v-if="authSettings.external.email && activeProviders.length"
          class="mb-2"
        >
          or continue with
        </div>

        <div class="flex space-x-4 items-center justify-center">
          <div
            v-for="provider in activeProviders"
            :key="provider"
          >
            <r-button
              flat
              :to="`${config.NUXT_PUBLIC_AUTH_URL}/authorize?provider=${provider}`"
            >
              <div class="p-3 flex items-center justify-center border border-pink-300 rounded-lg hover:bg-pink-50">
                <r-icon :name="provider" />
              </div>
            </r-button>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>

<script lang="ts" setup>
import { ref, computed } from "vue"
import { Settings, AuthSession } from "~~/composables/auth"
import { UserProfile } from "~~/composables/user"
import { RLogo, RForm, RInput, RButton, RIcon } from "ui"

definePageMeta({
  title: 'Rapidform | Login',
  layout: 'empty'
})

interface SessionResponse extends AuthSession  {
  user: UserProfile
}

// get run time configs
const config = useRuntimeConfig().public

// get active auth providers
const authSettings: Settings = await loadAuthSettings()
const activeProviders = computed(() => {
  if (authSettings && authSettings.external) {
    return Object.keys(authSettings.external).filter(provider => authSettings.external[provider] && !['email'].includes(provider))
  }

  return []
})

// manage page state
const email = ref("")
const password = ref("")
const formError = ref("")
const loading = ref(false)

async function loadAuthSettings() {
  try {
    return await $fetch(`${config.NUXT_PUBLIC_AUTH_URL}/settings`)
  } catch (err: any) {
    return {
      external: {
        email: true
      }
    }
  }
}

// handle login form submittion
async function handleSubmit() {
  try {
    // set loading state
    loading.value = true

    const session: SessionResponse = await $fetch(`${config.NUXT_PUBLIC_AUTH_URL}/token?grant_type=password`, {
      method: "POST",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
      body: {
        email: email.value,
        password: password.value,
      },
    })

    setAuthSession({
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      expires_in: session.expires_in,
      expires_at: Date.now() + session.expires_in * 10 * 60,
      token_type: session.token_type,
    })

    setUser(session.user)

    // redirect to home page
    navigateTo('/')
  } catch (error) {
    loading.value = false
    formError.value = error?.data?.error_description || 'Unknown error. Please contact support at support@rapidform.io'
    console.error(error)
  }
}
</script>

