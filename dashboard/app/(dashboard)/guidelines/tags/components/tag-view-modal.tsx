"use client"

import * as React from "react"
import { format } from "date-fns"

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import type { GuidelineTagsResponse } from "@/types/backend-types"

interface TagViewModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  tag: GuidelineTagsResponse | null
  onEdit?: (tag: GuidelineTagsResponse) => void
}

function Row({
  label,
  children,
}: {
  label: string
  children: React.ReactNode
}) {
  return (
    <div className="grid grid-cols-3 gap-3 py-2 border-b last:border-b-0">
      <div className="text-xs font-medium text-muted-foreground uppercase tracking-wide pt-0.5">
        {label}
      </div>
      <div className="col-span-2 text-sm break-words">{children}</div>
    </div>
  )
}

function formatDate(value?: string) {
  if (!value) return "—"
  try {
    return format(new Date(value), "PPpp")
  } catch {
    return value
  }
}

export function TagViewModal({
  open,
  onOpenChange,
  tag,
  onEdit,
}: TagViewModalProps) {
  if (!tag) return null

  const emptyDash = <span className="text-muted-foreground">—</span>

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[480px]">
        <DialogHeader>
          <DialogTitle>{tag.name}</DialogTitle>
          <DialogDescription>Tag details</DialogDescription>
        </DialogHeader>

        <div className="rounded-md border bg-muted/20 px-4 py-2">
          <Row label="Description">
            {tag.description ? (
              <p className="whitespace-pre-wrap text-sm">{tag.description}</p>
            ) : (
              emptyDash
            )}
          </Row>
          <Row label="Created">{formatDate(tag.created)}</Row>
          <Row label="Updated">{formatDate(tag.updated)}</Row>
          <Row label="ID">
            <code className="text-xs">{tag.id}</code>
          </Row>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Close
          </Button>
          {onEdit && (
            <Button
              onClick={() => {
                onOpenChange(false)
                onEdit(tag)
              }}
            >
              Edit Tag
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
