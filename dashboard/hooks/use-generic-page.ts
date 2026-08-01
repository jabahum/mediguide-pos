"use client"

import { useQuery, useQueryClient } from "@tanstack/react-query"
import { GenericPagesService } from "@/services/generic-pages.service"
import type { TypedGenericPagesResponse } from "@/types/generic-pages"

export const genericPageQueryKey = (pageKey: string) =>
  ["generic-page", pageKey] as const

export function useGenericPage(pageKey: string) {
  const queryClient = useQueryClient()

  const query = useQuery<TypedGenericPagesResponse | null>({
    queryKey: genericPageQueryKey(pageKey),
    queryFn: () => GenericPagesService.getPageByKey(pageKey),
  })

  return {
    page: query.data ?? null,
    loading: query.isPending,
    error: query.error,
    refresh: () =>
      queryClient.invalidateQueries({ queryKey: genericPageQueryKey(pageKey) }),
  }
}
