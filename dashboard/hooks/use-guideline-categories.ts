"use client"

import { useState, useEffect, useMemo, useCallback } from "react"
import { getBackendClient } from "@/lib/backend-client"
import type { GuidelineCategoriesResponse } from "@/types/backend-types"

export interface CategoryTreeNode extends GuidelineCategoriesResponse {
  children: CategoryTreeNode[]
  level: number
  path: string[]
}

interface UseGuidelineCategoriesOptions {
  includeInactive?: boolean
  parentId?: string | null
  searchTerm?: string
}

export function useGuidelineCategories(options: UseGuidelineCategoriesOptions = {}) {
  const { includeInactive = false, parentId, searchTerm } = options
  
  const [categories, setCategories] = useState<GuidelineCategoriesResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Fetch categories from the backend compatibility API.
  const fetchCategories = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)

      let filter = ""
      const filterParts: string[] = []

      // Status filter
      if (!includeInactive) {
        filterParts.push('status = "active"')
      }

      // Parent filter
      if (parentId !== undefined) {
        if (parentId === null) {
          filterParts.push('parent_category = ""')
        } else {
          filterParts.push(`parent_category = "${parentId}"`)
        }
      }

      // Search filter
      if (searchTerm) {
        filterParts.push(`(name ~ "${searchTerm}" || description ~ "${searchTerm}")`)
      }

      if (filterParts.length > 0) {
        filter = filterParts.join(" && ")
      }

      const backend = getBackendClient()
      const records = await backend.resource("guideline_categories").getFullList<GuidelineCategoriesResponse>({
        sort: "parent_category,sort_order,name",
        filter,
        expand: "parent_category"
      })

      setCategories(records)
    } catch (err) {
      console.error("Failed to fetch guideline categories:", err)
      setError(err instanceof Error ? err.message : "Failed to fetch categories")
    } finally {
      setLoading(false)
    }
  }, [includeInactive, parentId, searchTerm])

  useEffect(() => {
    fetchCategories()
  }, [fetchCategories])

  // Build hierarchical tree structure
  const categoryTree = useMemo((): CategoryTreeNode[] => {
    const categoryMap = new Map<string, CategoryTreeNode>()
    const rootCategories: CategoryTreeNode[] = []

    // First pass: create nodes
    categories.forEach(category => {
      const node: CategoryTreeNode = {
        ...category,
        children: [],
        level: 0,
        path: []
      }
      categoryMap.set(category.id, node)
    })

    // Second pass: build hierarchy and calculate levels/paths
    categories.forEach(category => {
      const node = categoryMap.get(category.id)!
      
      if (category.parent_category) {
        const parent = categoryMap.get(category.parent_category)
        if (parent) {
          parent.children.push(node)
          node.level = parent.level + 1
          node.path = [...parent.path, parent.id]
        } else {
          // Parent not found in current dataset, treat as root
          rootCategories.push(node)
        }
      } else {
        rootCategories.push(node)
      }
    })

    // Sort children recursively
    const sortChildren = (nodes: CategoryTreeNode[]) => {
      nodes.sort((a, b) => {
        if (a.sort_order !== b.sort_order) {
          return (a.sort_order || 0) - (b.sort_order || 0)
        }
        return a.name.localeCompare(b.name)
      })
      nodes.forEach(node => sortChildren(node.children))
    }

    sortChildren(rootCategories)
    return rootCategories
  }, [categories])

  // Flatten tree for simple list operations
  const flatCategories = useMemo((): CategoryTreeNode[] => {
    const flatten = (nodes: CategoryTreeNode[]): CategoryTreeNode[] => {
      const result: CategoryTreeNode[] = []
      nodes.forEach(node => {
        result.push(node)
        result.push(...flatten(node.children))
      })
      return result
    }
    return flatten(categoryTree)
  }, [categoryTree])

  // Get category by ID
  const getCategoryById = useCallback((id: string): CategoryTreeNode | undefined => {
    return flatCategories.find(cat => cat.id === id)
  }, [flatCategories])

  // Get category path (breadcrumbs)
  const getCategoryPath = useCallback((categoryId: string): CategoryTreeNode[] => {
    const category = getCategoryById(categoryId)
    if (!category) return []

    const path: CategoryTreeNode[] = []
    category.path.forEach(pathId => {
      const pathCategory = getCategoryById(pathId)
      if (pathCategory) path.push(pathCategory)
    })
    path.push(category)
    return path
  }, [getCategoryById])

  // Get subcategories of a category
  const getSubcategories = useCallback((parentId: string): CategoryTreeNode[] => {
    const parent = getCategoryById(parentId)
    return parent?.children || []
  }, [getCategoryById])

  // Get root categories (no parent)
  const getRootCategories = useCallback((): CategoryTreeNode[] => {
    return categoryTree
  }, [categoryTree])

  // Filter categories by criteria
  const filterCategories = useCallback((
    predicate: (category: CategoryTreeNode) => boolean
  ): CategoryTreeNode[] => {
    return flatCategories.filter(predicate)
  }, [flatCategories])

  // Check if category has children
  const hasChildren = useCallback((categoryId: string): boolean => {
    const category = getCategoryById(categoryId)
    return (category?.children.length || 0) > 0
  }, [getCategoryById])

  // Get category options for select components
  const getCategoryOptions = useCallback((excludeIds: string[] = []): Array<{
    value: string
    label: string
    level: number
    disabled?: boolean
  }> => {
    const options = flatCategories
      .filter(cat => !excludeIds.includes(cat.id))
      .map(cat => ({
        value: cat.id,
        label: "  ".repeat(cat.level) + cat.name,
        level: cat.level,
        disabled: false
      }))

    return options
  }, [flatCategories])

  // Get categories excluding descendants (for parent selection)
  const getCategoriesExcludingDescendants = useCallback((excludeId: string): CategoryTreeNode[] => {
    const isDescendant = (category: CategoryTreeNode, ancestorId: string): boolean => {
      if (category.id === ancestorId) return true
      return category.path.includes(ancestorId)
    }

    return flatCategories.filter(cat => !isDescendant(cat, excludeId))
  }, [flatCategories])

  return {
    // Data
    categories: flatCategories,
    categoryTree,
    loading,
    error,

    // Actions
    refetch: fetchCategories,

    // Helpers
    getCategoryById,
    getCategoryPath,
    getSubcategories,
    getRootCategories,
    filterCategories,
    hasChildren,
    getCategoryOptions,
    getCategoriesExcludingDescendants,

    // Computed
    isEmpty: categories.length === 0 && !loading,
    totalCount: categories.length
  }
}

// Search-specific hook for debounced searching
export function useGuidelineCategoriesSearch() {
  const [searchTerm, setSearchTerm] = useState("")
  const [debouncedSearchTerm, setDebouncedSearchTerm] = useState("")

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearchTerm(searchTerm)
    }, 300)

    return () => clearTimeout(timer)
  }, [searchTerm])

  const result = useGuidelineCategories({ 
    searchTerm: debouncedSearchTerm,
    includeInactive: false
  })

  return {
    ...result,
    searchTerm,
    setSearchTerm,
    isSearching: searchTerm !== debouncedSearchTerm
  }
}
