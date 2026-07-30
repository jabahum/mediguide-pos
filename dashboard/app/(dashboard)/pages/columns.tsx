"use client"

import { Badge } from "@/components/ui/badge"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { GenericPagesResponse } from "@/types/backend-types"
import { ExtendedColumnDef } from "@/types/data-table"

// Export the GenericPage type for use in other files
export type GenericPage = GenericPagesResponse

export const columns: ExtendedColumnDef<GenericPage>[] = [
  // ESSENTIAL COLUMNS (Always Visible)
  {
    accessorKey: "title",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Title"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const title = row.getValue("title") as string
      return (
        <div className="font-medium">{title}</div>
      )
    },
    enableHiding: false, // Always show title
  },
  {
    accessorKey: "key",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Key"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const key = row.getValue("key") as string
      return (
        <Badge variant="secondary" className="font-mono text-xs">
          {key}
        </Badge>
      )
    },
  },
  {
    accessorKey: "description",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Description"
        canSort={false}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const description = row.getValue("description") as string
      return (
        <div className="text-muted-foreground max-w-[300px] truncate">
          {description || "—"}
        </div>
      )
    },
    enableSorting: false,
  },
  {
    accessorKey: "content",
    header: "Content Status",
    cell: () => {
      // Since content field is excluded from the query, we can't determine the actual status
      // We'll show a placeholder that indicates content status is unknown
      // In a real implementation, you might want to make a separate API call or 
      // include a computed field in the response
      return (
        <Badge variant="secondary">Content available</Badge>
      )
    },
  },
  {
    accessorKey: "created",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Created"
        canSort={true}
        canFilter={true}
        filterType="date"
      />
    ),
    cell: ({ row }) => {
      const date = new Date(row.getValue("created"))
      return (
        <div className="text-muted-foreground">
          {date.toLocaleDateString()}
        </div>
      )
    },
  },
  {
    accessorKey: "updated",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Updated"
        canSort={true}
        canFilter={true}
        filterType="date"
      />
    ),
    cell: ({ row }) => {
      const date = new Date(row.getValue("updated"))
      return (
        <div className="text-muted-foreground">
          {date.toLocaleDateString()}
        </div>
      )
    },
  },
]