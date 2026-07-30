"use client"

// import { ColumnDef } from "@tanstack/react-table"
import { Badge } from "@/components/ui/badge"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { ExtendedColumnDef } from "@/types/data-table"
import { FacilityLevelsResponse } from "@/types/backend-types"

export const facilityLevelsColumns: ExtendedColumnDef<FacilityLevelsResponse>[] = [
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Facility Level"
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
    accessorKey: "code",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Code"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={[
          { label: "Hospital", value: "HOSPITAL" },
          { label: "Health Center III", value: "HC_III" },
          { label: "Health Center II", value: "HC_II" },
          { label: "Health Center I", value: "HC_I" }
        ]}
      />
    ),
    cell: ({ row }) => {
      const code = row.getValue("code") as string
      const getVariant = (code: string) => {
        switch (code) {
          case 'HOSPITAL': return 'default'
          case 'HC_III': return 'secondary'
          case 'HC_II': return 'outline'
          case 'HC_I': return 'destructive'
          default: return 'default'
        }
      }
      
      return (
        <Badge variant={getVariant(code)} className="font-mono text-xs">
          {code}
        </Badge>
      )
    },
    enableSorting: true,
  },
  {
    id: "facilities_count",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Facilities" />
    ),
    cell: () => {
      // This would need to be calculated if we want to show facility counts
      return (
        <div className="text-muted-foreground">
          -
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
        <div className="text-muted-foreground">
          {date.toLocaleDateString()}
        </div>
      )
    },
    enableSorting: true,
  },
]

export type FacilityLevelType = FacilityLevelsResponse