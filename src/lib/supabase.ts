const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

export const supabaseConfigured = Boolean(url && anonKey)

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  if (!url || !anonKey) throw new Error('Chưa cấu hình Supabase trong file .env')
  const response = await fetch(`${url}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${anonKey}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
      ...(init.headers || {}),
    },
  })
  if (!response.ok) throw new Error(await response.text())
  const text = await response.text()
  return (text ? JSON.parse(text) : null) as T
}

export async function rpc<T>(name: string, body: Record<string, unknown>): Promise<T> {
  return request<T>(`rpc/${name}`, { method: 'POST', body: JSON.stringify(body) })
}

export async function getProducts<T>(): Promise<T> {
  return request<T>('products?select=*&is_active=eq.true&order=group_name.asc,name.asc')
}
