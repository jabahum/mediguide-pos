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
import { DrugCategoriesResponse } from "@/types/backend-types"
import { formatDistanceToNow } from "date-fns"

interface CategoryViewDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  category: DrugCategoriesResponse
  parentCategory?: DrugCategoriesResponse
}

export function CategoryViewDialog({
  open,
  onOpenChange,
  category,
  parentCategory
}: CategoryViewDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center space-x-2">
            {category.icon && <span className="text-lg">{category.icon}</span>}
            <span>{category.name}</span>
          </DialogTitle>
          <DialogDescription>
            View details for this drug category
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-4 space-y-6">
          {/* Basic Information */}
          <div className="space-y-4">
            <div>
              <Label className="text-sm font-medium text-muted-foreground">Name</Label>
              <div className="flex items-center space-x-2 mt-1">
                {category.icon && <span>{category.icon}</span>}
                <p className="text-sm">{category.name}</p>
              </div>
            </div>

            {category.description && (
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Description</Label>
                <p className="text-sm mt-1">{category.description}</p>
              </div>
            )}

            <div>
              <Label className="text-sm font-medium text-muted-foreground">Status</Label>
              <div className="mt-1">
                <Badge className={category.status === 'active' ? 'bg-green-500' : 'bg-gray-500'}>
                  {category.status}
                </Badge>
              </div>
            </div>

            {parentCategory && (
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Parent Category</Label>
                <div className="flex items-center space-x-2 mt-1">
                  {parentCategory.color && (
                    <div
                      className="w-3 h-3 rounded-full border"
                      style={{ backgroundColor: parentCategory.color }}
                    />
                  )}
                  {parentCategory.icon && <span>{parentCategory.icon}</span>}
                  <Badge variant="outline">{parentCategory.name}</Badge>
                </div>
              </div>
            )}

            {category.color && (
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Color</Label>
                <div className="flex items-center space-x-2 mt-1">
                  <div
                    className="w-6 h-6 rounded-full border"
                    style={{ backgroundColor: category.color }}
                  />
                  <span className="text-sm font-mono">{category.color}</span>
                </div>
              </div>
            )}

            {category.sort_order !== null && category.sort_order !== undefined && (
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Sort Order</Label>
                <p className="text-sm mt-1">{category.sort_order}</p>
              </div>
            )}
          </div>

          {/* Timestamps */}
          <div className="border-t pt-4 space-y-2">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Created</Label>
                <p className="text-sm mt-1">
                  {formatDistanceToNow(new Date(category.created), { addSuffix: true })}
                </p>
              </div>
              <div>
                <Label className="text-sm font-medium text-muted-foreground">Updated</Label>
                <p className="text-sm mt-1">
                  {formatDistanceToNow(new Date(category.updated), { addSuffix: true })}
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