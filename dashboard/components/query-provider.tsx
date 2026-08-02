"use client"

import { QueryClient, QueryClientProvider, isServer } from "@tanstack/react-query"
import { BackendRequestError } from "@/lib/backend-client"

function shouldRetry(failureCount: number, error: unknown) {
  if (
    error instanceof BackendRequestError &&
    [401, 403, 429].includes(error.status)
  ) {
    return false
  }
  return failureCount < 2
}

function makeQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 60 * 1000,
        gcTime: 30 * 60 * 1000,
        retry: shouldRetry,
        refetchOnWindowFocus: false,
      },
      mutations: {
        retry: false,
      },
    },
  })
}

let browserQueryClient: QueryClient | undefined

function getQueryClient() {
  if (isServer) return makeQueryClient()
  if (!browserQueryClient) browserQueryClient = makeQueryClient()
  return browserQueryClient
}

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const queryClient = getQueryClient()
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
}
