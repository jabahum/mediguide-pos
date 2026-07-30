"use client"

import { format } from "date-fns"
import { 
  CalendarDays, 
  Mail, 
  Phone, 
  Building2, 
  MapPin, 
  Star, 
  Award, 
  Clock,
  FileText,
  Globe
} from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { ExtendedColumnDef } from "@/types/data-table"

// Define Consultant type based on our legacy collection API schema
export interface Consultant {
  [key: string]: unknown
  id: string
  name: string
  email: string
  phone: string
  alternativePhone?: string
  profilePicture?: string
  avatar?: string
  specialty: string
  licenseNumber?: string
  yearsOfExperience?: number
  qualifications?: string[]
  certifications?: string
  address?: string
  city?: string
  region?: string
  country: string
  postalCode?: string
  organization?: string
  department?: string
  preferredLanguage?: string
  timezone?: string
  availability?: Record<string, unknown>
  consultationTypes?: string[]
  status: 'active' | 'inactive' | 'pending_approval' | 'suspended'
  isVerified?: boolean
  rating?: number
  totalConsultations?: number
  notes?: string
  created: string
  updated: string
}

// Specialty options for filtering
export const SpecialtyOptions = [
  "General Practice",
  "Internal Medicine", 
  "Pediatrics",
  "Surgery",
  "Cardiology",
  "Neurology",
  "Psychiatry",
  "Orthopedics",
  "Dermatology",
  "Obstetrics & Gynecology",
  "Ophthalmology",
  "Emergency Medicine",
  "Radiology",
  "Anesthesiology",
  "Pathology",
  "Oncology",
  "Endocrinology",
  "Gastroenterology",
  "Pulmonology",
  "Nephrology",
  "Infectious Diseases",
  "Rheumatology",
  "Public Health",
  "Nursing",
  "Pharmacy",
  "Laboratory Medicine",
  "Other"
]

// Status options for filtering
export const StatusOptions = [
  { label: "Active", value: "active" },
  { label: "Inactive", value: "inactive" },
  { label: "Pending Approval", value: "pending_approval" },
  { label: "Suspended", value: "suspended" }
]

