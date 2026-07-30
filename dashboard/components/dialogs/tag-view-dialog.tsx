"use client"

import * as React from "react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Label } from "@/components/ui/label"
import { DrugTagsResponse } from "@/types/backend-types"
import { formatDistanceToNow } from "date-fns"

interface TagViewDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  tag: DrugTagsResponse
}

const tagCategoryLabels = {
  clinical: "Clinical",
  administrative: "Administrative", 
  regulatory: "Regulatory",
  safety: "Safety"
}

const tagCategoryDescriptions = {
  clinical: "Medical and therapeutic related tags",
  administrative: "Management and operational tags",
  regulatory: "Legal and compliance related tags", 
  safety: "Safety and risk related tags"
}

const tagCategoryColors = {
  clinical: "bg-blue-500",
  administrative: "bg-green-500",
  regulatory: "bg-purple-500",
  safety: "bg-red-500"
}

export function TagViewDialog({
  open,
  onOpenChange,
  tag
}: TagViewDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>{tag.name}</DialogTitle>
          <DialogDescription>
            View details for this drug tag
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-4 space-y-6">
          {/* Basic Information */}
          <div className="space-y-4">
            <div>
              <Label className="text-sm font-medium text-muted-foreground">Name</Label>
              <p className="text-sm mt-1">{tag.name}</p>
            </div>

            {tag.description && (
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Description</Label>
                <p className="text-sm mt-1">{tag.description}</p>
              </div>
            )}

            <div>
              <Label className="text-sm font-medium text-muted-foreground">Tag Category</Label>
              <div className="flex flex-col space-y-1 mt-1">
                <Badge className={tagCategoryColors[tag.tag_category]}>
                  {tagCategoryLabels[tag.tag_category]}
                </Badge>
                <p className="text-xs text-muted-foreground">
                  {tagCategoryDescriptions[tag.tag_category]}
                </p>
              </div>
            </div>

            <div>
              <Label className="text-sm font-medium text-muted-foreground">Status</Label>
              <div className="mt-1">
                <Badge className={tag.status === 'active' ? 'bg-green-500' : 'bg-gray-500'}>
                  {tag.status}
                </Badge>
              </div>
            </div>

            {tag.color && (
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Color</Label>
                <div className="flex items-center space-x-2 mt-1">
                  <div
                    className="w-6 h-6 rounded-full border"
                    style={{ backgroundColor: tag.color }}
                  />
                  <span className="text-sm font-mono">{tag.color}</span>
                </div>
              </div>
            )}

            {tag.sort_order !== null && tag.sort_order !== undefined && (
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Sort Order</Label>
                <p className="text-sm mt-1">{tag.sort_order}</p>
              </div>
            )}

            {/* Tag Preview */}
            <div>
              <Label className="text-sm font-medium text-muted-foreground">Preview</Label>
              <div className="mt-1">
                <Badge
                  style={{
                    backgroundColor: tag.color ? `${tag.color}20` : undefined,
                    borderColor: tag.color || undefined,
                    color: tag.color || undefined
                  }}
                >
                  {tag.name}
                </Badge>
              </div>
            </div>
          </div>

          {/* Timestamps */}
          <div className="border-t pt-4 space-y-2">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Created</Label>
                <p className="text-sm mt-1">
                  {formatDistanceToNow(new Date(tag.created), { addSuffix: true })}
                </p>
              </div>
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Updated</Label>
                <p className="text-sm mt-1">
                  {formatDistanceToNow(new Date(tag.updated), { addSuffix: true })}
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="flex justify-end pt-4">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Close
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}