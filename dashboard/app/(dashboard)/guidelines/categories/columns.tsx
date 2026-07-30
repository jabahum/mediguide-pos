"use client"

import type { ColumnDef, Column, Row } from "@tanstack/react-table"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { 
  ExternalLink, 
  Bug, 
  Users, 
  Heart, 
  HeartPulse, 
  Wind, 
  Zap, 
  Shield, 
  Activity, 
  Microscope, 
  Flower2, 
  UserX, 
  Waves, 
  Thermometer, 
  AlertTriangle, 
  Skull, 
  Droplet,
  Bandage,
  LucideIcon
} from "lucide-react"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import type { GuidelineCategoriesResponse } from "@/types/backend-types"
import { GuidelineCategoriesWithParent } from "@/types/expanded"
import { ExtendedColumnDef } from "@/types/data-table"
import { useGuidelineCategories } from "@/hooks/use-guideline-categories"

// Icon mapping for rendering proper Lucide icons
const iconMap: Record<string, LucideIcon> = {
  Bug,
  Users,
  Heart,
  HeartPulse,
  Wind,
  Zap,
  Shield,
  Activity,
  Microscope,
  Flower2,
  UserX,
  Waves,
  Thermometer,
  AlertTriangle,
  Skull,
  Droplet,
  Bandage,
}

// Helper function to render icon component
const renderIcon = (iconName: string | null) => {
  if (!iconName || !iconMap[iconName]) {
    return <span className="text-muted-foreground">—</span>
  }
  
  const IconComponent = iconMap[iconName]
  return <IconComponent className="h-4 w-4" />
}

export function useGuidelineCategoryColumns(): ColumnDef<GuidelineCategoriesResponse>[] {
  const { getCategoryById, getCategoryPath } = useGuidelineCategories()

  return [
    {
      accessorKey: "name",
      header: ({ column }) => (
        <DataTableColumnHeader column={column} title="Name" />
      ),
      cell: ({ row }) => {
        const category = row.original
        const path = getCategoryPath(category.id)
        const level = path.length - 1
        const indent = "  ".repeat(level)

        return (
          <div className="flex items-center space-x-2">
            {level > 0 && (
              <span className="text-muted-foreground text-sm">
                {indent}└─
              </span>
            )}
            {category.icon && (
              <span className="text-lg">{category.icon}</span>
            )}
            {category.color && (
              <div 
                className="w-3 h-3 rounded-full border"
                style={{ backgroundColor: category.color }}
              />
            )}
            <div>
              <div className="font-medium">{category.name}</div>
              {category.slug && (
                <div className="text-xs text-muted-foreground">
                  /{category.slug}
                </div>
              )}
            </div>
          </div>
        )
      },
      enableSorting: true,
      enableHiding: false,
    },
    {
      accessorKey: "description",
      header: ({ column }) => (
        <DataTableColumnHeader column={column} title="Description" />
      ),
      cell: ({ row }) => {
        const description = row.getValue("description") as string
        if (!description) return <span className="text-muted-foreground">—</span>
        
        return (
          <div className="max-w-[300px]">
            <p className="truncate text-sm">{description}</p>
          </div>
        )
      },
      enableSorting: false,
    },
    {
      accessorKey: "parent_category",
      header: ({ column }) => (
        <DataTableColumnHeader column={column} title="Parent Category" />
      ),
      cell: ({ row }) => {
        const parentId = row.getValue("parent_category") as string
        if (!parentId) {
          return (
            <Badge variant="outline" className="text-xs">
              Root Category
            </Badge>
          )
        }

        const parent = getCategoryById(parentId)
        if (!parent) return <span className="text-muted-foreground">—</span>

        return (
          <div className="flex items-center space-x-2">
            {parent.icon && (
              <span className="text-sm">{parent.icon}</span>
            )}
            {parent.color && (
              <div 
                className="w-2 h-2 rounded-full"
                style={{ backgroundColor: parent.color }}
              />
            )}
            <span className="text-sm">{parent.name}</span>
          </div>
        )
      },
      enableSorting: true,
    },
    {
      accessorKey: "sort_order",
      header: ({ column }) => (
        <DataTableColumnHeader column={column} title="Sort Order" />
      ),
      cell: ({ row }) => {
        const sortOrder = row.getValue("sort_order") as number
        return (
          <Badge variant="secondary" className="text-xs font-mono">
            {sortOrder || 0}
          </Badge>
        )
      },
      enableSorting: true,
    },
    {
      accessorKey: "status",
      header: ({ column }) => (
        <DataTableColumnHeader column={column} title="Status" />
      ),
      cell: ({ row }) => {
        const status = row.getValue("status") as string
        
        return (
          <Badge 
            variant={status === "active" ? "default" : "secondary"}
            className="text-xs"
          >
            {status === "active" ? "Active" : "Inactive"}
          </Badge>
        )
      },
      enableSorting: true,
      filterFn: (row, id, value) => {
        return value.includes(row.getValue(id))
      },
    },
    {
      accessorKey: "created",
      header: ({ column }) => (
        <DataTableColumnHeader column={column} title="Created" />
      ),
      cell: ({ row }) => {
        const created = row.getValue("created") as string
        if (!created) return <span className="text-muted-foreground">—</span>
        
        return (
          <time className="text-sm text-muted-foreground">
            {new Date(created).toLocaleDateString()}
          </time>
        )
      },
      enableSorting: true,
    },
    {
      accessorKey: "updated",
      header: ({ column }) => (
        <DataTableColumnHeader column={column} title="Updated" />
      ),
      cell: ({ row }) => {
        const updated = row.getValue("updated") as string
        if (!updated) return <span className="text-muted-foreground">—</span>
        
        return (
          <time className="text-sm text-muted-foreground">
            {new Date(updated).toLocaleDateString()}
          </time>
        )
      },
      enableSorting: true,
    },
  ]
}

