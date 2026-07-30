"use client"

import { useEffect, useMemo } from "react"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { getBackendClient } from "@/lib/backend-client"

export const backendRecordQueryKey = (
  collection: string,
  id: string,
  expand?: string,
  fields?: string
) => ["backend-record", collection, id, expand ?? "", fields ?? ""] as const

// Prefix key for invalidating any variant of a record (any expand/fields).
export const backendRecordKeyPrefix = (collection: string, id: string) =>
  ["backend-record", collection, id] as const

export interface UseBackendRecordOptions {
  expand?: string
  fields?: string
  enabled?: boolean
}

export function useBackendRecord<T = unknown>(
  collection: string,
  id: string | undefined | null,
  options: UseBackendRecordOptions = {}
) {
  const { expand, fields, enabled = true } = options
  const backendClient = useMemo(() => getBackendClient(), [])
  const queryClient = useQueryClient()
  const recordId = id ?? ""

  const fetchOptions = useMemo(() => {
    const opts: Record<string, string> = {}
    if (expand) opts.expand = expand
    if (fields) opts.fields = fields
    return Object.keys(opts).length > 0 ? opts : undefined
  }, [expand, fields])

  const query = useQuery<T | null>({
    queryKey: backendRecordQueryKey(collection, recordId, expand, fields),
    queryFn: async () => {
      const record = await backendClient
        .collection(collection)
        .getOne(recordId, fetchOptions)
      return record as unknown as T
    },
    enabled: enabled && Boolean(recordId),
  })

  useEffect(() => {
    if (!enabled || !recordId) return

    let cancelled = false
    const queryKey = backendRecordQueryKey(collection, recordId, expand, fields)
    const subscribePromise = backendClient
      .collection(collection)
      .subscribe(
        recordId,
        (e) => {
          if (cancelled) return
          if (e.action === "delete") {
            queryClient.setQueryData(queryKey, null)
          } else {
            queryClient.setQueryData(queryKey, e.record as unknown as T)
          }
        },
        fetchOptions
      )

    return () => {
      cancelled = true
      subscribePromise
        .then((unsub) => unsub?.())
        .catch(() => {})
    }
  }, [collection, recordId, expand, fields, fetchOptions, enabled, backendClient, queryClient])

  return {
    record: query.data ?? null,
    loading: query.isPending,
    error: query.error,
    refresh: () =>
      queryClient.invalidateQueries({
        queryKey: backendRecordQueryKey(collection, recordId, expand, fields),
      }),
  }
}
