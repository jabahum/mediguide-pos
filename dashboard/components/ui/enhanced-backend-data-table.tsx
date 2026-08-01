"use client"

import * as React from "react"
import { BackendDataTable } from "@/components/ui/backend-data-table"
import {
  BaseRecord,
  EnhancedBackendDataTableProps,
} from "@/types/data-table"

export function EnhancedBackendDataTable<TData extends BaseRecord = BaseRecord>(
  props: EnhancedBackendDataTableProps<TData>
) {
  // Map the established presentation props to the typed table structure.
  const {
    collectionName,
    collection = collectionName,
    columns,
    loadPage,

    // Legacy pagination
    defaultPageSize = 20,

    // Legacy search
    searchable = true,
    searchFields = [],
    searchPlaceholder = "Search...",

    // Legacy selection
    selectable = true,

    // Actions (keep as-is)
    rowActions = [],
    bulkActions = [],

    // Legacy Export/Import
    exportable = false,
    importable = false,

    // Legacy UI
    title,
    description,

    // Legacy handlers
    onRowClick,
    onSelectionChange,
    onSelect = onSelectionChange, // new prop takes precedence
    onError,

    // Advanced filtering
    availableFields = []
  } = props
  // Use the new simplified DataTable component
  return (
    <BackendDataTable<TData>
      collection={collection!}
      columns={columns}
      loadPage={loadPage}
      searchFields={searchable ? searchFields : []}
      searchPlaceholder={searchPlaceholder}
      rowActions={rowActions}
      bulkActions={selectable ? bulkActions : []}
      availableFields={availableFields}
      ui={{
        pageSize: defaultPageSize,
        exportable,
        importable,
        title,
        description,
      }}
      onRowClick={onRowClick}
      onSelect={onSelect}
      onError={onError}
    />
  )
}
