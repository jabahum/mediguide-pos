"use client"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { ExternalLink } from "lucide-react"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { HealthSubRegionsWithRegion } from "@/types/expanded"
import { ExtendedColumnDef } from "@/types/data-table"
import { withDashboardBasePath } from "@/lib/dashboard-path"

export const healthSubRegionsColumns: ExtendedColumnDef<HealthSubRegionsWithRegion>[] = [
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Health Sub-Region"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => (
      <div className="font-medium">{row.getValue("name")}</div>
    ),
    enableSorting: true,
    enableHiding: false,
  },
  {
    id: "region_name",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Region"
        canSort={true}
        canFilter={true}
        filterType="text"
        relationField="region.name"
      />
    ),
    accessorFn: (row) => {
      const expandedData = row.expand?.region
      return expandedData?.name || "No Region"
    },
    cell: ({ row, getValue }) => {
      const regionName = getValue() as string
      const expandedData = row.original.expand?.region
      
      if (regionName === "No Region" || !expandedData) {
        return <span className="text-muted-foreground">{regionName}</span>
      }

      return (
        <Button
          variant="link"
          size="sm"
          className="h-auto p-0 text-left justify-start"
          onClick={(e) => {
            e.stopPropagation()
            window.location.href = withDashboardBasePath(`/health-facilities/regions/${expandedData.id}`)
          }}
        >
          {regionName}
          <ExternalLink className="ml-1 h-3 w-3" />
        </Button>
      )
    },
    enableSorting: true,
  },
  {
    accessorKey: "nhpi_code",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="NHPI Code"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
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
      <DataTableColumnHeader
        column={column}
        title="HSDT Code"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
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
        <div className="text-muted-foreground">
          {date.toLocaleDateString()}
        </div>
      )
    },
    enableSorting: true,
  },
]

export type HealthSubRegionType = HealthSubRegionsWithRegion
