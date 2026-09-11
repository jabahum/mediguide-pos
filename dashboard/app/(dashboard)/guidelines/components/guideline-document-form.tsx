"use client"

import * as React from "react"
import { Loader2, Save } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { GuidelineDocumentInput } from "@/services/guideline-documents.service"
import { guidelineCategoryService } from "@/services/guideline-content.service"
import { useQuery } from "@tanstack/react-query"

const emptyDocument: GuidelineDocumentInput = {
  title: "",
  country: "",
  source_org: "",
  program_area: "",
  language: "en",
  description: "",
  category_ids: [],
}

export function GuidelineDocumentForm({
  initialValue,
  submitting,
  submitLabel,
  onCancel,
  onSubmit,
}: {
  initialValue?: GuidelineDocumentInput
  submitting: boolean
  submitLabel: string
  onCancel: () => void
  onSubmit: (value: GuidelineDocumentInput) => Promise<void>
}) {
  const [value, setValue] = React.useState<GuidelineDocumentInput>(initialValue || emptyDocument)
  const categories = useQuery({
    queryKey: ["guideline-categories", "active", "document-form"],
    queryFn: () => guidelineCategoryService.all({ status: "active" }),
  })

  React.useEffect(() => {
    if (initialValue) setValue(initialValue)
  }, [initialValue])

  function setField(field: keyof GuidelineDocumentInput, fieldValue: string) {
    setValue((current) => ({ ...current, [field]: fieldValue }))
  }

  return (
    <Card>
      <CardContent className="space-y-5 pt-6">
        <div className="grid gap-5 md:grid-cols-2">
          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="guideline-title">Title</Label>
            <Input
              id="guideline-title"
              value={value.title}
              onChange={(event) => setField("title", event.target.value)}
              placeholder="Uganda Clinical Guidelines"
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="program-area">Program area</Label>
            <Input
              id="program-area"
              value={value.program_area || ""}
              onChange={(event) => setField("program_area", event.target.value)}
              placeholder="Malaria"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="source-org">Source organization</Label>
            <Input
              id="source-org"
              value={value.source_org || ""}
              onChange={(event) => setField("source_org", event.target.value)}
              placeholder="Ministry of Health"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="country">Country</Label>
            <Input
              id="country"
              value={value.country || ""}
              onChange={(event) => setField("country", event.target.value)}
              placeholder="Uganda"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="language">Language code</Label>
            <Input
              id="language"
              value={value.language || ""}
              onChange={(event) => setField("language", event.target.value)}
              placeholder="en"
              maxLength={12}
            />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label>Categories</Label>
            <p className="text-sm text-muted-foreground">
              Select every browsing category that applies. Program area remains available for backward compatibility.
            </p>
            <div className="grid gap-2 rounded-md border p-3 sm:grid-cols-2 lg:grid-cols-3">
              {categories.isLoading ? (
                <span className="text-sm text-muted-foreground">Loading categories…</span>
              ) : categories.data?.length ? (
                categories.data.map((category) => {
                  const selected = (value.category_ids || []).includes(category.id)
                  return (
                    <label key={category.id} className="flex cursor-pointer items-center gap-2 rounded p-2 hover:bg-muted">
                      <input
                        type="checkbox"
                        checked={selected}
                        onChange={(event) => setValue((current) => ({
                          ...current,
                          category_ids: event.target.checked
                            ? [...new Set([...(current.category_ids || []), category.id])]
                            : (current.category_ids || []).filter((id) => id !== category.id),
                        }))}
                      />
                      <span className="text-sm">{category.name}</span>
                    </label>
                  )
                })
              ) : (
                <span className="text-sm text-muted-foreground">No active categories are available.</span>
              )}
            </div>
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              value={value.description || ""}
              onChange={(event) => setField("description", event.target.value)}
              rows={6}
              placeholder="Scope and intended use of this guideline..."
            />
          </div>
        </div>
        <div className="flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={onCancel} disabled={submitting}>
            Cancel
          </Button>
          <Button
            type="button"
            disabled={submitting || !value.title.trim()}
            onClick={() => onSubmit({ ...value, title: value.title.trim() })}
          >
            {submitting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
            {submitLabel}
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
