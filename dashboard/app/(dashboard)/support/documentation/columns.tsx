"use client"

import { Badge } from "@/components/ui/badge"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { DocumentationResponse, DocumentationStatusOptions } from "@/types/backend-types"
import { ExtendedColumnDef } from "@/types/data-table"

export const documentationColumns: ExtendedColumnDef<DocumentationResponse>[] = [
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
        <div className="max-w-[300px]">
          <div className="font-medium truncate" title={title}>
            {title}
          </div>
          {row.original.description && (
            <div className="text-xs text-muted-foreground truncate mt-1" title={row.original.description}>
              {row.original.description}
            </div>
          )}
        </div>
      )
    },
    enableSorting: true,
    enableHiding: false,
  },
  {
    accessorKey: "category",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Category"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const category = row.getValue("category") as string
      return category ? (
        <Badge variant="secondary" className="text-xs">
          {category}
        </Badge>
      ) : (
        <span className="text-muted-foreground text-xs">—</span>
      )
    },
    enableSorting: true,
  },
  {
    accessorKey: "status",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Status"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={[
          { label: "Draft", value: "draft" },
          { label: "Published", value: "published" },
          { label: "Archived", value: "archived" }
        ]}
      />
    ),
    cell: ({ row }) => {
      const status = row.getValue("status") as DocumentationStatusOptions
      
      const statusConfig = {
        [DocumentationStatusOptions.draft]: { label: "Draft", variant: "outline" as const },
        [DocumentationStatusOptions.published]: { label: "Published", variant: "default" as const },
        [DocumentationStatusOptions.archived]: { label: "Archived", variant: "secondary" as const }
      }

      const config = statusConfig[status] || statusConfig[DocumentationStatusOptions.draft]

      return (
        <Badge variant={config.variant}>
          {config.label}
        </Badge>
      )
    },
    enableSorting: true,
    filterFn: "equals",
  },
  {
    accessorKey: "tags",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Tags"
        canSort={false}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const tags = row.getValue("tags") as string
      if (!tags || tags.trim() === "") {
        return <span className="text-muted-foreground text-xs">—</span>
      }
      
      const tagList = tags.split(',').map(tag => tag.trim()).filter(tag => tag)
      
      if (tagList.length === 0) {
        return <span className="text-muted-foreground text-xs">—</span>
      }

      return (
        <div className="flex flex-wrap gap-1">
          {tagList.slice(0, 2).map((tag, index) => (
            <Badge key={index} variant="outline" className="text-xs">
              {tag}
            </Badge>
          ))}
          {tagList.length > 2 && (
            <Badge variant="outline" className="text-xs">
              +{tagList.length - 2}
            </Badge>
          )}
        </div>
      )
    },
    enableSorting: false,
  },
  {
    accessorKey: "created",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Created"
        canSort={true}
        canFilter={true}
        filterType="dateRange"
      />
    ),
    cell: ({ row }) => {
      const date = new Date(row.getValue("created"))
      return (
        <div className="text-muted-foreground text-xs">
          {date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
          })}
        </div>
      )
    },
    enableSorting: true,
  },
  {
    accessorKey: "updated",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Updated"
        canSort={true}
        canFilter={true}
        filterType="dateRange"
      />
    ),
    cell: ({ row }) => {
      const date = new Date(row.getValue("updated"))
      return (
        <div className="text-muted-foreground text-xs">
          {date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
          })}
        </div>
      )
    },
    enableSorting: true,
  },
]

export type DocumentationType = DocumentationResponse