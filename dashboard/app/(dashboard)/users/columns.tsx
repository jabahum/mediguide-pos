"use client"

import { format } from "date-fns"
import { CalendarDays, Mail, User, Phone, Building2, Briefcase, FileText, Globe, Clock, MapPin as Location } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { UsersResponse, UsersStatusOptions, UsersPreferredLanguageOptions, ConsultantsSpecialtyOptions } from "@/types/backend-types"
import { ExtendedColumnDef } from "@/types/data-table"

// Use the proper legacy collection API generated type
export type User = UsersResponse

// Role option type for dynamic roles
interface RoleOption {
  label: string
  value: string
}

// Factory function to create columns with dynamic roles
export const createColumns = (roleOptions: RoleOption[] = []): ExtendedColumnDef<User>[] => [
  // 1. Core Identity - User, Email, Phone
  {
    id: "user",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="User"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const user = row.original
      return (
        <div className="flex items-center space-x-3">
          <Avatar className="h-8 w-8">
            <AvatarImage
              src={user.avatar || `/avatars/${user.id}.png`}
              alt={user.name}
            />
            <AvatarFallback>
              {user.name
                .split(' ')
                .map(n => n[0])
                .join('')
                .toUpperCase()
                .slice(0, 2)
              }
            </AvatarFallback>
          </Avatar>
          <div className="flex flex-col">
            <span className="font-medium">{user.name}</span>
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
    accessorKey: "email",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Email"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const email = row.original.email
      return (
        <div className="flex items-center space-x-2">
          <Mail className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm">{email}</span>
        </div>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "phone",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Phone"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const phone = row.original.phone
      if (!phone) return null
      return (
        <div className="flex items-center space-x-2">
          <Phone className="h-3 w-3 text-muted-foreground" />
          <a href={`tel:${phone}`} className="text-sm hover:underline">
            {phone}
          </a>
        </div>
      )
    },
    enableSorting: true,
  },

  // 2. Additional Contact - Alternative Phone, Address, Location Info
  {
    accessorKey: "alternativePhone",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Alt Phone"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const altPhone = row.original.alternativePhone
      if (!altPhone) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <Phone className="h-3 w-3 text-muted-foreground" />
          <a href={`tel:${altPhone}`} className="text-sm hover:underline">
            {altPhone}
          </a>
        </div>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "address",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Address"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const address = row.original.address
      if (!address) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <Location className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm truncate max-w-[150px]" title={address}>
            {address}
          </span>
        </div>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "city",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="City"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const city = row.original.city
      if (!city) return <span className="text-muted-foreground">—</span>
      return <span className="text-sm">{city}</span>
    },
    enableSorting: true,
  },

  {
    accessorKey: "state",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="State"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const state = row.original.state
      if (!state) return <span className="text-muted-foreground">—</span>
      return <span className="text-sm">{state}</span>
    },
    enableSorting: true,
  },

  {
    accessorKey: "country",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Country"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const country = row.original.country
      if (!country) return <span className="text-muted-foreground">—</span>
      return <span className="text-sm">{country}</span>
    },
    enableSorting: true,
  },

  {
    accessorKey: "postalCode",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Postal Code"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const postalCode = row.original.postalCode
      if (!postalCode) return <span className="text-muted-foreground">—</span>
      return <span className="text-sm font-mono">{postalCode}</span>
    },
    enableSorting: true,
  },

  // 3. Professional Information - Role, Organization, Job Title, Department, Specialization
  {
    accessorKey: "role",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Role"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={roleOptions}
      />
    ),
    cell: ({ row }) => {
      const role = row.original.role
      if (!role) return null

      // Get role label from the roleOptions
      const roleOption = roleOptions.find(r => r.value === role)
      const roleLabel = roleOption?.label || role

      // Simple role variant logic based on role keys
      const getRoleVariant = (roleKey: string) => {
        if (roleKey.includes('super_admin') || roleKey.includes('admin')) {
          return 'destructive'
        }
        if (roleKey.includes('manager') || roleKey.includes('content')) {
          return 'secondary'
        }
        if (roleKey.includes('reviewer')) {
          return 'outline'
        }
        if (roleKey.includes('provider') || roleKey.includes('healthcare')) {
          return 'default'
        }
        return 'outline'
      }

      return (
        <Badge variant={getRoleVariant(role)}>
          {roleLabel}
        </Badge>
      )
    },
    enableSorting: true,
    filterFn: (row, _id, value) => {
      const role = row.original.role
      return role === value
    },
  },

  {
    accessorKey: "organization",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Organization"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const organization = row.original.organization
      if (!organization) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <Building2 className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm truncate max-w-[150px]" title={organization}>
            {organization}
          </span>
        </div>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "jobTitle",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Job Title"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const jobTitle = row.original.jobTitle
      if (!jobTitle) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <Briefcase className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm truncate max-w-[120px]" title={jobTitle}>
            {jobTitle}
          </span>
        </div>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "department",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Department"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const department = row.original.department
      if (!department) return <span className="text-muted-foreground">—</span>
      return (
        <span className="text-sm truncate max-w-[120px]" title={department}>
          {department}
        </span>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "specialization",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Specialization"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={Object.values(ConsultantsSpecialtyOptions).map(specialty => ({
          label: specialty,
          value: specialty
        }))}
      />
    ),
    cell: ({ row }) => {
      const specialization = row.original.specialization
      if (!specialization) {
        return <span className="text-muted-foreground">—</span>
      }
      return (
        <Badge variant="outline" className="text-xs">
          {specialization}
        </Badge>
      )
    },
    enableSorting: true,
    filterFn: (row, _id, value) => {
      const specialization = row.original.specialization
      if (!specialization) return false
      return specialization === value
    },
  },

  // 4. Status & Verification
  {
    accessorKey: "status",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Status"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={Object.values(UsersStatusOptions).map(status => ({
          label: status === UsersStatusOptions.pendingActivation ? 'Pending Activation' : status.charAt(0).toUpperCase() + status.slice(1),
          value: status
        }))}
      />
    ),
    cell: ({ row }) => {
      const status = row.original.status

      const getStatusVariant = (status: UsersStatusOptions) => {
        switch (status) {
          case UsersStatusOptions.active:
            return 'default'
          case UsersStatusOptions.inactive:
            return 'secondary'
          case UsersStatusOptions.suspended:
            return 'destructive'
          case UsersStatusOptions.pendingActivation:
            return 'outline'
          default:
            return 'outline'
        }
      }

      return (
        <Badge variant={getStatusVariant(status)}>
          {status === UsersStatusOptions.pendingActivation ? 'Pending Activation' : status.charAt(0).toUpperCase() + status.slice(1)}
        </Badge>
      )
    },
    enableSorting: true,
    filterFn: (row, id, value) => {
      return row.getValue(id) === value
    },
  },

  {
    accessorKey: "verified",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Verified"
        canSort={true}
        canFilter={true}
        filterType="boolean"
      />
    ),
    cell: ({ row }) => {
      const verified = row.original.verified
      return (
        <Badge variant={verified ? 'default' : 'secondary'}>
          {verified ? 'Verified' : 'Unverified'}
        </Badge>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "licenseNumber",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="License #"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const license = row.original.licenseNumber
      if (!license) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <FileText className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm font-mono">{license}</span>
        </div>
      )
    },
    enableSorting: true,
  },

  // 5. System Settings - Language, Timezone, Email Visibility
  {
    accessorKey: "preferredLanguage",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Language"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={Object.values(UsersPreferredLanguageOptions).map(lang => ({
          label: lang,
          value: lang
        }))}
      />
    ),
    cell: ({ row }) => {
      const language = row.original.preferredLanguage
      if (!language) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <Globe className="h-3 w-3 text-muted-foreground" />
          <Badge variant="outline" className="text-xs">
            {language}
          </Badge>
        </div>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "timezone",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Timezone"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const timezone = row.original.timezone
      if (!timezone) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <Clock className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm font-mono">{timezone}</span>
        </div>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "emailVisibility",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Email Visible"
        canSort={true}
        canFilter={true}
        filterType="boolean"
      />
    ),
    cell: ({ row }) => {
      const emailVisibility = row.original.emailVisibility
      return (
        <Badge variant={emailVisibility ? 'default' : 'secondary'}>
          {emailVisibility ? 'Public' : 'Private'}
        </Badge>
      )
    },
    enableSorting: true,
  },

  // 6. Metadata - Notes, Created, Updated
  {
    accessorKey: "notes",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Notes"
        canSort={false}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const notes = row.original.notes
      if (!notes) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <FileText className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm truncate max-w-[100px]" title={notes}>
            {notes.length > 50 ? `${notes.substring(0, 47)}...` : notes}
          </span>
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

// Helper function to get user initials
export function getUserInitials(name: string): string {
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

// Helper function to get user role badge variant (using dynamic role keys)
export function getRoleBadgeVariant(roleKey?: string): "default" | "secondary" | "outline" | "destructive" {
  if (!roleKey) return "outline"

  // Use string matching for role variants
  if (roleKey.includes('super_admin') || roleKey.includes('admin')) {
    return 'destructive'
  }
  if (roleKey.includes('manager') || roleKey.includes('content')) {
    return 'secondary'
  }
  if (roleKey.includes('reviewer')) {
    return 'outline'
  }
  if (roleKey.includes('provider') || roleKey.includes('healthcare')) {
    return 'default'
  }
  return 'outline'
}

// Helper function to get status badge variant
export function getStatusBadgeVariant(status: UsersStatusOptions): "default" | "secondary" | "outline" | "destructive" {
  switch (status) {
    case UsersStatusOptions.active:
      return 'default'
    case UsersStatusOptions.inactive:
      return 'secondary'
    case UsersStatusOptions.suspended:
      return 'destructive'
    case UsersStatusOptions.pendingActivation:
      return 'outline'
    default:
      return 'outline'
  }
}