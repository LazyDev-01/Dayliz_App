/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_ANON_KEY: string
  readonly VITE_FASTAPI_BASE_URL: string
  readonly VITE_FASTAPI_TOKEN: string
  readonly VITE_BACKEND_TYPE: string
  readonly VITE_ENABLE_REALTIME: string
  readonly VITE_ENABLE_OFFLINE: string
  readonly VITE_ENABLE_ANALYTICS: string
  readonly VITE_ENABLE_NOTIFICATIONS: string
  readonly VITE_DEV_MODE: string
  readonly VITE_LOG_LEVEL: string
  readonly VITE_PWA_ENABLED: string
  readonly VITE_PWA_OFFLINE_SUPPORT: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
