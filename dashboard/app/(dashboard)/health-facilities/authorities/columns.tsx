"use client"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { ExternalLink } from "lucide-react"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { ExtendedColumnDef } from "@/types/data-table"
import { AuthoritiesWithOwnershipType } from "@/types/expanded"
import { withDashboardBasePath } from "@/lib/dashboard-path"

export const authoritiesColumns: ExtendedColumnDef<AuthoritiesWithOwnershipType>[] = [
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Authority Name"
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
        filterType="text"
      />
    ),
    cell: ({ row }) => (
      <Badge variant="secondary" className="font-mono text-xs">
        {row.getValue("code")}
      </Badge>
    ),
    enableSorting: true,
  },
  {
    id: "ownership_type_name",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Ownership Type"
        canSort={true}
        canFilter={true}
        filterType="text"
        relationField="ownership_type.name"
      />
    ),
    accessorFn: (row) => {
      const ownershipType = row.expand?.ownership_type
      return ownershipType?.name || "No Ownership Type"
    },
    cell: ({ row }) => {
      const ownershipType = row.original.expand?.ownership_type
      
      if (!ownershipType) {
        return <span className="text-muted-foreground">No Ownership Type</span>
      }
      
      const getVariant = (code: string) => {
        switch (code) {
          case 'GOVT': return 'default'
          case 'PNFP': return 'secondary'
          case 'PFP': return 'outline'
          case 'NGO': return 'destructive'
          case 'FBO': return 'secondary'
          case 'INTL': return 'outline'
          default: return 'default'
        }
      }
      
      return (
        <Button
          variant="link"
          size="sm"
          className="h-auto p-0 text-left justify-start"
          onClick={(e) => {
            e.stopPropagation()
            window.location.href = withDashboardBasePath(`/health-facilities/ownership-types/${ownershipType.id}`)
          }}
        >
          <Badge variant={getVariant(ownershipType.code)} className="text-xs">
            {ownershipType.name}
          </Badge>
          <ExternalLink className="ml-1 h-3 w-3" />
        </Button>
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

export type AuthorityType = AuthoritiesWithOwnershipType
