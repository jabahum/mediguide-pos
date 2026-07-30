"use client"

import { useEffect, useMemo } from "react"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { getBackendClient } from "@/lib/backend-client"
import { GenericPagesService } from "@/services/generic-pages.service"
import type { TypedGenericPagesResponse } from "@/types/generic-pages"

export const genericPageQueryKey = (pageKey: string) =>
  ["generic-page", pageKey] as const

export function useGenericPage(pageKey: string) {
  const backend = useMemo(() => getBackendClient(), [])
  const queryClient = useQueryClient()

  const query = useQuery<TypedGenericPagesResponse | null>({
    queryKey: genericPageQueryKey(pageKey),
    queryFn: () => GenericPagesService.getPageByKey(pageKey),
  })

  const pageId = query.data?.id

  useEffect(() => {
    if (!pageId) return

    let cancelled = false
    const subscribePromise = backend
      .resource("generic_pages")
      .subscribe(pageId, (e) => {
        if (cancelled) return
        const queryKey = genericPageQueryKey(pageKey)
        if (e.action === "delete") {
          queryClient.setQueryData(queryKey, null)
        } else {
          queryClient.setQueryData(
            queryKey,
            e.record as unknown as TypedGenericPagesResponse
          )
        }
      })

    return () => {
      cancelled = true
      subscribePromise
        .then((unsub) => unsub?.())
        .catch(() => {})
    }
  }, [pageId, pageKey, backend, queryClient])

  return {
    page: query.data ?? null,
    loading: query.isPending,
    error: query.error,
    refresh: () =>
      queryClient.invalidateQueries({ queryKey: genericPageQueryKey(pageKey) }),
  }
}
