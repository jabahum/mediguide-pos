"use client"

import * as React from "react"
import {
  ColumnDef,
  ColumnFiltersState,
  SortingState,
  VisibilityState,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
  RowSelectionState,
} from "@tanstack/react-table"
import { Loader2, RefreshCw, AlertCircle } from "lucide-react"

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { DataTableToolbar } from "@/components/ui/datatable-toolbar"
import { DataTablePagination } from "@/components/ui/datatable-pagination"
import { DataTableRowActions } from "@/components/ui/datatable-row-actions"
import { useBackendTable } from "@/hooks/use-backend-table"
import {
  BaseRecord,
  BackendDataTableProps,
  ExportFormat,
} from "@/types/data-table"

// Default configuration with smart defaults
const DEFAULT_CONFIG = {
  pageSize: 20,
  pageSizeOptions: [10, 20, 50, 100],
  searchPlaceholder: "Search...",
  exportFormats: ['csv', 'json'] as ExportFormat[],
  importFormats: ['csv', 'json'] as ExportFormat[],
}

export function BackendDataTable<TData extends BaseRecord = BaseRecord>({
  collection,
  columns,
  loadPage,

  // Search options
  searchFields = [],
  searchPlaceholder = DEFAULT_CONFIG.searchPlaceholder,

  // Actions (keep separate)
  rowActions = [],
  bulkActions = [],

  // Filtering
  availableFields = [],

  refreshSignal,

  // UI options with smart defaults
  ui = {},

  // Callbacks
  onRowClick,
  onSelect,
  onError,
}: BackendDataTableProps<TData>) {

  // Merge UI options with defaults
  const uiConfig = {
    pageSize: ui.pageSize || DEFAULT_CONFIG.pageSize,
    exportable: ui.exportable ?? true,
    importable: ui.importable ?? true,
    title: ui.title,
    description: ui.description,
  }

  // Enhanced columns with selection if bulk actions are provided
  const enhancedColumns = React.useMemo(() => {
    const cols: ColumnDef<TData>[] = [...(columns as ColumnDef<TData>[])]

    // Add selection column if bulk actions are provided
    if (bulkActions.length > 0) {
      cols.unshift({
        id: "select",
        header: ({ table }) => (
          <input
            type="checkbox"
            checked={table.getIsAllPageRowsSelected()}
            ref={(el) => {
              if (el) el.indeterminate = table.getIsSomePageRowsSelected() && !table.getIsAllPageRowsSelected()
            }}
            onChange={(e) => table.toggleAllPageRowsSelected(e.target.checked)}
            onClick={(e) => e.stopPropagation()}
            aria-label="Select all"
            className="rounded border-gray-300"
          />
        ),
        cell: ({ row }) => (
          <input
            type="checkbox"
            checked={row.getIsSelected()}
            onChange={(e) => row.toggleSelected(e.target.checked)}
            onClick={(e) => e.stopPropagation()}
            aria-label="Select row"
            className="rounded border-gray-300"
          />
        ),
        enableSorting: false,
        enableHiding: false,
      })
    }

    // Add actions column if row actions are provided
    if (rowActions.length > 0) {
      cols.push({
        id: "actions",
        header: "Actions",
        cell: ({ row }) => (
          <DataTableRowActions row={row.original} actions={rowActions} />
        ),
        enableSorting: false,
        enableHiding: false,
      })
    }

    return cols
  }, [columns, rowActions, bulkActions])

  // Hook for data management with simplified config
  const {
    data,
    paginationInfo,
    loading,
    error,
    refresh,
    goToPage,
    changePageSize,
    updateGlobalFilter,
    updateAdvancedFilters,
    selectedRows,
    exportData,
  } = useBackendTable<TData>({
    collection,
    loadPage,
    searchFields,
    rowActions,
    bulkActions,
    availableFields,
    refreshSignal,
    ui: uiConfig,
    onRowClick,
    onSelect,
    onError,
  })

  // Table state
  const [sorting, setSorting] = React.useState<SortingState>([])
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([])
  const defaultColumnVisibility = React.useMemo<VisibilityState>(() => {
    const hidden = new Set([
      "status",
      "created",
      "updated",
      "order",
    ])
    const visibility: VisibilityState = {}

    const getColumnId = (column: ColumnDef<TData>) => {
      if (column.id) return column.id
      if ("accessorKey" in column && typeof column.accessorKey === "string") {
        return column.accessorKey
      }
      return undefined
    }

    columns.forEach((column) => {
      const id = getColumnId(column)
      const configuredAsHidden =
        "defaultVisible" in column && column.defaultVisible === false
      if (id && (hidden.has(id) || configuredAsHidden)) {
        visibility[id] = false
      }
    })

    return visibility
  }, [columns])

  const [columnVisibility, setColumnVisibility] = React.useState<VisibilityState>(
    defaultColumnVisibility
  )
  const [rowSelection, setRowSelection] = React.useState<RowSelectionState>({})
  const [globalFilter, setGlobalFilter] = React.useState("")

  React.useEffect(() => {
    setColumnVisibility((prev) => ({ ...defaultColumnVisibility, ...prev }))
  }, [defaultColumnVisibility])

  // TanStack Table instance
  const table = useReactTable({
    data,
    columns: enhancedColumns,
    pageCount: paginationInfo.totalPages,
    state: {
      sorting,
      columnFilters,
      columnVisibility,
      rowSelection,
      globalFilter,
      pagination: {
        pageIndex: paginationInfo.page - 1,
        pageSize: paginationInfo.perPage,
      },
    },
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onColumnVisibilityChange: setColumnVisibility,
    onRowSelectionChange: setRowSelection,
    onGlobalFilterChange: setGlobalFilter,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    manualPagination: true,
    manualSorting: true,
    manualFiltering: true,
  })

  // Handle export
  const handleExport = React.useCallback(async (format: ExportFormat, selectedOnly = false) => {
    await exportData(format, { selectedOnly })
  }, [exportData])

  // Sync selection with hook
  React.useEffect(() => {
    const selectedIndices = Object.keys(rowSelection).filter(id => rowSelection[id])
    const selectedData = selectedIndices.map(indexStr => {
      const index = parseInt(indexStr, 10)
      return data[index]
    }).filter(Boolean)

    onSelect?.(selectedData)
  }, [rowSelection, data, onSelect])

  // Error display
  if (error) {
    return (
      <div className="space-y-4">
        {uiConfig.title && (
          <div>
            <h2 className="text-2xl font-bold tracking-tight">{uiConfig.title}</h2>
            {uiConfig.description && (
              <p className="text-muted-foreground">{uiConfig.description}</p>
            )}
          </div>
        )}

        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription className="flex items-center justify-between">
            <span>{error.message}</span>
            <Button variant="outline" size="sm" onClick={refresh}>
              <RefreshCw className="h-4 w-4 mr-2" />
              Retry
            </Button>
          </AlertDescription>
        </Alert>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Simplified Toolbar */}
      <DataTableToolbar
        table={table}
        title={uiConfig.title}
        description={uiConfig.description}
        searchable={searchFields.length > 0}
        searchPlaceholder={searchPlaceholder}
        bulkActions={bulkActions}
        selectedRows={selectedRows}
        availableFields={availableFields}
        exportFormats={uiConfig.exportable ? DEFAULT_CONFIG.exportFormats : []}
        importFormats={uiConfig.importable ? DEFAULT_CONFIG.importFormats : []}
        onRefresh={refresh}
        onExport={uiConfig.exportable ? handleExport : undefined}
        onAdvancedFilter={updateAdvancedFilters}
        onGlobalFilterChange={updateGlobalFilter}
        loading={loading.initial || loading.table || loading.refresh || loading.pagination}
      />

      {/* Table */}
      <div className="grid grid-cols-1">
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              {table.getHeaderGroups().map((headerGroup) => (
                <TableRow key={headerGroup.id}>
                  {headerGroup.headers.map((header) => (
                    <TableHead key={header.id} className="whitespace-nowrap px-4">
                      {header.isPlaceholder
                        ? null
                        : flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                    </TableHead>
                  ))}
                </TableRow>
              ))}
            </TableHeader>
            {(loading.pagination || (loading.table && data.length > 0)) && (
              <tbody>
                <tr>
                  <td colSpan={enhancedColumns.length} className="p-0">
                    <div
                      className="h-1 w-full overflow-hidden bg-primary/20"
                      role="progressbar"
                      aria-busy="true"
                    >
                      <div className="animate-indeterminate-bar h-full w-1/3 bg-primary" />
                    </div>
                  </td>
                </tr>
              </tbody>
            )}
            <TableBody>
              {loading.initial ? (
                <TableRow>
                  <TableCell
                    colSpan={enhancedColumns.length}
                    className="h-24 text-center"
                  >
                    <div className="flex items-center justify-center space-x-2">
                      <Loader2 className="h-6 w-6 animate-spin" />
                      <span>Loading...</span>
                    </div>
                  </TableCell>
                </TableRow>
              ) : table.getRowModel().rows?.length ? (
                table.getRowModel().rows.map((row) => (
                  <TableRow
                    key={row.id}
                    data-state={row.getIsSelected() && "selected"}
                    className={onRowClick ? "cursor-pointer hover:bg-muted/50" : ""}
                    onClick={() => onRowClick?.(row.original)}
                  >
                    {row.getVisibleCells().map((cell) => (
                      <TableCell
                        key={cell.id}
                        className="whitespace-nowrap px-4"
                      >
                        {flexRender(
                          cell.column.columnDef.cell,
                          cell.getContext()
                        )}
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell
                    colSpan={enhancedColumns.length}
                    className="h-24 text-center"
                  >
                    <div className="text-muted-foreground">
                      No {collection} found.
                    </div>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>
      </div>

      {/* Pagination */}
      <DataTablePagination
        table={table}
        paginationInfo={paginationInfo}
        pageSizeOptions={DEFAULT_CONFIG.pageSizeOptions}
        onPageChange={goToPage}
        onPageSizeChange={changePageSize}
        loading={loading.pagination || loading.initial || loading.table}
        showSelection={bulkActions.length > 0}
      />
    </div>
  )
}