// Export for use in other components  
export const columns: ExtendedColumnDef<GuidelineCategoriesWithParent>[] = [
  {
    accessorKey: "name",
    header: ({ column }: { column: Column<GuidelineCategoriesWithParent> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Name"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }: { row: Row<GuidelineCategoriesWithParent> }) => {
      const name = row.getValue("name") as string
      return <div className="font-medium">{name}</div>
    },
    enableSorting: true,
    enableHiding: false,
  },
  {
    accessorKey: "description",
    header: ({ column }: { column: Column<GuidelineCategoriesWithParent> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Description"
        canSort={false}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }: { row: Row<GuidelineCategoriesWithParent> }) => {
      const description = row.getValue("description") as string
      if (!description) return <span className="text-muted-foreground">—</span>
      
      return (
        <div className="max-w-[300px]">
          <p className="truncate text-sm">{description}</p>
        </div>
      )
    },
    enableSorting: false,
  },
  {
    id: "parent_category_name",
    header: ({ column }: { column: Column<GuidelineCategoriesWithParent> }) => (
      <DataTableColumnHeader
        column={column}
        title="Parent Category"
        canSort={true}
        canFilter={true}
        filterType="text"
        relationField="parent_category.name"
      />
    ),
    accessorFn: (row) => {
      const parent = row.expand?.parent_category
      return parent?.name || "Root Category"
    },
    cell: ({ row }: { row: Row<GuidelineCategoriesWithParent> }) => {
      const parent = row.original.expand?.parent_category
      
      if (!parent) {
        return (
          <Badge variant="outline" className="text-xs">
            Root Category
          </Badge>
        )
      }
      
      return (
        <Button
          variant="link"
          size="sm"
          className="h-auto p-0 text-left justify-start"
          onClick={(e) => {
            e.stopPropagation()
            // Could navigate to parent category or show details
            console.log("Navigate to parent category:", parent.id)
          }}
        >
          <span>{parent.name}</span>
          <ExternalLink className="ml-1 h-3 w-3" />
        </Button>
      )
    },
    enableSorting: true,
    size: 180,
  },
  {
    accessorKey: "status",
    header: ({ column }: { column: Column<GuidelineCategoriesWithParent> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Status"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={[
          { label: "Active", value: "active" },
          { label: "Inactive", value: "inactive" }
        ]}
      />
    ),
    cell: ({ row }: { row: Row<GuidelineCategoriesWithParent> }) => {
      const status = row.getValue("status") as string
      
      return (
        <Badge 
          variant={status === "active" ? "default" : "secondary"}
          className="text-xs"
        >
          {status === "active" ? "Active" : "Inactive"}
        </Badge>
      )
    },
    enableSorting: true,
    filterFn: (row: Row<GuidelineCategoriesWithParent>, id: string, value: string[]) => {
      return value.includes(row.getValue(id) as string)
    },
    size: 80,
  },
  {
    accessorKey: "sort_order",
    header: ({ column }: { column: Column<GuidelineCategoriesWithParent> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Order"
        canSort={true}
        canFilter={true}
        filterType="numberRange"
      />
    ),
    cell: ({ row }: { row: Row<GuidelineCategoriesWithParent> }) => {
      const sortOrder = row.getValue("sort_order") as number
      return (
        <Badge variant="secondary" className="text-xs font-mono">
          {sortOrder || 0}
        </Badge>
      )
    },
    enableSorting: true,
    size: 80,
  },
  {
    accessorKey: "icon",
    header: ({ column }: { column: Column<GuidelineCategoriesWithParent> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Icon"
        canSort={false}
        canFilter={true}
        filterType="select"
        filterOptions={[
          { label: "Bug", value: "Bug" },
          { label: "Users", value: "Users" },
          { label: "Heart", value: "Heart" },
          { label: "HeartPulse", value: "HeartPulse" },
          { label: "Wind", value: "Wind" },
          { label: "Zap", value: "Zap" },
          { label: "Shield", value: "Shield" },
          { label: "Activity", value: "Activity" },
          { label: "Microscope", value: "Microscope" },
          { label: "Flower2", value: "Flower2" },
          { label: "UserX", value: "UserX" },
          { label: "Waves", value: "Waves" },
          { label: "Thermometer", value: "Thermometer" },
          { label: "AlertTriangle", value: "AlertTriangle" },
          { label: "Skull", value: "Skull" },
          { label: "Droplet", value: "Droplet" },
          { label: "Bandage", value: "Bandage" }
        ]}
      />
    ),
    cell: ({ row }: { row: Row<GuidelineCategoriesWithParent> }) => {
      const icon = row.getValue("icon") as string
      return renderIcon(icon)
    },
    enableSorting: false,
    enableHiding: true,
    defaultVisible: false,
    size: 60,
  },
  {
    accessorKey: "color",
    header: ({ column }: { column: Column<GuidelineCategoriesWithParent> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Color"
        canSort={false}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }: { row: Row<GuidelineCategoriesWithParent> }) => {
      const color = row.getValue("color") as string
      if (!color) return <span className="text-muted-foreground">—</span>
      return (
        <div className="flex items-center space-x-2">
          <div 
            className="w-4 h-4 rounded-full border border-border"
            style={{ backgroundColor: color }}
          />
          <span className="text-xs font-mono text-muted-foreground">{color}</span>
        </div>
      )
    },
    enableSorting: false,
    enableHiding: true,
    defaultVisible: false,
    size: 120,
  },
  {
    accessorKey: "slug",
    header: ({ column }: { column: Column<GuidelineCategoriesWithParent> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Slug"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }: { row: Row<GuidelineCategoriesWithParent> }) => {
      const slug = row.getValue("slug") as string
      if (!slug) return <span className="text-muted-foreground">—</span>
      return (
        <code className="text-xs bg-muted px-1 py-0.5 rounded">
          /{slug}
        </code>
      )
    },
    enableSorting: true,
    enableHiding: true,
    defaultVisible: false,
    size: 150,
  },
  {
    accessorKey: "created",
    header: ({ column }: { column: Column<GuidelineCategoriesWithParent> }) => (
      <DataTableColumnHeader 
        column={column} 
        title="Created"
        canSort={true}
        canFilter={true}
        filterType="dateRange"
      />
    ),
    cell: ({ row }: { row: Row<GuidelineCategoriesWithParent> }) => {
      const created = row.getValue("created") as string
      if (!created) return <span className="text-muted-foreground">—</span>
      
      return (
        <time className="text-sm text-muted-foreground">
          {new Date(created).toLocaleDateString()}
        </time>
      )
    },
    enableSorting: true,
    size: 100,
  },
]

export type CategoryType = GuidelineCategoriesWithParent