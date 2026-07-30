"use client"

import * as React from "react"
import { Badge } from "@/components/ui/badge"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { DrugsResponse, DrugCategoriesResponse, DrugTagsResponse, DrugClassesResponse, TherapeuticCategoriesResponse } from "@/types/backend-types"
import { ExtendedColumnDef } from "@/types/data-table"

// Define the expanded drug type with relations based on actual database structure  
export type DrugWithRelations = DrugsResponse<{
  categories: DrugCategoriesResponse[]
  tags: DrugTagsResponse[]
  drug_class: DrugClassesResponse
  therapeutic_category: TherapeuticCategoriesResponse
}>

export const columns: ExtendedColumnDef<DrugWithRelations>[] = [
  // ESSENTIAL COLUMNS (Always Visible)
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Drug Name"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const name = row.getValue("name") as string
      return (
        <div className="font-medium">{name}</div>
      )
    },
  },
  {
    id: "drug_class_name",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Drug Class"
        canSort={true}
        canFilter={true}
        filterType="text"
        relationField="drug_class.name"
      />
    ),
    accessorFn: (row) => {
      const drugClass = row.expand?.drug_class
      return drugClass?.name || ""
    },
    cell: ({ row }) => {
      const drugClass = row.original.expand?.drug_class
      return drugClass ? (
        <span className="text-sm">{drugClass.name}</span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
    enableSorting: true,
    filterFn: "includesString",
  },
  {
    accessorKey: "categories",
    header: "Categories",
    cell: ({ row }) => {
      const categories = row.original.expand?.categories

      if (!Array.isArray(categories) || categories.length === 0) {
        return <span className="text-muted-foreground">—</span>
      }

      return (
        <Popover>
          <PopoverTrigger className="cursor-pointer">
            {categories.length} {categories.length === 1 ? 'category' : 'categories'}
          </PopoverTrigger>
          <PopoverContent className="w-60" align="start">
            <ul className="space-y-1 list-disc list-inside">
              {categories.map((category) => (
                <li key={category.id} className="text-sm">
                  {category.name}
                </li>
              ))}
            </ul>
          </PopoverContent>
        </Popover>
      )
    },
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
          { label: "Active", value: "active" },
          { label: "Inactive", value: "inactive" },
          { label: "Under Review", value: "under_review" },
          { label: "Archived", value: "archived" }
        ]}
      />
    ),
    cell: ({ row }) => {
      const status = row.getValue("status") as string
      const getStatusVariant = (status: string) => {
        switch (status) {
          case "active": return "default"
          case "inactive": return "secondary"
          case "under_review": return "outline"
          case "archived": return "destructive"
          default: return "secondary"
        }
      }

      return (
        <Badge variant={getStatusVariant(status) as "default" | "secondary" | "destructive" | "outline"}>
          {status?.replace("_", " ").replace(/\b\w/g, l => l.toUpperCase())}
        </Badge>
      )
    },
  },

  // BASIC INFORMATION (Hidden by default)
  {
    accessorKey: "brand_names",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Brand Names"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const brands = row.getValue("brand_names") as string
      return brands ? (
        <span className="text-sm">{brands}</span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "description",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Description" />
    ),
    cell: ({ row }) => {
      const desc = row.getValue("description") as string
      return desc ? (
        <div className="max-w-xs truncate text-sm" title={desc}>
          {desc.replace(/<[^>]*>/g, '')}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "therapeutic_category",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Therapeutic Category" />
    ),
    cell: ({ row }) => {
      const category = row.original.expand?.therapeutic_category
      return category ? (
        <Badge variant="secondary">{category.name}</Badge>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "tags",
    defaultVisible: false,
    header: "Tags",
    cell: ({ row }) => {
      const tags = row.original.expand?.tags

      if (!Array.isArray(tags) || tags.length === 0) {
        return <span className="text-muted-foreground">—</span>
      }

      return (
        <Popover>
          <PopoverTrigger className="cursor-pointer">
            {tags.length} {tags.length === 1 ? 'tag' : 'tags'}
          </PopoverTrigger>
          <PopoverContent className="w-60" align="start">
            <ul className="space-y-1 list-disc list-inside">
              {tags.map((tag) => (
                <li key={tag.id} className="text-sm">
                  {tag.name}
                </li>
              ))}
            </ul>
          </PopoverContent>
        </Popover>
      )
    },
  },

  // CLINICAL INFORMATION (Hidden by default)
  {
    accessorKey: "indications",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Indications" />
    ),
    cell: ({ row }) => {
      const indications = row.getValue("indications") as string
      return indications ? (
        <div className="max-w-xs truncate text-sm" title={indications}>
          {indications.replace(/<[^>]*>/g, '')}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "contraindications",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Contraindications" />
    ),
    cell: ({ row }) => {
      const contra = row.getValue("contraindications") as string
      return contra ? (
        <div className="max-w-xs truncate text-sm" title={contra}>
          {contra.replace(/<[^>]*>/g, '')}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "side_effects",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Side Effects" />
    ),
    cell: ({ row }) => {
      const effects = row.getValue("side_effects") as string
      return effects ? (
        <div className="max-w-xs truncate text-sm" title={effects}>
          {effects.replace(/<[^>]*>/g, '')}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "warnings",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Warnings" />
    ),
    cell: ({ row }) => {
      const warnings = row.getValue("warnings") as string
      return warnings ? (
        <div className="max-w-xs truncate text-sm" title={warnings}>
          {warnings.replace(/<[^>]*>/g, '')}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "mechanism_of_action",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Mechanism of Action" />
    ),
    cell: ({ row }) => {
      const mechanism = row.getValue("mechanism_of_action") as string
      return mechanism ? (
        <div className="max-w-xs truncate text-sm" title={mechanism}>
          {mechanism.replace(/<[^>]*>/g, '')}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },

  // DOSING INFORMATION (Hidden by default)
  {
    accessorKey: "adult_dose",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Adult Dose" />
    ),
    cell: ({ row }) => {
      const dose = row.getValue("adult_dose") as string
      return dose ? (
        <span className="font-mono text-xs">{dose}</span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "pediatric_dose",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Pediatric Dose" />
    ),
    cell: ({ row }) => {
      const dose = row.getValue("pediatric_dose") as string
      return dose ? (
        <span className="font-mono text-xs">{dose}</span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "elderly_dose",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Elderly Dose" />
    ),
    cell: ({ row }) => {
      const dose = row.getValue("elderly_dose") as string
      return dose ? (
        <span className="font-mono text-xs">{dose}</span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "max_daily_dose",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Max Daily Dose" />
    ),
    cell: ({ row }) => {
      const dose = row.getValue("max_daily_dose") as string
      return dose ? (
        <span className="font-mono text-xs">{dose}</span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "frequency",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Frequency" />
    ),
    cell: ({ row }) => {
      const freq = row.getValue("frequency") as string
      return freq ? (
        <span className="text-sm">{freq}</span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "duration",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Duration" />
    ),
    cell: ({ row }) => {
      const duration = row.getValue("duration") as string
      return duration ? (
        <span className="text-sm">{duration}</span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "route_of_administration",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Route"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={[
          { label: "Oral", value: "oral" },
          { label: "Intravenous", value: "intravenous" },
          { label: "Intramuscular", value: "intramuscular" },
          { label: "Subcutaneous", value: "subcutaneous" },
          { label: "Topical", value: "topical" },
          { label: "Inhalation", value: "inhalation" },
          { label: "Sublingual", value: "sublingual" },
          { label: "Rectal", value: "rectal" },
          { label: "Ophthalmic", value: "ophthalmic" },
          { label: "Otic", value: "otic" }
        ]}
      />
    ),
    cell: ({ row }) => {
      const route = row.getValue("route_of_administration") as string
      return route ? (
        <Badge variant="outline">{route}</Badge>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },

  // SAFETY & REGULATORY (Hidden by default)
  {
    accessorKey: "pregnancy_category",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Pregnancy Category"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={[
          { label: "Category A", value: "A" },
          { label: "Category B", value: "B" },
          { label: "Category C", value: "C" },
          { label: "Category D", value: "D" },
          { label: "Category X", value: "X" },
          { label: "Unknown", value: "Unknown" }
        ]}
      />
    ),
    cell: ({ row }) => {
      const category = row.getValue("pregnancy_category") as string
      if (!category || category === "Unknown") {
        return <span className="text-muted-foreground">—</span>
      }

      const getVariant = (cat: string) => {
        switch (cat) {
          case "A": return "default"
          case "B": return "secondary"
          case "C": return "outline"
          case "D": return "destructive"
          case "X": return "destructive"
          default: return "outline"
        }
      }

      return (
        <Badge variant={getVariant(category) as "default" | "secondary" | "destructive" | "outline"}>
          Category {category}
        </Badge>
      )
    },
  },
  {
    accessorKey: "controlled_substance",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Controlled Substance" />
    ),
    cell: ({ row }) => {
      const controlled = row.getValue("controlled_substance") as string
      return controlled && controlled !== "None" ? (
        <Badge variant="destructive">
          {controlled}
        </Badge>
      ) : (
        <span className="text-muted-foreground">None</span>
      )
    },
  },
  {
    accessorKey: "special_status",
    defaultVisible: false,
    header: "Special Status",
    cell: ({ row }) => {
      const drug = row.original
      const badges = []

      if (drug.who_eml_status) {
        badges.push(
          <Badge key="eml" variant="secondary">
            WHO EML
          </Badge>
        )
      }

      if (drug.antimicrobial_status) {
        badges.push(
          <Badge key="antimicrobial" variant="destructive">
            Antimicrobial
          </Badge>
        )
      }

      return (
        <div className="flex flex-wrap gap-1">
          {badges.length > 0 ? badges : <span className="text-muted-foreground">—</span>}
        </div>
      )
    },
  },

  // MONITORING & NOTES (Hidden by default)
  {
    accessorKey: "monitoring_parameters",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Monitoring" />
    ),
    cell: ({ row }) => {
      const monitoring = row.getValue("monitoring_parameters") as string
      return monitoring ? (
        <div className="max-w-xs truncate text-sm" title={monitoring}>
          {monitoring}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "clinical_notes",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Clinical Notes" />
    ),
    cell: ({ row }) => {
      const notes = row.getValue("clinical_notes") as string
      return notes ? (
        <div className="max-w-xs truncate text-sm" title={notes}>
          {notes.replace(/<[^>]*>/g, '')}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },

  // ADMINISTRATIVE (Hidden by default)
  {
    accessorKey: "review_status",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Review Status" />
    ),
    cell: ({ row }) => {
      const status = row.getValue("review_status") as string
      const getReviewVariant = (status: string) => {
        switch (status) {
          case "approved": return "default"
          case "pending": return "outline"
          case "needs_update": return "secondary"
          default: return "secondary"
        }
      }

      return (
        <Badge variant={getReviewVariant(status) as "default" | "secondary" | "destructive" | "outline"}>
          {status?.replace("_", " ").replace(/\b\w/g, l => l.toUpperCase())}
        </Badge>
      )
    },
  },
  {
    accessorKey: "references",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="References" />
    ),
    cell: ({ row }) => {
      const refs = row.getValue("references") as string
      return refs ? (
        <div className="max-w-xs truncate text-sm" title={refs}>
          {refs.replace(/<[^>]*>/g, '')}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "search_keywords",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Search Keywords" />
    ),
    cell: ({ row }) => {
      const keywords = row.getValue("search_keywords") as string
      return keywords ? (
        <div className="max-w-xs truncate text-sm text-muted-foreground" title={keywords}>
          {keywords}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },

  // TIMESTAMPS (Hidden by default)
  {
    accessorKey: "created",
    defaultVisible: false,
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
      const date = row.getValue("created") as string
      return date ? (
        <span className="text-xs text-muted-foreground">
          {new Date(date).toLocaleDateString()}
        </span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "updated",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Last Updated" />
    ),
    cell: ({ row }) => {
      const date = row.getValue("updated") as string
      return date ? (
        <span className="text-xs text-muted-foreground">
          {new Date(date).toLocaleDateString()}
        </span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
]

// Expanded type with parent relation for categories
export type CategoryWithRelations = DrugCategoriesResponse<{
  parent_category: DrugCategoriesResponse
}>

// Column definitions for categories
export const categoryColumns: ExtendedColumnDef<CategoryWithRelations>[] = [
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Category Name" />
    ),
    cell: ({ row }) => {
      const category = row.original
      return (
        <div className="flex items-center gap-2">
          <div className="font-medium">{category.name}</div>
        </div>
      )
    },
  },
  {
    accessorKey: "parent_category",
    header: "Parent Category",
    cell: ({ row }) => {
      const parent = row.original.parent_category && typeof row.original.parent_category === 'object'
        ? (row.original.parent_category as unknown as DrugCategoriesResponse)
        : null
      return parent ? (
        <Badge variant="outline">{parent.name}</Badge>
      ) : (
        <span className="text-muted-foreground">Root</span>
      )
    },
  },
  {
    accessorKey: "color",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Color" />
    ),
    cell: ({ row }) => {
      const color = row.getValue("color") as string
      return color ? (
        <div className="flex items-center gap-2">
          <div
            className="w-4 h-4 rounded border"
            style={{ backgroundColor: color }}
          />
          <span className="text-xs font-mono">{color}</span>
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "sort_order",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Order" />
    ),
    cell: ({ row }) => {
      const order = row.getValue("sort_order") as number
      return (
        <span className="text-sm">{order || 0}</span>
      )
    },
  },
  {
    accessorKey: "status",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Status" />
    ),
    cell: ({ row }) => {
      const status = row.getValue("status") as string
      return (
        <Badge variant={status === "active" ? "default" : "secondary"}>
          {status}
        </Badge>
      )
    },
  },
  {
    accessorKey: "description",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Description" />
    ),
    cell: ({ row }) => {
      const desc = row.getValue("description") as string
      return desc ? (
        <div className="max-w-xs truncate text-sm" title={desc}>
          {desc}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "icon",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Icon" />
    ),
    cell: ({ row }) => {
      const icon = row.getValue("icon") as string
      return icon ? (
        <span className="text-sm">{icon}</span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "created",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Created" />
    ),
    cell: ({ row }) => {
      const date = row.getValue("created") as string
      return date ? (
        <span className="text-xs text-muted-foreground">
          {new Date(date).toLocaleDateString()}
        </span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "updated",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Updated" />
    ),
    cell: ({ row }) => {
      const date = row.getValue("updated") as string
      return date ? (
        <span className="text-xs text-muted-foreground">
          {new Date(date).toLocaleDateString()}
        </span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
]

// Column definitions for tags
export const tagColumns: ExtendedColumnDef<DrugTagsResponse>[] = [
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Tag Name" />
    ),
    cell: ({ row }) => {
      const tag = row.original
      return (
        <div className="flex items-center gap-2">
          <div className="font-medium">{tag.name}</div>
        </div>
      )
    },
  },
  {
    accessorKey: "tag_category",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Category" />
    ),
    cell: ({ row }) => {
      const category = row.getValue("tag_category") as string
      return category ? (
        <Badge variant="outline">{category}</Badge>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "color",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Color" />
    ),
    cell: ({ row }) => {
      const color = row.getValue("color") as string
      return color ? (
        <div className="flex items-center gap-2">
          <div
            className="w-4 h-4 rounded border"
            style={{ backgroundColor: color }}
          />
          <span className="text-xs font-mono">{color}</span>
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "sort_order",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Order" />
    ),
    cell: ({ row }) => {
      const order = row.getValue("sort_order") as number
      return (
        <span className="text-sm">{order || 0}</span>
      )
    },
  },
  {
    accessorKey: "status",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Status" />
    ),
    cell: ({ row }) => {
      const status = row.getValue("status") as string
      return (
        <Badge variant={status === "active" ? "default" : "secondary"}>
          {status}
        </Badge>
      )
    },
  },
  {
    accessorKey: "description",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Description" />
    ),
    cell: ({ row }) => {
      const desc = row.getValue("description") as string
      return desc ? (
        <div className="max-w-xs truncate text-sm" title={desc}>
          {desc}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "created",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Created" />
    ),
    cell: ({ row }) => {
      const date = row.getValue("created") as string
      return date ? (
        <span className="text-xs text-muted-foreground">
          {new Date(date).toLocaleDateString()}
        </span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
  {
    accessorKey: "updated",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Updated" />
    ),
    cell: ({ row }) => {
      const date = row.getValue("updated") as string
      return date ? (
        <span className="text-xs text-muted-foreground">
          {new Date(date).toLocaleDateString()}
        </span>
      ) : (
        <span className="text-muted-foreground">—</span>
      )
    },
  },
]