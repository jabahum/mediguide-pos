"use client"

import * as React from "react"
import { Loader2, Save } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { MultiSelect } from "@/components/ui/multi-select"
import { Textarea } from "@/components/ui/textarea"
import { GuidelineDocumentInput } from "@/services/guideline-documents.service"
import { guidelineCategoryService } from "@/services/guideline-content.service"
import { useQuery } from "@tanstack/react-query"
import { diseaseService } from "@/services/content-hubs.service"

const emptyDocument: GuidelineDocumentInput = {
  title: "",
  country: "",
  source_org: "",
  program_area: "",
  language: "en",
  description: "",
  category_ids: [],
  disease_ids: [],
  primary_disease_id: "",
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
  const diseases = useQuery({
    queryKey: ["diseases", "active", "guideline-document-form"],
    queryFn: () => diseaseService.list("", "active"),
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
            <Label htmlFor="program-area">Legacy program area (optional)</Label>
            <Input
              id="program-area"
              value={value.program_area || ""}
              onChange={(event) => setField("program_area", event.target.value)}
              placeholder="Malaria"
            />
            <p className="text-xs text-muted-foreground">Retained for older integrations. Use diseases and categories for new classification.</p>
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
            <MultiSelect
              options={(categories.data || []).map((category) => ({
                value: category.id,
                label: `${category.expand?.parent_category?.name ? `${category.expand.parent_category.name} › ` : ""}${category.name}`,
              }))}
              value={value.category_ids || []}
              onValueChange={(category_ids) => setValue((current) => ({ ...current, category_ids }))}
              placeholder={categories.isLoading ? "Loading categories…" : "Search categories"}
              disabled={categories.isLoading}
            />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label>Diseases</Label>
            <p className="text-sm text-muted-foreground">Assign every applicable disease, then choose one primary disease for discovery and hub placement.</p>
            <MultiSelect
              options={(diseases.data?.items || []).map((disease) => ({
                value: disease.id,
                label: `${disease.parent_name ? `${disease.parent_name} › ` : ""}${disease.name}`,
                color: disease.color,
              }))}
              value={value.disease_ids || []}
              onValueChange={(disease_ids) => setValue((current) => ({
                ...current,
                disease_ids,
                primary_disease_id: disease_ids.includes(current.primary_disease_id || "") ? current.primary_disease_id : "",
              }))}
              placeholder={diseases.isLoading ? "Loading diseases…" : "Search diseases"}
              disabled={diseases.isLoading}
            />
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="primary-disease">Primary disease</Label>
            <select
              id="primary-disease"
              className="h-10 w-full rounded-md border bg-background px-3"
              value={value.primary_disease_id || ""}
              onChange={(event) => setField("primary_disease_id", event.target.value)}
              disabled={!(value.disease_ids || []).length}
            >
              <option value="">No primary disease</option>
              {(diseases.data?.items || []).filter((disease) => (value.disease_ids || []).includes(disease.id)).map((disease) => (
                <option key={disease.id} value={disease.id}>{disease.name}</option>
              ))}
            </select>
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
