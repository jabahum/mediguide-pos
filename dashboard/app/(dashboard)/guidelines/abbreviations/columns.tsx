"use client"

import { Badge } from "@/components/ui/badge"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { AbbreviationsResponse } from "@/types/backend-types"
import { AbbreviationsWithExpanded } from "@/types/expanded"
import { ExtendedColumnDef } from "@/types/data-table"
import { CheckCircle, Clock } from "lucide-react"

export const abbreviationsColumns: ExtendedColumnDef<AbbreviationsWithExpanded>[] = [
  {
    accessorKey: "abbreviation",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Abbreviation"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => (
      <div className="font-mono font-semibold text-sm">
        {row.getValue("abbreviation")}
      </div>
    ),
    enableSorting: true,
    enableHiding: false,
  },
  {
    accessorKey: "meaning",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Meaning"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => (
      <div className="font-medium max-w-[300px]">
        {row.getValue("meaning")}
      </div>
    ),
    enableSorting: true,
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
      return description ? (
        <div className="text-muted-foreground text-sm max-w-[200px] truncate">
          {description}
        </div>
      ) : (
        <span className="text-muted-foreground italic">No description</span>
      )
    },
    enableSorting: false,
  },
  {
    accessorKey: "common_usage",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Common Usage"
        canSort={true}
        canFilter={true}
        filterType="boolean"
      />
    ),
    cell: ({ row }) => {
      const isCommon = row.getValue("common_usage") as boolean
      return isCommon ? (
        <Badge variant="default" className="text-xs">
          <CheckCircle className="w-3 h-3 mr-1" />
          Common
        </Badge>
      ) : (
        <Badge variant="outline" className="text-xs">
          <Clock className="w-3 h-3 mr-1" />
          Standard
        </Badge>
      )
    },
    enableSorting: true,
  },
  {
    accessorKey: "category",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Category"
        canSort={false}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const data = row.original
      const category = data.expand?.category
      
      return category ? (
        <Badge 
          variant="secondary" 
          className="text-xs"
          style={{ 
            backgroundColor: category.color ? `${category.color}20` : undefined,
            borderColor: category.color || undefined
          }}
        >
          {category.name}
        </Badge>
      ) : (
        <span className="text-muted-foreground italic text-xs">No category</span>
      )
    },
    enableSorting: false,
  },
  {
    accessorKey: "tags",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Tags"
        canSort={false}
        canFilter={false}
      />
    ),
    cell: ({ row }) => {
      const data = row.original
      const tags = data.expand?.tags || []
      
      return tags.length > 0 ? (
        <div className="flex flex-wrap gap-1 max-w-[200px]">
          {tags.slice(0, 1).map((tag) => (
            <Badge key={tag.id} variant="outline" className="text-xs">
              {tag.name}
            </Badge>
          ))}
          {tags.length > 1 && (
            <span className="text-muted-foreground text-xs">
              +{tags.length - 1}...
            </span>
          )}
        </div>
      ) : (
        <span className="text-muted-foreground italic text-xs">No tags</span>
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
        <div className="text-muted-foreground text-sm">
          {date.toLocaleDateString()}
        </div>
      )
    },
    enableSorting: true,
    enableHiding: true,
    defaultVisible: false,
  },
]

export type AbbreviationType = AbbreviationsResponse