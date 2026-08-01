"use client"

import * as React from "react"
import { GuidelineIndexResponse } from "@/types/backend-types"
import { guidelineIndexService } from "@/services/guideline-content.service"

export type GuidelineIndexItem = GuidelineIndexResponse

export interface UseGuidelineIndexSearchOptions {
  /**
   * Filter to exclude specific items by ID
   */
  excludeIds?: string[]
  
  /**
   * Filter to exclude items at or above a certain level (for preventing circular references)
   */
  maxLevel?: number
  
  /**
   * Initial search term
   */
  initialSearchTerm?: string
  
  /**
   * Debounce delay in milliseconds (default: 300)
   */
  debounceMs?: number
  
  /**
   * Maximum number of results to fetch (default: 50)
   */
  maxResults?: number
  
  /**
   * Additional compatibility-API filter to apply
   */
  additionalFilter?: string
}

export interface UseGuidelineIndexSearchResult {
  /**
   * Current search term
   */
  searchTerm: string
  
  /**
   * Update the search term
   */
  setSearchTerm: (term: string) => void
  
  /**
   * Search results
   */
  results: GuidelineIndexItem[]
  
  /**
   * Whether search is in progress
   */
  isSearching: boolean
  
  /**
   * Search error, if any
   */
  error: string | null
  
  /**
   * Clear search results and term
   */
  clearSearch: () => void
  
  /**
   * Manually trigger search with current term
   */
  triggerSearch: () => void
}

/**
 * Custom hook for searching guideline index items with server-side search
 * 
 * @param options Configuration options for the search
 * @returns Search state and methods
 * 
 * @example
 * ```typescript
 * const { searchTerm, setSearchTerm, results, isSearching } = useGuidelineIndexSearch({
 *   excludeIds: ['current-item-id'],
 *   maxLevel: 2,
 *   debounceMs: 300
 * })
 * ```
 */
export function useGuidelineIndexSearch(
  options: UseGuidelineIndexSearchOptions = {}
): UseGuidelineIndexSearchResult {
  const {
    excludeIds = [],
    maxLevel,
    initialSearchTerm = "",
    debounceMs = 300,
    maxResults = 50,
    additionalFilter
  } = options

  const [searchTerm, setSearchTerm] = React.useState(initialSearchTerm)
  const [results, setResults] = React.useState<GuidelineIndexItem[]>([])
  const [isSearching, setIsSearching] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)

  // Stabilize the dependencies to prevent infinite loops
  const stableExcludeIds = React.useMemo(() => excludeIds.join(','), [excludeIds])
  const stableMaxLevel = maxLevel
  const stableMaxResults = maxResults
  const stableAdditionalFilter = additionalFilter

  // Memoize the search function to prevent unnecessary recreations
  const searchItems = React.useCallback(async (term: string) => {
    const trimmedTerm = term.trim()
    if (!trimmedTerm) {
      setResults([])
      setError(null)
      return
    }

    setIsSearching(true)
    setError(null)

    try {
      const excludeIdsArray = stableExcludeIds ? stableExcludeIds.split(',').filter(Boolean) : []
      const records = await guidelineIndexService.all({ search: trimmedTerm, per_page: stableMaxResults })
      setResults(records.filter(item => !excludeIdsArray.includes(item.id) && (typeof stableMaxLevel !== "number" || (item.level || 0) < stableMaxLevel)))
    } catch (err) {
      console.error("Failed to search guideline index items:", err)
      setError("Failed to search items")
      setResults([])
    } finally {
      setIsSearching(false)
    }
  }, [stableExcludeIds, stableMaxLevel, stableMaxResults, stableAdditionalFilter])

  // Debounced search effect
  React.useEffect(() => {
    const timer = setTimeout(() => {
      searchItems(searchTerm)
    }, debounceMs)

    return () => clearTimeout(timer)
  }, [searchTerm, debounceMs, searchItems])

  const clearSearch = React.useCallback(() => {
    setSearchTerm("")
    setResults([])
    setError(null)
  }, [])

  const triggerSearch = React.useCallback(() => {
    searchItems(searchTerm)
  }, [searchItems, searchTerm])

  return {
    searchTerm,
    setSearchTerm,
    results,
    isSearching,
    error,
    clearSearch,
    triggerSearch
  }
}
