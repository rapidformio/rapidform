export interface AuthSession {
  access_token?: string;
  expires_in?: number;
  expires_at?: number;
  provider_token?: string;
  refresh_token?: string;
  token_type?: string;
}

export const useAuthSession = () => useState<AuthSession>('authSession', () => ({}))

export const setAuthSession = (newAuthSession: AuthSession) => {
  const authSession = useAuthSession()
  authSession.value = newAuthSession
}

export const updateAuthSession = (authSessionAttributed: Partial<AuthSession>) => {
  const authSession = useAuthSession()
  authSession.value = {
    ...authSession.value,
    ...authSessionAttributed
  }
}

export const removeAuthSession = () => {
  const authSession = useAuthSession()
  authSession.value = {}
}

export interface Settings {
  disable_signup: boolean;
  mailer_autoconfirm: boolean;
  phone_autoconfirm: boolean;
  sms_provider: string;
  external_labels: {
    [key: string]: string;
  };
  external: {
    email: boolean,
    phone: boolean,
    [key: string]: boolean;
  };
};

export const useAuthSettings = () => useState<Settings>('authSettings', () => ({
  disable_signup: false,
  mailer_autoconfirm: false,
  phone_autoconfirm: false,
  sms_provider: '',
  external_labels: {},
  external: {
    email: false,
    phone: false,
  }
}))

export const setAuthSettings = (newAuthSettings: Settings) => {
  const authSettings = useAuthSettings()
  authSettings.value = newAuthSettings
}

export const getAccessSession = (): Partial<AuthSession> => {
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

