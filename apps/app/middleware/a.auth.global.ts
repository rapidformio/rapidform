import { UserProfile } from "~~/composables/user"
import { AuthSession, setAuthSession, updateAuthSession, useAuthSession } from "~~/composables/auth"

function getAccessSession(): Partial<AuthSession> {
  const cookieAccessToken = useCookie('rapidform-access-token').value
  const authSessionAccessToken = useAuthSession().value.access_token

  const cookieRefreshToken = useCookie('rapidform-refresh-token').value
  const authSessionRefreshToken = useAuthSession().value.refresh_token

  if (!authSessionAccessToken && !authSessionRefreshToken) {
    // set auth session access token
    updateAuthSession({
      access_token: cookieAccessToken,
      refresh_token: cookieRefreshToken
    })
  }

  return {
    access_token: authSessionAccessToken || cookieAccessToken || '',
    refresh_token: authSessionRefreshToken || cookieRefreshToken || ''
  }
}

async function getUserProfile(accessToken: string): Promise<UserProfile> {
  const config = useRuntimeConfig().public

  try {
    const user: UserProfile = await $fetch(`${config.NUXT_PUBLIC_AUTH_URL}/user`, {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    })

    return user
  } catch (err) {
    if (Number(err?.data?.error?.code) !== 401) {
      console.error('unable to get user profile', err)
    }

    throw err
  }
}

async function refreshToken(at: string, rt: string): Promise<void> {
  const config = useRuntimeConfig().public

  try {
    const authSession: AuthSession = await $fetch(`${config.NUXT_PUBLIC_AUTH_URL}/token?grant_type=refresh_token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${at}`
      },
      body: {
        refresh_token: rt
      }
    })

    updateAuthSession({
      ...authSession,
      expires_at: Date.now() + authSession.expires_in * 1000
    })
  } catch (err: unknown) {
    console.error('unable to refresh token', err)
  }
}

const WHITELISTED_ROUTES = [
  '/signup',
]

export default defineNuxtRouteMiddleware(async (to, from) => {
  // whitelist access to form submission
  if (to.path.startsWith('/v/')) {
    return
  }

  try {
    const { access_token, refresh_token } = getAccessSession()

    // verify session
    const user: UserProfile = await getUserProfile(access_token)

    // white list some routes
    if (WHITELISTED_ROUTES.includes(to.path) && !user.id) {
      return
    }

    if (user?.id) {
      // user authorized - set user information
      setUser(user)

      // check if token is going to be expired in the next
      // 10 minutes, and refresh it if it
      const expiresAt = useAuthSession().value.expires_at
      if (expiresAt && expiresAt - Date.now() < 10 * 60 * 1000) {
        refreshToken(access_token, refresh_token)
      }

      if (to.path === '/login') {
        return navigateTo('/')
      }

      return
    } else {
      // unauthorized user - revoke all information
      useCookie('rapidform-access-token').value = ''
      useCookie('rapidform-refresh-token').value = ''
      setUser({})
      setAuthSession({})

      // navigate to /login unless loop
      if (to.path !== '/login') {
        return navigateTo('/login')
      }
    }
  } catch (err) {
    // navigate to /login unless loop
    if (to.path !== '/login') {
      return navigateTo('/login')
    }
  }

  return
})
