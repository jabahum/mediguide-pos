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
  // Map legacy props to new simplified structure
  const {
    collectionName,
    collection = collectionName, // fallback to legacy prop
    columns,
    loadPage,

    // Legacy collection query settings
    expand = "",
    filter = "",
    sort = "-created",
    fields,

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
      query={{
        expand,
        filter,
        sort,
        fields,
      }}
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
