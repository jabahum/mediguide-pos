import { ColumnDef } from "@tanstack/react-table"
import { LucideIcon } from "lucide-react"

// Base shape shared by records returned from the backend compatibility API.
export interface BaseRecord {
  id: string
  created: string
  updated: string
  expand?: unknown | Record<string, unknown | unknown[]>
  [key: string]: unknown
}

// Filter types (includes legacy types for compatibility)
export type FilterType = 'text' | 'select' | 'date' | 'dateRange' | 'number' | 'numberRange' | 'boolean' | 'json'
export type FilterCondition = 'equals' | 'contains' | 'starts_with' | 'ends_with' | 'greater_than' | 'less_than' | 'greater_equal' | 'less_equal' | 'not_equals' | 'is_empty' | 'is_not_empty'

export interface AdvancedFilter {
  id: string
  field: string
  condition: FilterCondition
  value: string | number | boolean | null
  /** Human-readable form of `value` for fields whose stored value is an opaque id (e.g. PB relation). */
  displayValue?: string
}

export interface FieldOption {
  label: string
  value: string
  type: FilterType
  /** Static options for select-type fields */
  options?: FilterOption[]
  /**
   * Dynamic options sourced from a backend collection. Use this for
   * relation fields so the filter UI shows human-readable labels while the
   * underlying filter value remains the related record id.
   */
  relation?: {
    collection?: string
    key?: string
    loadOptions?: (search: string, pageSize: number) => Promise<Array<Record<string, unknown>>>
    labelField?: string
    valueField?: string
    sort?: string
    filter?: string
    pageSize?: number
  }
}

// Keep some complex types for backward compatibility
export interface FilterOption {
  label: string
  value: string
}

export interface RangeFilterValue {
  type: 'range'
  min?: string | number
  max?: string | number
}

export interface DateRangeFilterValue {
  type: 'dateRange'
  start?: string
  end?: string
  preset?: 'today' | 'yesterday' | 'thisWeek' | 'lastWeek' | 'thisMonth' | 'lastMonth' | 'thisYear' | 'lastYear'
}

// Legacy types for existing components
export interface ImportOptions {
  validateData: boolean
  skipErrors: boolean
  updateExisting: boolean
  batchSize: number
}

export interface ImportResult {
  success: boolean
  imported: number
  errors: string[]
  warnings: string[]
  skipped?: number
  updated?: number
}

// Legacy expand types
export interface ExpandConfig {
  relations: Record<string, RelationConfig>
}
export interface RelationConfig {
  collection: string
  displayFields: string[]
  expandable?: boolean
  renderer?: 'table' | 'list' | 'custom' | 'inline'
  customComponent?: React.ComponentType<any>
  nested?: any
  maxRows?: number
  showPagination?: boolean
  linkTo?: string | ((record: BaseRecord) => string)
  sortBy?: string
}

export interface DataTableExpandableRowProps<TData = BaseRecord> {
  row: TData
  expandConfig: any
  isExpanded: boolean
  onToggle: () => void
  depth?: number
  relationRenderers?: Record<string, React.ComponentType<any>>
}


// Action types
export interface RowAction<TData = BaseRecord> {
  id: string
  label: string
  icon?: LucideIcon
  onClick: (row: TData) => void | Promise<void>
  disabled?: (row: TData) => boolean
  variant?: 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link'
  separator?: boolean
  requiresConfirmation?: boolean
  confirmMessage?: string
}

export interface BulkAction<TData = BaseRecord> {
  id: string
  label: string
  icon?: LucideIcon
  onClick: (rows: TData[]) => void | Promise<void>
  disabled?: (rows: TData[]) => boolean
  variant?: 'default' | 'destructive' | 'outline' | 'secondary'
  confirmMessage?: string
  requiresConfirmation?: boolean
  description?: string
  separator?: boolean
}

// Simplified Export types
export type ExportFormat = 'csv' | 'json' | 'xlsx'

// Query options supported by the temporary collection compatibility API.
export interface BackendQueryOptions {
  expand?: string
  filter?: string
  sort?: string
  fields?: string
}

export interface DomainPageQuery {
  page: number
  perPage: number
  search: string
  filters: AdvancedFilter[]
}

export interface DomainPageResult<TData> {
  items: TData[]
  page: number
  perPage: number
  totalItems: number
  totalPages: number
}

export type DomainPageLoader<TData> = (
  query: DomainPageQuery,
) => Promise<DomainPageResult<TData>>

// Simplified UI options
export interface UIOptions {
  pageSize?: number
  exportable?: boolean
  importable?: boolean
  title?: string
  description?: string
}

// Main DataTable props - SIMPLIFIED
export interface BackendDataTableProps<TData = BaseRecord> {
  // Core required
  collection: string
  columns: ColumnDef<TData>[]
  loadPage?: DomainPageLoader<TData>

  // Search (explicit)
  searchFields?: string[]
  searchPlaceholder?: string

  // Actions (keep separate)
  rowActions?: RowAction<TData>[]
  bulkActions?: BulkAction<TData>[]

  // Filtering (explicit)
  availableFields?: FieldOption[]

  // Backend collection query options
  query?: BackendQueryOptions
  refreshSignal?: number | string

  // UI options (grouped)
  ui?: UIOptions

  // Callbacks
  onRowClick?: (row: TData) => void
  onSelect?: (rows: TData[]) => void
  onError?: (error: Error) => void
}

// Legacy interface for backward compatibility
export interface EnhancedBackendDataTableProps<TData = BaseRecord> {
  // Required
  columns: ColumnDef<TData>[]
  loadPage?: DomainPageLoader<TData>

