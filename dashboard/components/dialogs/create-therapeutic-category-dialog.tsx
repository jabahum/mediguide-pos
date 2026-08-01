"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { drugReferenceService } from "@/services/drug.service"
import { showToast } from "@/lib/toast"

interface CreateTherapeuticCategoryDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess?: (category: { id: string; name: string }) => void
}

export function CreateTherapeuticCategoryDialog({ open, onOpenChange, onSuccess }: CreateTherapeuticCategoryDialogProps) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    name: "",
    description: "",
    status: "active" as const,
    sort_order: 0
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const category = await drugReferenceService.createTherapeuticCategory(formData)
      
      showToast.success("Success", "Therapeutic category created successfully")
      onSuccess?.(category as unknown as { id: string; name: string })
      onOpenChange(false)
      
      // Reset form
      setFormData({
        name: "",
        description: "",
        status: "active",
        sort_order: 0
      })
    } catch (error: unknown) {
      console.error("Failed to create therapeutic category:", error)
      const message = error instanceof Error ? error.message : "Failed to create therapeutic category"
      showToast.error("Error", message)
    } finally {
      setLoading(false)
    }
  }

  const handleChange = (field: string, value: string | number) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Create Therapeutic Category</DialogTitle>
          <DialogDescription>
            Add a new therapeutic category to the system
          </DialogDescription>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="name">Name *</Label>
            <Input
              id="name"
              value={formData.name}
              onChange={(e) => handleChange("name", e.target.value)}
              placeholder="e.g., Cardiovascular"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => handleChange("description", e.target.value)}
              placeholder="Optional description"
              rows={3}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="status">Status</Label>
            <Select value={formData.status} onValueChange={(value) => handleChange("status", value)}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="inactive">Inactive</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="sort_order">Sort Order</Label>
            <Input
              id="sort_order"
              type="number"
              value={formData.sort_order}
              onChange={(e) => handleChange("sort_order", parseInt(e.target.value) || 0)}
              placeholder="0"
            />
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={loading || !formData.name.trim()}>
              {loading ? "Creating..." : "Create"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
