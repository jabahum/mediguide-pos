"use client"

import { format } from "date-fns"
import { CalendarDays, Shield, MapPin, Hash, Stethoscope } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { HealthFacilitiesResponse, FacilityLevelsResponse, AuthoritiesResponse, OwnershipTypesResponse, RegionsResponse, DistrictsResponse, CountiesResponse, SubcountiesResponse, ParishesResponse } from "@/types/backend-types"
import { ExtendedColumnDef } from "@/types/data-table"

// Use the proper legacy collection API generated type
export type HealthFacility = HealthFacilitiesResponse<{
  facility_level: FacilityLevelsResponse
  authority: AuthoritiesResponse
  ownership_type: OwnershipTypesResponse
  region: RegionsResponse
  district: DistrictsResponse
  county: CountiesResponse
  subcounty: SubcountiesResponse
  parish: ParishesResponse
}>

// Factory function to create columns
export const createColumns = (): ExtendedColumnDef<HealthFacility>[] => [
  // 1. Core Identity - Name, Codes
  {
    id: "facility",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Facility"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const facility = row.original
      return (
        <div className="flex flex-col space-y-1">
          <span className="font-medium text-sm">{facility.name}</span>
          <div className="flex items-center space-x-2 text-xs text-muted-foreground">
            <span className="font-mono">{facility.nhpi_code}</span>
          </div>
        </div>
      )
    },
    enableSorting: true,
    sortingFn: (rowA, rowB) => {
      return rowA.original.name.localeCompare(rowB.original.name)
    },
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
    cell: ({ row }) => {
      const hsdt = row.original.hsdt_code
      return (
        <div className="flex items-center space-x-2">
          <Hash className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm font-mono">{hsdt}</span>
        </div>
      )
    },
    enableSorting: true,
  },

  // 2. Classification - Level, Authority, Ownership
  {
    id: "facility_level",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Level"
        canSort={true}
        canFilter={true}
        filterType="select"
      />
    ),
    cell: ({ row }) => {
      const level = row.original.expand?.facility_level
      if (!level) return <span className="text-muted-foreground">—</span>

      const getLevelVariant = (code: string) => {
        if (code.includes('Hospital')) return 'destructive'
        if (code.includes('HC IV')) return 'default'
        if (code.includes('HC III')) return 'secondary'
        if (code.includes('HC II')) return 'outline'
        return 'outline'
      }

      return (
        <div className="flex items-center space-x-2">
          <Stethoscope className="h-3 w-3 text-muted-foreground" />
          <Badge variant={getLevelVariant(level.code)}>
            {level.name}
          </Badge>
        </div>
      )
    },
    enableSorting: true,
    filterFn: (row, _id, value) => {
      const level = row.original.expand?.facility_level
      return level?.name === value
    },
  },

  {
    id: "authority",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Authority"
        canSort={true}
        canFilter={true}
        filterType="select"
      />
    ),
    cell: ({ row }) => {
      const authority = row.original.expand?.authority
      if (!authority) return <span className="text-muted-foreground">—</span>

      const getAuthorityVariant = (name: string) => {
        if (name.includes('MOH')) return 'default'
        if (name.includes('UPDF')) return 'destructive'
        if (name.includes('Private')) return 'secondary'
        if (name.includes('UNHCR')) return 'outline'
        return 'outline'
      }

      return (
        <div className="flex items-center space-x-2">
          <Shield className="h-3 w-3 text-muted-foreground" />
          <Badge variant={getAuthorityVariant(authority.name)}>
            {authority.name}
          </Badge>
        </div>
      )
    },
    enableSorting: true,
    filterFn: (row, _id, value) => {
      const authority = row.original.expand?.authority
      return authority?.name === value
    },
  },

  {
    id: "ownership_type",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Ownership"
        canSort={true}
        canFilter={true}
        filterType="select"
      />
    ),
    cell: ({ row }) => {
      const ownership = row.original.expand?.ownership_type
      if (!ownership) return <span className="text-muted-foreground">—</span>

      const getOwnershipVariant = (code: string) => {
        if (code === 'Govt') return 'default'
        if (code === 'PNFP') return 'secondary'
        if (code === 'PFP') return 'outline'
        return 'outline'
      }

      return (
        <Badge variant={getOwnershipVariant(ownership.code)}>
          {ownership.name}
        </Badge>
      )
    },
    enableSorting: true,
    filterFn: (row, _id, value) => {
      const ownership = row.original.expand?.ownership_type
      return ownership?.name === value
    },
  },

  // 3. Location Hierarchy - Region, District, County, Subcounty, Parish
  {
    id: "location",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Location"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const { expand } = row.original
      if (!expand) return <span className="text-muted-foreground">—</span>

      // Build the location hierarchy display
      const region = expand.region?.name || ''
      const district = expand.district?.name || ''
      const subcounty = expand.subcounty?.name || ''
      const parish = expand.parish?.name || ''

      return (
        <div className="flex flex-col space-y-1">
          <div className="flex items-center space-x-1 text-sm">
            <MapPin className="h-3 w-3 text-muted-foreground" />
            <span className="font-medium">{district}</span>
            {region && (
              <>
                <span className="text-muted-foreground">·</span>
                <span className="text-muted-foreground text-xs">{region}</span>
              </>
            )}
          </div>
          {(subcounty || parish) && (
            <div className="text-xs text-muted-foreground pl-4">
              {subcounty && <span>{subcounty}</span>}
              {subcounty && parish && <span> → </span>}
              {parish && <span>{parish}</span>}
            </div>
          )}
        </div>
      )
    },
    enableSorting: true,
    sortingFn: (rowA, rowB) => {
      const districtA = rowA.original.expand?.district?.name || ''
      const districtB = rowB.original.expand?.district?.name || ''
      return districtA.localeCompare(districtB)
    },
  },

  // 4. Individual Location Columns (hidden by default)
  {
    id: "region",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Region"
        canSort={true}
        canFilter={true}
        filterType="select"
      />
    ),
    cell: ({ row }) => {
      const region = row.original.expand?.region
      if (!region) return <span className="text-muted-foreground">—</span>
      return <span className="text-sm">{region.name}</span>
    },
    enableSorting: true,
    filterFn: (row, _id, value) => {
      const region = row.original.expand?.region
      return region?.name === value
    },
  },

  {
    id: "district",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="District"
        canSort={true}
        canFilter={true}
        filterType="select"
      />
    ),
    cell: ({ row }) => {
      const district = row.original.expand?.district
      if (!district) return <span className="text-muted-foreground">—</span>
      return <span className="text-sm">{district.name}</span>
    },
    enableSorting: true,
    filterFn: (row, _id, value) => {
      const district = row.original.expand?.district
      return district?.name === value
    },
  },

  {
    id: "county",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="County"
        canSort={true}
        canFilter={true}
        filterType="select"
      />
    ),
    cell: ({ row }) => {
      const county = row.original.expand?.county
      if (!county) return <span className="text-muted-foreground">—</span>
      return <span className="text-sm">{county.name}</span>
    },
    enableSorting: true,
    filterFn: (row, _id, value) => {
      const county = row.original.expand?.county
      return county?.name === value
    },
  },

  {
    id: "subcounty",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Subcounty"
        canSort={true}
        canFilter={true}
        filterType="select"
      />
    ),
    cell: ({ row }) => {
      const subcounty = row.original.expand?.subcounty
      if (!subcounty) return <span className="text-muted-foreground">—</span>
      return <span className="text-sm">{subcounty.name}</span>
    },
    enableSorting: true,
    filterFn: (row, _id, value) => {
      const subcounty = row.original.expand?.subcounty
      return subcounty?.name === value
    },
  },

  {
    id: "parish",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Parish"
        canSort={true}
        canFilter={true}
        filterType="select"
      />
    ),
    cell: ({ row }) => {
      const parish = row.original.expand?.parish
      if (!parish) return <span className="text-muted-foreground">—</span>
      return <span className="text-sm">{parish.name}</span>
    },
    enableSorting: true,
    filterFn: (row, _id, value) => {
      const parish = row.original.expand?.parish
      return parish?.name === value
    },
  },

  // 5. Metadata - Created, Updated
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
      const created = row.original.created
      try {
        const date = new Date(created)
        return (
          <div className="flex items-center space-x-1 text-sm">
            <CalendarDays className="h-3 w-3 text-muted-foreground" />
            <span title={format(date, 'PPpp')}>
              {format(date, 'MMM dd, yyyy')}
            </span>
          </div>
        )
      } catch {
        return <span className="text-muted-foreground">Invalid date</span>
      }
    },
    enableSorting: true,
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
      const updated = row.original.updated
      try {
        const date = new Date(updated)
        return (
          <div className="flex items-center space-x-1 text-sm">
            <CalendarDays className="h-3 w-3 text-muted-foreground" />
            <span title={format(date, 'PPpp')}>
              {format(date, 'MMM dd, yyyy')}
            </span>
          </div>
        )
      } catch {
        return <span className="text-muted-foreground">Invalid date</span>
      }
    },
    enableSorting: true,
  },
]

// Default columns export (for backward compatibility)
export const columns = createColumns()

// Helper function to get facility level badge variant
export function getFacilityLevelBadgeVariant(code?: string): "default" | "secondary" | "outline" | "destructive" {
  if (!code) return "outline"

  if (code.includes('Hospital')) return 'destructive'
  if (code.includes('HC IV')) return 'default'
  if (code.includes('HC III')) return 'secondary'
  if (code.includes('HC II')) return 'outline'
  return 'outline'
}

// Helper function to get authority badge variant
export function getAuthorityBadgeVariant(name?: string): "default" | "secondary" | "outline" | "destructive" {
  if (!name) return "outline"

  if (name.includes('MOH')) return 'default'
  if (name.includes('UPDF')) return 'destructive'
  if (name.includes('Private')) return 'secondary'
  if (name.includes('UNHCR')) return 'outline'
  return 'outline'
}

// Helper function to get ownership badge variant
export function getOwnershipBadgeVariant(code?: string): "default" | "secondary" | "outline" | "destructive" {
  if (!code) return "outline"

  if (code === 'Govt') return 'default'
  if (code === 'PNFP') return 'secondary'
  if (code === 'PFP') return 'outline'
  return 'outline'
}