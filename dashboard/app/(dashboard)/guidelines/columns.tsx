"use client"

import { ColumnDef } from "@tanstack/react-table"
import { BellPlus, Eye, FilePlus2, Pencil, Upload } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header"
import {
  getDocumentCurrentVersion,
  getDocumentLatestVersion,
  GuidelineDocumentRecord,
} from "@/services/guideline-documents.service"

interface GuidelineColumnActions {
  canUpdate: boolean
  canNotify: boolean
  onView: (document: GuidelineDocumentRecord) => void
  onEdit: (document: GuidelineDocumentRecord) => void
  onNewVersion: (document: GuidelineDocumentRecord) => void
  onUpload: (document: GuidelineDocumentRecord) => void
  onNotify: (document: GuidelineDocumentRecord) => void
}

export function createGuidelinesColumns({
  canUpdate,
  canNotify,
  onView,
  onEdit,
  onNewVersion,
  onUpload,
  onNotify,
}: GuidelineColumnActions): ColumnDef<GuidelineDocumentRecord>[] {
  return [
    {
      accessorKey: "title",
      header: ({ column }) => <DataTableColumnHeader column={column} title="Guideline" />,
      cell: ({ row }) => (
        <div className="min-w-[240px] max-w-[360px] whitespace-normal break-words font-medium leading-5">
          {row.original.title}
        </div>
      ),
      size: 360,
    },
    {
      accessorKey: "program_area",
      header: ({ column }) => <DataTableColumnHeader column={column} title="Program Area" />,
      cell: ({ row }) => (
        <div className="min-w-[180px] max-w-[260px] whitespace-normal break-words leading-5">
          {row.original.program_area || <span className="text-muted-foreground">—</span>}
        </div>
      ),
      size: 240,
    },
    {
      accessorKey: "country",
      header: ({ column }) => <DataTableColumnHeader column={column} title="Country" />,
      cell: ({ row }) => (
        <div className="min-w-[120px] max-w-[170px] whitespace-normal break-words">
          {row.original.country || <span className="text-muted-foreground">—</span>}
        </div>
      ),
      size: 150,
    },
    {
      id: "current_version",
      header: "Current Version",
      accessorFn: (document) => getDocumentCurrentVersion(document)?.version || "",
      cell: ({ row }) => {
        const version = getDocumentCurrentVersion(row.original)
        return version ? (
          <div className="flex min-w-[170px] flex-wrap items-center gap-2">
            <span>{version.version}</span>
            <Badge variant={version.status === "published" ? "default" : "secondary"}>
              {version.status}
            </Badge>
          </div>
        ) : (
          <span className="text-muted-foreground">No version</span>
        )
      },
      size: 190,
    },
    {
      accessorKey: "language",
      header: "Language",
      cell: ({ row }) => (
        <div className="min-w-[90px] whitespace-normal break-words">
          {(row.original.language || "en").toUpperCase()}
        </div>
      ),
      size: 110,
    },
    {
      accessorKey: "updated_at",
      header: ({ column }) => <DataTableColumnHeader column={column} title="Updated" />,
      cell: ({ row }) => (
        <div className="min-w-[110px]">{new Date(row.original.updated_at).toLocaleDateString()}</div>
      ),
      size: 130,
    },
    {
      id: "actions",
      enableHiding: false,
      size: 190,
      cell: ({ row }) => (
        <div className="flex min-w-[176px] justify-end gap-1">
          <Button variant="ghost" size="icon" title="View" onClick={() => onView(row.original)}>
            <Eye className="h-4 w-4" />
          </Button>
          {canUpdate && (
            <>
              <Button variant="ghost" size="icon" title="Edit" onClick={() => onEdit(row.original)}>
                <Pencil className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="icon"
                title="Create version"
                onClick={() => onNewVersion(row.original)}
              >
                <FilePlus2 className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="icon"
                title="Upload PDF"
                disabled={!getDocumentLatestVersion(row.original)}
                onClick={() => onUpload(row.original)}
              >
                <Upload className="h-4 w-4" />
              </Button>
            </>
          )}
          {canNotify && (
            <Button
              variant="ghost"
              size="icon"
              title={getDocumentCurrentVersion(row.original)?.status === "published" ? "Create notification campaign" : "Publish the current version before notifying users"}
              disabled={getDocumentCurrentVersion(row.original)?.status !== "published"}
              onClick={() => onNotify(row.original)}
            >
              <BellPlus className="h-4 w-4" />
            </Button>
          )}
        </div>
      ),
    },
  ]
}
