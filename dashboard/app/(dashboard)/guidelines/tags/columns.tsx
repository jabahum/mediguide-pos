"use client"

import type { Column, Row } from "@tanstack/react-table"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import type { GuidelineTagsResponse } from "@/types/backend-types"
import { ExtendedColumnDef } from "@/types/data-table"

// Export for use in other components  
export const columns: ExtendedColumnDef<GuidelineTagsResponse>[] = [
  {
    accessorKey: "name",
    header: ({ column }: { column: Column<GuidelineTagsResponse> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Name"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }: { row: Row<GuidelineTagsResponse> }) => {
      const name = row.getValue("name") as string
      return <div className="font-medium">{name}</div>
    },
    enableSorting: true,
    enableHiding: false,
  },
  {
    accessorKey: "description",
    header: ({ column }: { column: Column<GuidelineTagsResponse> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Description"
        canSort={false}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }: { row: Row<GuidelineTagsResponse> }) => {
      const description = row.getValue("description") as string
      if (!description) return <span className="text-muted-foreground">—</span>
      
      return (
        <div className="max-w-[300px]">
          <p className="truncate text-sm">{description}</p>
        </div>
      )
    },
    enableSorting: false,
  },
  {
    accessorKey: "created",
    header: ({ column }: { column: Column<GuidelineTagsResponse> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Created"
        canSort={true}
        canFilter={true}
        filterType="dateRange"
      />
    ),
    cell: ({ row }: { row: Row<GuidelineTagsResponse> }) => {
      const created = row.getValue("created") as string
      if (!created) return <span className="text-muted-foreground">—</span>
      
      return (
        <time className="text-sm text-muted-foreground">
          {new Date(created).toLocaleDateString()}
        </time>
      )
    },
    enableSorting: true,
    size: 100,
  },
  {
    accessorKey: "updated",
    header: ({ column }: { column: Column<GuidelineTagsResponse> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Updated"
        canSort={true}
        canFilter={true}
        filterType="dateRange"
      />
    ),
    cell: ({ row }: { row: Row<GuidelineTagsResponse> }) => {
      const updated = row.getValue("updated") as string
      if (!updated) return <span className="text-muted-foreground">—</span>
      
      return (
        <time className="text-sm text-muted-foreground">
          {new Date(updated).toLocaleDateString()}
        </time>
      )
    },
    enableSorting: true,
    size: 100,
  },
]

export type TagType = GuidelineTagsResponse