"use client"

import { useState, useCallback, useEffect, useMemo, useRef } from 'react'
import { keepPreviousData, useQuery, useQueryClient } from "@tanstack/react-query"
import { getBackendClient } from '@/lib/backend-client'
import { showToast } from '@/lib/toast'
import {
  BaseRecord,
  UseBackendTableConfig,
  UseBackendTableReturn,
  TableError,
  PaginationInfo,
  ExportFormat,
  AdvancedFilter
} from '@/types/data-table'

export function useBackendTable<TData extends BaseRecord = BaseRecord>(
  config: UseBackendTableConfig<TData>
): UseBackendTableReturn<TData> {
  // State management
  const [data, setData] = useState<TData[]>([])
  const [totalItems, setTotalItems] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)
  const [currentPageSize, setCurrentPageSize] = useState(config.ui?.pageSize || 20)
  const [selectedRows, setSelectedRows] = useState<TData[]>([])
  const [globalFilter, setGlobalFilter] = useState('')
  const [advancedFilters, setAdvancedFilters] = useState<AdvancedFilter[]>([])
  const [error, setError] = useState<TableError | null>(null)

  const [actionLoading, setActionLoading] = useState({
    export: false,
    import: false,
    bulkAction: false,
  })

  const backendClient = useMemo(() => getBackendClient(), [])
  const hasLoadedRef = useRef(false)
  const actionRef = useRef<'initial' | 'pagination' | 'table' | 'refresh'>('initial')
  const queryClient = useQueryClient()

  // Pagination info
  const paginationInfo: PaginationInfo = useMemo(() => ({
    page: currentPage,
    perPage: currentPageSize,
    totalItems,
    totalPages: Math.ceil(totalItems / currentPageSize),
    hasNextPage: currentPage < Math.ceil(totalItems / currentPageSize),
    hasPreviousPage: currentPage > 1
  }), [currentPage, currentPageSize, totalItems])

  // Convert advanced filters to the temporary compatibility query syntax.
  const convertAdvancedFilterCondition = useCallback((filter: AdvancedFilter) => {
    const { field, condition, value } = filter

    switch (condition) {
      case 'equals':
        return `${field} = "${value}"`
      case 'not_equals':
        return `${field} != "${value}"`
      case 'contains':
        return `${field} ~ "${value}"`
      case 'starts_with':
        return `${field} ~ "^${value}"`
      case 'ends_with':
        return `${field} ~ "${value}$"`
      case 'greater_than':
        return `${field} > "${value}"`
      case 'less_than':
        return `${field} < "${value}"`
      case 'greater_equal':
        return `${field} >= "${value}"`
      case 'less_equal':
        return `${field} <= "${value}"`
      case 'is_empty':
        return `${field} = ""`
      case 'is_not_empty':
        return `${field} != ""`
      default:
        return `${field} = "${value}"`
    }
  }, [])

  // Build filter query
  const buildFilterQuery = useCallback(() => {
    const filters: string[] = []

    // Add base filter if provided
    if (config.query?.filter) {
      filters.push(`(${config.query.filter})`)
    }

    // Add search filters
    if (globalFilter && config.searchFields?.length) {
      const searchConditions = config.searchFields.map(field =>
        `${field} ~ "${globalFilter}"`
      ).join(' || ')
      filters.push(`(${searchConditions})`)
    }

    // Add advanced filters
    if (advancedFilters.length > 0) {
      const advancedConditions = advancedFilters.map(filter =>
        convertAdvancedFilterCondition(filter)
      )
      filters.push(...advancedConditions)
    }

    return filters.join(' && ')
  }, [config.query?.filter, config.searchFields, globalFilter, advancedFilters, convertAdvancedFilterCondition])

  // Build sort query
  const buildSortQuery = useCallback(() => {
    return config.query?.sort || '-created'
  }, [config.query?.sort])

  const filterQuery = useMemo(() => buildFilterQuery(), [buildFilterQuery])
  const sortQuery = useMemo(() => buildSortQuery(), [buildSortQuery])

  const queryKey = useMemo(() => [
    "backend",
    config.collection,
    {
      page: currentPage,
      perPage: currentPageSize,
      filter: filterQuery,
      sort: sortQuery,
      expand: config.query?.expand || "",
      fields: config.query?.fields || "",
      typed: Boolean(config.loadPage),
      search: config.loadPage ? globalFilter : undefined,
      filters: config.loadPage ? advancedFilters : undefined,
    }
  ], [config.collection, currentPage, currentPageSize, filterQuery, sortQuery, config.query?.expand, config.query?.fields, config.loadPage, globalFilter, advancedFilters])

  const query = useQuery({
    queryKey,
    queryFn: async () => {
      if (config.loadPage) {
        return config.loadPage({
          page: currentPage,
          perPage: currentPageSize,
          search: globalFilter,
          filters: advancedFilters,
        })
      }
      return backendClient.resource(config.collection).getList(currentPage, currentPageSize, {
        filter: filterQuery || undefined,
        sort: sortQuery,
        expand: config.query?.expand || undefined,
        fields: config.query?.fields || undefined,
      })
    },
    placeholderData: keepPreviousData,
  })

  useEffect(() => {
    if (!query.data) return
    setData(query.data.items as unknown as TData[])
    setTotalItems(query.data.totalItems)
    setCurrentPage(query.data.page)
    hasLoadedRef.current = true
    setError(null)
  }, [query.data])

  useEffect(() => {
    if (!query.error) return
    const err = query.error as Error
    if (err.message?.includes("autocancelled")) return
    const error: TableError = {
      type: 'fetch',
      message: err.message || 'Failed to fetch data',
      details: err
    }
    setError(error)
    config.onError?.(err)
    showToast.error('Error', error.message)
  }, [query.error, config])

  // Refresh data
  const refresh = useCallback(async () => {
    actionRef.current = 'refresh'
    await queryClient.invalidateQueries({ queryKey: ["backend", config.collection] })
  }, [queryClient, config.collection])

  useEffect(() => {
    if (config.refreshSignal === undefined) return
    void refresh()
  }, [config.refreshSignal, refresh])

  // Navigate to page
  const goToPage = useCallback(async (page: number) => {
    if (page >= 1 && page <= paginationInfo.totalPages) {
      actionRef.current = 'pagination'
      setCurrentPage(page)
    }
  }, [paginationInfo.totalPages])

  // Change page size
  const changePageSize = useCallback(async (size: number) => {
    actionRef.current = 'table'
    setCurrentPageSize(size)
    setCurrentPage(1)
    // fetchData will be called by useEffect when currentPageSize changes
  }, [])

  // Update global filter
  const updateGlobalFilter = useCallback(async (filter: string) => {
    actionRef.current = 'table'
    setGlobalFilter(filter)
    setCurrentPage(1)
    // fetchData will be called by useEffect when globalFilter changes
  }, [])

  // Update advanced filters
  const updateAdvancedFilters = useCallback(async (filters: AdvancedFilter[]) => {
    actionRef.current = 'table'
    setAdvancedFilters(filters)
    setCurrentPage(1)
    // fetchData will be called by useEffect when advancedFilters changes
  }, [])

  // Clear selection
  const clearSelection = useCallback(() => {
    setSelectedRows([])
  }, [])

  // Export functionality
  const exportData = useCallback(async (
    format: ExportFormat,
    options?: { selectedOnly?: boolean }
  ) => {
    const selectedOnly = options?.selectedOnly ?? false
    setActionLoading(prev => ({ ...prev, export: true }))
    try {
      const dataToExport = selectedOnly ? selectedRows : data
      const filename = `${config.collection}_export`

      if (format === 'csv') {
        await exportToCSV(dataToExport, `${filename}.csv`)
      } else if (format === 'json') {
        await exportToJSON(dataToExport, `${filename}.json`)
      } else if (format === 'xlsx') {
        await exportToExcel(dataToExport, `${filename}.xlsx`)
      }

      showToast.success('Success', `Data exported as ${format.toUpperCase()}`)
    } catch (err) {
      const error: TableError = {
        type: 'export',
        message: err instanceof Error ? err.message : 'Export failed',
        details: err
      }
      setError(error)
      showToast.error('Error', error.message)
    } finally {
      setActionLoading(prev => ({ ...prev, export: false }))
    }
  }, [selectedRows, data, config.collection])

  // Realtime subscriptions (always enabled)
  useEffect(() => {
    if (config.loadPage) return
    void backendClient.resource(config.collection).subscribe('*', (e) => {
      if (e.action === 'create') {
        setData(prev => [e.record as unknown as TData, ...prev.slice(0, currentPageSize - 1)])
        setTotalItems(prev => prev + 1)
        showToast.info('New Record', `A new ${config.collection} record was created`)
      } else if (e.action === 'update') {
        setData(prev => prev.map(item =>
          item.id === e.record.id ? e.record as unknown as TData : item
        ))
        showToast.info('Record Updated', `A ${config.collection} record was updated`)
      } else if (e.action === 'delete') {
        setData(prev => prev.filter(item => item.id !== e.record.id))
        setTotalItems(prev => prev - 1)
        setSelectedRows(prev => prev.filter(item => item.id !== e.record.id))
        showToast.info('Record Deleted', `A ${config.collection} record was deleted`)
      }
    })

    return () => {
      backendClient.resource(config.collection).unsubscribe('*')
    }
  }, [config.collection, config.loadPage, currentPageSize, backendClient])

  // Effects for data fetching
  useEffect(() => {
    if (!hasLoadedRef.current) {
      actionRef.current = 'initial'
    }
    setCurrentPage(1)
  }, [currentPageSize, globalFilter, advancedFilters])

  // Selection change callback
  useEffect(() => {
    config.onSelect?.(selectedRows)
  }, [selectedRows, config])

  return {
    // Data
    data,
    totalItems,
    paginationInfo,

    // State
    loading: {
      initial: query.isPending && !hasLoadedRef.current,
      pagination: query.isFetching && actionRef.current === 'pagination',
      table: query.isFetching && actionRef.current === 'table',
      refresh: query.isFetching && actionRef.current === 'refresh',
      export: actionLoading.export,
      import: actionLoading.import,
      bulkAction: actionLoading.bulkAction,
    },
    error,

    // Core actions
    refresh,
    goToPage,
    changePageSize,
    updateFilters: async () => {}, // No-op for simplified version
    updateSorting: async () => {}, // No-op for simplified version
    updateGlobalFilter,
    updateAdvancedFilters,

    // Selection
    selectedRows,
    selectRow: () => {}, // No-op for simplified version
    selectAll: () => {}, // No-op for simplified version
    clearSelection,

    // Expand (legacy - no-ops)
    expandedRows: {},
    toggleRowExpansion: () => {},
    expandAll: () => {},
    collapseAll: () => {},

    // Bulk operations
    executeBulkAction: async () => {}, // No-op for simplified version

    // Export/Import
    exportData,
    importData: async () => {}, // No-op for simplified version
  }
}

// Helper functions for export
async function exportToCSV(data: unknown[], filename: string) {
  if (data.length === 0) return

  const headers = Object.keys(data[0] as Record<string, unknown>)
  const csvContent = [
    headers.join(','),
    ...data.map(row => headers.map(header =>
      JSON.stringify((row as Record<string, unknown>)[header] || '')
    ).join(','))
  ].join('\n')

  downloadFile(csvContent, filename, 'text/csv')
}

async function exportToJSON(data: unknown[], filename: string) {
  const jsonContent = JSON.stringify(data, null, 2)
  downloadFile(jsonContent, filename, 'application/json')
}

async function exportToExcel(data: unknown[], filename: string) {
  // This would require the 'xlsx' library to be installed
  // For now, we'll export as CSV as a fallback
  await exportToCSV(data, filename.replace('.xlsx', '.csv'))
}

function downloadFile(content: string, filename: string, mimeType: string) {
  const blob = new Blob([content], { type: mimeType })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}
