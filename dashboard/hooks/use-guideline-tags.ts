"use client"

import { useState, useEffect, useMemo, useCallback } from "react"
import { getBackendClient } from "@/lib/backend-client"
import type { GuidelineTagsResponse } from "@/types/backend-types"

interface UseGuidelineTagsOptions {
  searchTerm?: string
}

export function useGuidelineTags(options: UseGuidelineTagsOptions = {}) {
  const { searchTerm } = options
  
  const [tags, setTags] = useState<GuidelineTagsResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Fetch tags from the backend compatibility API.
  const fetchTags = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)

      let filter = ""
      
      // Search filter
      if (searchTerm) {
        filter = `(name ~ "${searchTerm}" || description ~ "${searchTerm}")`
      }

      const backend = getBackendClient()
      const records = await backend.resource("guideline_tags").getFullList<GuidelineTagsResponse>({
        sort: "name",
        filter: filter || undefined
      })

      setTags(records)
    } catch (err) {
      console.error("Failed to fetch guideline tags:", err)
      setError(err instanceof Error ? err.message : "Failed to fetch tags")
    } finally {
      setLoading(false)
    }
  }, [searchTerm])

  useEffect(() => {
    fetchTags()
  }, [fetchTags])

  // Get tag by ID
  const getTagById = useCallback((id: string): GuidelineTagsResponse | undefined => {
    return tags.find(tag => tag.id === id)
  }, [tags])

  // Get tag options for select components
  const getTagOptions = useCallback((): Array<{
    value: string
    label: string
    description?: string
  }> => {
    return tags.map(tag => ({
      value: tag.id,
      label: tag.name,
      description: tag.description
    }))
  }, [tags])

  // Get options for MultiSelect component
  const getMultiSelectOptions = useCallback((): Array<{
    value: string
    label: string
  }> => {
    return tags.map(tag => ({
      value: tag.id,
      label: tag.name
    }))
  }, [tags])

  // Filter tags by criteria
  const filterTags = useCallback((
    predicate: (tag: GuidelineTagsResponse) => boolean
  ): GuidelineTagsResponse[] => {
    return tags.filter(predicate)
  }, [tags])

  // Get tags by IDs (useful for displaying selected tags)
  const getTagsByIds = useCallback((ids: string[]): GuidelineTagsResponse[] => {
    return tags.filter(tag => ids.includes(tag.id))
  }, [tags])

  return {
    // Data
    tags,
    loading,
    error,

    // Actions
    refetch: fetchTags,

    // Helpers
    getTagById,
    getTagOptions,
    getMultiSelectOptions,
    filterTags,
    getTagsByIds,

    // Computed
    isEmpty: tags.length === 0 && !loading,
    totalCount: tags.length
  }
}

// Search-specific hook for debounced searching
export function useGuidelineTagsSearch() {
  const [searchTerm, setSearchTerm] = useState("")
  const [debouncedSearchTerm, setDebouncedSearchTerm] = useState("")

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearchTerm(searchTerm)
    }, 300)

    return () => clearTimeout(timer)
  }, [searchTerm])

  const result = useGuidelineTags({ 
    searchTerm: debouncedSearchTerm
  })

  return {
    ...result,
    searchTerm,
    setSearchTerm,
    isSearching: searchTerm !== debouncedSearchTerm
  }
}
