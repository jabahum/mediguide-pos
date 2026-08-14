"use client"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { ExternalLink } from "lucide-react"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { ExtendedColumnDef } from "@/types/data-table"
import { HealthSubDistrictsWithDistrict } from "@/types/expanded"
import { withDashboardBasePath } from "@/lib/dashboard-path"

export const healthSubDistrictsColumns: ExtendedColumnDef<HealthSubDistrictsWithDistrict>[] = [
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Health Sub-District" />
    ),
    cell: ({ row }) => (
      <div className="font-medium">{row.getValue("name")}</div>
    ),
    enableSorting: true,
    enableHiding: false,
  },
  {
    id: "district_name",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="District" />
    ),
    accessorFn: (row) => {
      const district = row.expand?.district
      return district?.name || "No District"
    },
    cell: ({ row }) => {
      const district = row.original.expand?.district
      
      if (!district) {
        return <span className="text-muted-foreground">No District</span>
      }
      
      return (
        <Button
          variant="link"
          size="sm"
          className="h-auto p-0 text-left justify-start"
          onClick={(e) => {
            e.stopPropagation()
            window.location.href = withDashboardBasePath(`/health-facilities/districts/${district.id}`)
          }}
        >
          {district.name}
          <ExternalLink className="ml-1 h-3 w-3" />
        </Button>
      )
    },
    enableSorting: true,
  },
  {
    accessorKey: "nhpi_code",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="NHPI Code" />
    ),
    cell: ({ row }) => (
      <Badge variant="secondary" className="font-mono text-xs">
        {row.getValue("nhpi_code")}
      </Badge>
    ),
    enableSorting: true,
  },
  {
    accessorKey: "hsdt_code",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="HSDT Code" />
    ),
    cell: ({ row }) => (
      <Badge variant="outline" className="font-mono text-xs">
        {row.getValue("hsdt_code")}
      </Badge>
    ),
    enableSorting: true,
  },
  {
    accessorKey: "created",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Created" />
    ),
    cell: ({ row }) => {
      const date = new Date(row.getValue("created"))
      return (
        <div className="text-muted-foreground">
          {date.toLocaleDateString()}
        </div>
      )
    },
    enableSorting: true,
  },
]

export type HealthSubDistrictType = HealthSubDistrictsWithDistrict
