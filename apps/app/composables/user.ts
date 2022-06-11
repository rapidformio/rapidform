// define the user profile structure
export interface UserProfile {
  id?: string;
  aud?: string;
  role?: string;
  email?: string;
  email_confirmed_at?: string;
  phone?: string;
  confirmed_at?: string;
  last_sign_in_at?: string;
  app_metadata?: UserProfileAppMetadata;
  user_metadata?: UserProfileUserMetadata;
  identities?: UserProfileIdentity[];
  created_at?: string;
  updated_at?: string;
}

export interface UserProfileAppMetadata {
  provider: string;
  providers: string[];
}

export interface UserProfileUserMetadata {
  avatar_url: string;
  email: string;
  email_verified: boolean;
  full_name: string;
  iss: string;
  name: string;
  preferred_username: string;
  provider_id: string;
  sub: string;
  user_name: string;
}

export interface UserProfileIdentity {
  id: string;
  user_id: string;
  identity_data: UserProfileUserMetadata;
  provider: string;
  last_sign_in_at: string;
  created_at: string;
  updated_at: string;
}

export const useUser = () => useState<UserProfile>('user', () => ({}))

// export setter for the user
export const setUser = (newUser: UserProfile) => {
  const user = useUser()
  user.value = newUser
}

export const updateUser = (userAttributed: Partial<UserProfile>) => {
  const user = useUser()

  user.value = {
    ...user.value,
    ...userAttributed
  }
}

export const removeUser = () => {
  const user = useUser()
  user.value = {}
}
