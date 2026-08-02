"use client"

import { useState, useCallback, useEffect, useMemo, useRef } from 'react'
import { keepPreviousData, useQuery, useQueryClient } from "@tanstack/react-query"
import { showToast } from '@/lib/toast'
import { staleTimeForDomain } from '@/lib/query-cache-policy'
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

  const queryKey = useMemo(() => [
    "backend",
    config.collection,
    {
      page: currentPage,
      perPage: currentPageSize,
      search: globalFilter,
      filters: advancedFilters,
    }
  ], [config.collection, currentPage, currentPageSize, globalFilter, advancedFilters])

  const query = useQuery({
    queryKey,
    queryFn: async () => {
      return config.loadPage({
        page: currentPage,
        perPage: currentPageSize,
        search: globalFilter,
        filters: advancedFilters,
      })
    },
    placeholderData: keepPreviousData,
    staleTime: staleTimeForDomain(config.collection),
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
