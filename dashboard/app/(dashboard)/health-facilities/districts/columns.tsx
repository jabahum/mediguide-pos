"use client"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { ExternalLink } from "lucide-react"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { DistrictsWithExpanded } from "@/types/expanded"
import { ExtendedColumnDef } from "@/types/data-table"
import { withDashboardBasePath } from "@/lib/dashboard-path"

export const districtsColumns: ExtendedColumnDef<DistrictsWithExpanded>[] = [
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader 
        column={column} 
        title="District Name"
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
      const region = row.expand?.region
      return region?.name || "No Region"
    },
    cell: ({ row }) => {
      const region = row.original.expand?.region
      
      if (!region) {
        return <span className="text-muted-foreground">No Region</span>
      }
      
      return (
        <Button
          variant="link"
          size="sm"
          className="h-auto p-0 text-left justify-start"
          onClick={(e) => {
            e.stopPropagation()
            window.location.href = withDashboardBasePath(`/health-facilities/regions/${region.id}`)
          }}
        >
          {region.name}
          <ExternalLink className="ml-1 h-3 w-3" />
        </Button>
      )
    },
    enableSorting: true,
  },
  {
    id: "health_sub_region_name",
    header: ({ column }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Health Sub-Region"
        canSort={true}
        canFilter={true}
        filterType="text"
        relationField="health_sub_region.name"
      />
    ),
    accessorFn: (row) => {
      const hsr = row.expand?.health_sub_region
      return hsr?.name || "No HSR"
    },
    cell: ({ row }) => {
      const hsr = row.original.expand?.health_sub_region
      
      if (!hsr) {
        return <span className="text-muted-foreground">No HSR</span>
      }
      
      return (
        <Button
          variant="link"
          size="sm"
          className="h-auto p-0 text-left justify-start"
          onClick={(e) => {
            e.stopPropagation()
            window.location.href = withDashboardBasePath(`/health-facilities/health-sub-regions/${hsr.id}`)
          }}
        >
          {hsr.name}
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

export type DistrictType = DistrictsWithExpanded