  // Legacy collection prop mapping
  collection?: string
  collectionName?: string // fallback to this if collection not provided

  // Legacy collection query settings
  expand?: string
  filter?: string
  sort?: string
  realtime?: boolean
  fields?: string

  // Legacy pagination
  defaultPageSize?: number
  pageSizeOptions?: number[]

  // Legacy search
  searchable?: boolean
  searchFields?: string[]
  searchPlaceholder?: string

  // Legacy selection
  selectable?: boolean
  enableSelectAll?: boolean

  // Actions (keep as-is)
  rowActions?: RowAction<TData>[]
  bulkActions?: BulkAction<TData>[]

  // Legacy Export/Import
  exportable?: boolean
  importable?: boolean
  exportConfig?: any
  importConfig?: any

  // Legacy expand (ignored for now)
  expandable?: boolean
  expandMode?: 'click' | 'always' | 'manual'
  relationRenderers?: Record<string, React.ComponentType<any>>

  // Legacy UI
  title?: string
  description?: string
  toolbar?: boolean
  columnVisibility?: boolean

  // Legacy handlers
  onRowClick?: (row: TData) => void
  onSelectionChange?: (selectedRows: TData[]) => void
  onSelect?: (rows: TData[]) => void
  onError?: (error: Error) => void
  onDataChange?: (data: TData[]) => void
  onAdvancedFilter?: (filters: AdvancedFilter[]) => void

  // Advanced filtering
  availableFields?: FieldOption[]

  // Column persistence (ignored for now)
  persistColumnConfig?: boolean
  userId?: string
  tableContext?: string

  // Legacy expand state
  expandedRows?: Record<string, boolean>
  toggleRowExpansion?: (rowId: string) => void
}


// Pagination info
export interface PaginationInfo {
  page: number
  perPage: number
  totalItems: number
  totalPages: number
  hasNextPage: boolean
  hasPreviousPage: boolean
}

// Loading states
export interface LoadingStates {
  initial: boolean
  pagination: boolean
  table: boolean
  export: boolean
  import: boolean
  bulkAction: boolean
  refresh: boolean
}

// Error types
export interface TableError {
  type: 'fetch' | 'export' | 'import' | 'bulk_action' | 'validation'
  message: string
  details?: unknown
}

// Simplified hook interface
export interface UseBackendTableConfig<TData = BaseRecord> {
  collection: string
  loadPage?: DomainPageLoader<TData>
  searchFields?: string[]
  rowActions?: RowAction<TData>[]
  bulkActions?: BulkAction<TData>[]
  availableFields?: FieldOption[]
  query?: BackendQueryOptions
  refreshSignal?: number | string
  ui?: UIOptions
  onRowClick?: (row: TData) => void
  onSelect?: (rows: TData[]) => void
  onError?: (error: Error) => void
}

// Hook return type (compatible with legacy usage)
export interface UseBackendTableReturn<TData = BaseRecord> {
  // Data
  data: TData[]
  totalItems: number
  paginationInfo: PaginationInfo

  // State
  loading: LoadingStates
  error: TableError | null

  // Core actions
  refresh: () => Promise<void>
  goToPage: (page: number) => Promise<void>
  changePageSize: (size: number) => Promise<void>
  updateFilters: (filters: Record<string, unknown>) => Promise<void>
  updateSorting: (sorting: { id: string; desc: boolean }[]) => Promise<void>
  updateGlobalFilter: (filter: string) => Promise<void>
  updateAdvancedFilters: (filters: AdvancedFilter[]) => Promise<void>

  // Selection
  selectedRows: TData[]
  selectRow: (row: TData) => void
  selectAll: () => void
  clearSelection: () => void

  // Expand (legacy)
  expandedRows: Record<string, boolean>
  toggleRowExpansion: (rowId: string) => void
  expandAll: () => void
  collapseAll: () => void

  // Bulk operations
  executeBulkAction: (actionId: string, rows: TData[]) => Promise<void>

  // Export/Import
  exportData: (format: ExportFormat, options?: { selectedOnly?: boolean }) => Promise<void>
  importData: (file: File, format: ExportFormat) => Promise<void>
}

// Keep existing column definition
export type ExtendedColumnDef<TData = unknown> = ColumnDef<TData> & {
  defaultVisible?: boolean
}


// Component prop types for individual components
export interface DataTableToolbarProps<TData = BaseRecord> {
  table: any // TanStack table instance
  searchable?: boolean
  searchPlaceholder?: string
  bulkActions?: BulkAction<TData>[]
  selectedRows?: TData[]
  onRefresh?: () => void
  loading?: boolean
}

export interface DataTablePaginationProps {
  table: any // TanStack table instance
  paginationInfo: PaginationInfo
  pageSizeOptions?: number[]
  onPageChange?: (page: number) => void
  onPageSizeChange?: (size: number) => void
  loading?: boolean
}

export interface DataTableColumnHeaderProps {
  title: string
  canSort?: boolean
  canFilter?: boolean
  filterType?: FilterType
  filterOptions?: FilterOption[]
  column: any // TanStack column instance
}

export interface DataTableRowActionsProps<TData = BaseRecord> {
  row: TData
  actions: RowAction<TData>[]
}

export interface DataTableBulkActionsProps<TData = BaseRecord> {
  selectedRows: TData[]
  actions: BulkAction<TData>[]
  onAction: (actionId: string, rows: TData[]) => void
  onClearSelection: () => void
}