// Factory function to create columns
export const createColumns = (): ExtendedColumnDef<Consultant>[] => [
  // 1. Core Identity - Consultant Profile
  {
    id: "consultant",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Consultant"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const consultant = row.original
      return (
        <div className="flex items-center space-x-3">
          <Avatar className="h-8 w-8">
            <AvatarImage
              src={consultant.profilePicture || consultant.avatar || `/avatars/${consultant.id}.png`}
              alt={consultant.name}
            />
            <AvatarFallback>
              {consultant.name
                .split(' ')
                .map(n => n[0])
                .join('')
                .toUpperCase()
                .slice(0, 2)
              }
            </AvatarFallback>
          </Avatar>
          <div className="flex flex-col">
            <span className="font-medium">{consultant.name}</span>
            <span className="text-sm text-muted-foreground">{consultant.specialty}</span>
          </div>
        </div>
      )
    },
    enableSorting: true,
    sortingFn: (rowA, rowB) => {
      return rowA.original.name.localeCompare(rowB.original.name)
    },
  },

  // 2. Contact Information
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

  // 3. Specialty & Professional Info
  {
    accessorKey: "specialty",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Specialty"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={SpecialtyOptions.map(specialty => ({
          label: specialty,
          value: specialty
        }))}
      />
    ),
    cell: ({ row }) => {
      const specialty = row.original.specialty
      return (
        <Badge variant="outline" className="text-xs">
          {specialty}
        </Badge>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "yearsOfExperience",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Experience"
        canSort={true}
        canFilter={true}
        filterType="numberRange"
      />
    ),
    cell: ({ row }) => {
      const years = row.original.yearsOfExperience
      if (!years) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <Clock className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm">{years} years</span>
        </div>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "qualifications",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Qualifications"
        canSort={false}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const qualifications = row.original.qualifications
      if (!qualifications || qualifications.length === 0) {
        return <span className="text-muted-foreground">—</span>
      }
      return (
        <div className="flex flex-wrap gap-1">
          {qualifications.slice(0, 2).map((qual, index) => (
            <Badge key={index} variant="secondary" className="text-xs">
              {qual}
            </Badge>
          ))}
          {qualifications.length > 2 && (
            <Badge variant="outline" className="text-xs">
              +{qualifications.length - 2}
            </Badge>
          )}
        </div>
      )
    },
    enableSorting: false,
  },

  // 4. Location & Organization
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
      const { city, region, country } = row.original
      const location = [city, region, country].filter(Boolean).join(', ')
      if (!location) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <MapPin className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm truncate max-w-[150px]" title={location}>
            {location}
          </span>
        </div>
      )
    },
    enableSorting: true,
    sortingFn: (rowA, rowB) => {
      const locationA = [rowA.original.city, rowA.original.region, rowA.original.country].filter(Boolean).join(', ')
      const locationB = [rowB.original.city, rowB.original.region, rowB.original.country].filter(Boolean).join(', ')
      return locationA.localeCompare(locationB)
    },
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

  // 5. Performance & Verification
  {
    accessorKey: "rating",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Rating"
        canSort={true}
        canFilter={true}
        filterType="numberRange"
      />
    ),
    cell: ({ row }) => {
      const rating = row.original.rating
      const totalConsultations = row.original.totalConsultations
      if (!rating) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <Star className="h-3 w-3 text-yellow-500" />
          <span className="text-sm">{rating.toFixed(1)}</span>
          {totalConsultations && (
            <span className="text-xs text-muted-foreground">({totalConsultations})</span>
          )}
        </div>
      )
    },
    enableSorting: true,
  },

  {
    accessorKey: "isVerified",
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
      const verified = row.original.isVerified
      return (
        <Badge variant={verified ? 'default' : 'secondary'} className="text-xs">
          {verified ? 'Verified' : 'Unverified'}
        </Badge>
      )
    },
    enableSorting: true,
  },

  // 6. Status & System Fields
  {
    accessorKey: "status",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Status"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={StatusOptions}
      />
    ),
    cell: ({ row }) => {
      const status = row.original.status

      const getStatusVariant = (status: string) => {
        switch (status) {
          case 'active':
            return 'default'
          case 'inactive':
            return 'secondary'
          case 'suspended':
            return 'destructive'
          case 'pending_approval':
            return 'outline'
          default:
            return 'outline'
        }
      }

      const getStatusLabel = (status: string) => {
        switch (status) {
          case 'pending_approval':
            return 'Pending Approval'
          default:
            return status.charAt(0).toUpperCase() + status.slice(1)
        }
      }

      return (
        <Badge variant={getStatusVariant(status)}>
          {getStatusLabel(status)}
        </Badge>
      )
    },
    enableSorting: true,
    filterFn: (row, id, value) => {
      return row.getValue(id) === value
    },
  },

  {
    accessorKey: "preferredLanguage",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Language"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={[
          { label: "English", value: "English" },
          { label: "French", value: "French" },
          { label: "Spanish", value: "Spanish" },
          { label: "Portuguese", value: "Portuguese" },
          { label: "Arabic", value: "Arabic" },
          { label: "Swahili", value: "Swahili" },
          { label: "Amharic", value: "Amharic" },
          { label: "Other", value: "Other" }
        ]}
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
          <Award className="h-3 w-3 text-muted-foreground" />
          <span className="text-sm font-mono">{license}</span>
        </div>
      )
    },
    enableSorting: true,
  },

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

  // 7. Timestamps
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
        filterType="dateRange"
      />
    ),
    cell: ({ row }) => {
      const updated = row.original.updated
      if (!updated) return <span className="text-muted-foreground">—</span>
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

// Helper function to get consultant initials
export function getConsultantInitials(name: string): string {
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

// Helper function to get status badge variant
export function getStatusBadgeVariant(status: string): "default" | "secondary" | "outline" | "destructive" {
  switch (status) {
    case 'active':
      return 'default'
    case 'inactive':
      return 'secondary'
    case 'suspended':
      return 'destructive'
    case 'pending_approval':
      return 'outline'
    default:
      return 'outline'
  }
}

// Helper function to format location
export function formatLocation(city?: string, region?: string, country?: string): string {
  return [city, region, country].filter(Boolean).join(', ')
}