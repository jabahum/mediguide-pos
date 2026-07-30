"use client"

import { useState, useCallback } from "react"
import { useQueryClient } from "@tanstack/react-query"
import { getBackendClient } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"
import { backendRecordKeyPrefix } from "@/hooks/use-backend-record"

interface UseBackendCrudOptions {
  collectionName: string
  onSuccess?: () => void
  onError?: (error: any) => void
}

export function useBackendCrud({
  collectionName,
  onSuccess,
  onError
}: UseBackendCrudOptions) {
  const [loading, setLoading] = useState(false)
  const backendClient = getBackendClient()
  const queryClient = useQueryClient()

  const invalidateList = useCallback(() => {
    return queryClient.invalidateQueries({ queryKey: ["backend", collectionName] })
  }, [queryClient, collectionName])

  const invalidateRecord = useCallback(
    (id: string) =>
      queryClient.invalidateQueries({ queryKey: backendRecordKeyPrefix(collectionName, id) }),
    [queryClient, collectionName]
  )

  const create = useCallback(async (data: any) => {
    setLoading(true)
    try {
      const record = await backendClient.resource(collectionName).create(data)
      await invalidateList()
      showToast.success("Success", "Record created successfully")
      onSuccess?.()
      return record
    } catch (error: any) {
      console.error(`Failed to create ${collectionName}:`, error)
      showToast.error("Error", error?.message || "Failed to create record")
      onError?.(error)
      throw error
    } finally {
      setLoading(false)
    }
  }, [backendClient, collectionName, onSuccess, onError, invalidateList])

  const update = useCallback(async (id: string, data: any) => {
    setLoading(true)
    try {
      const record = await backendClient.resource(collectionName).update(id, data)
      await Promise.all([invalidateRecord(id), invalidateList()])
      showToast.success("Success", "Record updated successfully")
      onSuccess?.()
      return record
    } catch (error: any) {
      console.error(`Failed to update ${collectionName}:`, error)
      showToast.error("Error", error?.message || "Failed to update record")
      onError?.(error)
      throw error
    } finally {
      setLoading(false)
    }
  }, [backendClient, collectionName, onSuccess, onError, invalidateRecord, invalidateList])

  const deleteRecord = useCallback(async (id: string) => {
    setLoading(true)
    try {
      await backendClient.resource(collectionName).delete(id)
      await Promise.all([invalidateRecord(id), invalidateList()])
      showToast.success("Success", "Record deleted successfully")
      onSuccess?.()
      return true
    } catch (error: any) {
      console.error(`Failed to delete ${collectionName}:`, error)
      showToast.error("Error", error?.message || "Failed to delete record")
      onError?.(error)
      throw error
    } finally {
      setLoading(false)
    }
  }, [backendClient, collectionName, onSuccess, onError, invalidateRecord, invalidateList])

  const getOne = useCallback(async (id: string, options?: any) => {
    setLoading(true)
    try {
      const record = await backendClient.resource(collectionName).getOne(id, options)
      return record
    } catch (error: any) {
      console.error(`Failed to get ${collectionName}:`, error)
      showToast.error("Error", error?.message || "Failed to fetch record")
      onError?.(error)
      throw error
    } finally {
      setLoading(false)
    }
  }, [backendClient, collectionName, onError])

  const getList = useCallback(async (page = 1, perPage = 50, options?: any) => {
    setLoading(true)
    try {
      const records = await backendClient.resource(collectionName).getList(page, perPage, options)
      return records
    } catch (error: any) {
      console.error(`Failed to list ${collectionName}:`, error)
      onError?.(error)
      throw error
    } finally {
      setLoading(false)
    }
  }, [backendClient, collectionName, onError])

  return {
    create,
    update,
    deleteRecord,
    getOne,
    getList,
    loading
  }
}
