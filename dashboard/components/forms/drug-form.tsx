"use client"

import * as React from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Checkbox } from "@/components/ui/checkbox"
import { MultiSelect } from "@/components/ui/multi-select"
import { SelectWithCreate } from "@/components/ui/select-with-create"
import { drugReferenceService } from "@/services/drug.service"
import { CreateDrugClassDialog } from "@/components/dialogs/create-drug-class-dialog"
import { CreateTherapeuticCategoryDialog } from "@/components/dialogs/create-therapeutic-category-dialog"
import { DrugsResponse, DrugCategoriesResponse, DrugTagsResponse } from "@/types/backend-types"

const drugSchema = z.object({
  name: z.string().min(1, "Name is required").max(200, "Name must be less than 200 characters"),
  description: z.string().optional(),
  brand_names: z.string().optional(),
  drug_class: z.string().optional(),
  therapeutic_category: z.string().optional(),
  mechanism_of_action: z.string().optional(),
  indications: z.string().optional(),
  contraindications: z.string().optional(),
  side_effects: z.string().optional(),
  warnings: z.string().optional(),
  adult_dose: z.string().optional(),
  pediatric_dose: z.string().optional(),
  elderly_dose: z.string().optional(),
  max_daily_dose: z.string().optional(),
  frequency: z.string().optional(),
  duration: z.string().optional(),
  route_of_administration: z.array(z.enum(["oral", "IV", "IM", "topical", "inhaled", "sublingual", "rectal", "transdermal", "intranasal", "subcutaneous"])).optional(),
  pregnancy_category: z.enum(["A", "B", "C", "D", "X", "Unknown"]).optional(),
  controlled_substance: z.enum(["None", "Schedule I", "Schedule II", "Schedule III", "Schedule IV", "Schedule V"]).optional(),
  monitoring_parameters: z.string().optional(),
  clinical_notes: z.string().optional(),
  references: z.string().optional(),
  search_keywords: z.string().optional(),
  categories: z.array(z.string()).optional(),
  tags: z.array(z.string()).optional(),
  who_eml_status: z.boolean().optional(),
  antimicrobial_status: z.boolean().optional(),
  status: z.enum(["active", "inactive", "under_review", "archived"]),
  review_status: z.enum(["approved", "pending", "needs_update"]),
})

type DrugFormData = z.infer<typeof drugSchema>

interface DrugFormProps {
  initialData?: Partial<DrugsResponse>
  categories?: DrugCategoriesResponse[]
  tags?: DrugTagsResponse[]
  onSubmit: (data: DrugFormData) => Promise<void>
  onCancel: () => void
  loading?: boolean
  mode: "create" | "edit"
}

const routeOptions = [
  { value: "oral", label: "Oral" },
  { value: "IV", label: "Intravenous (IV)" },
  { value: "IM", label: "Intramuscular (IM)" },
  { value: "topical", label: "Topical" },
  { value: "inhaled", label: "Inhaled" },
  { value: "sublingual", label: "Sublingual" },
  { value: "rectal", label: "Rectal" },
  { value: "transdermal", label: "Transdermal" },
  { value: "intranasal", label: "Intranasal" },
  { value: "subcutaneous", label: "Subcutaneous" },
]

const pregnancyOptions = [
  { value: "A", label: "Category A - No risk" },
  { value: "B", label: "Category B - No risk in humans" },
  { value: "C", label: "Category C - Risk cannot be ruled out" },
  { value: "D", label: "Category D - Positive evidence of risk" },
  { value: "X", label: "Category X - Contraindicated" },
  { value: "Unknown", label: "Unknown" },
]

const controlledSubstanceOptions = [
  { value: "None", label: "None" },
  { value: "Schedule I", label: "Schedule I" },
  { value: "Schedule II", label: "Schedule II" },
  { value: "Schedule III", label: "Schedule III" },
  { value: "Schedule IV", label: "Schedule IV" },
  { value: "Schedule V", label: "Schedule V" },
]

export function DrugForm({
  initialData,
  categories = [],
  tags = [],
  onSubmit,
  onCancel,
  loading = false,
  mode
}: DrugFormProps) {
  // Dialog states
  const [drugClassDialogOpen, setDrugClassDialogOpen] = React.useState(false)
  const [therapeuticCategoryDialogOpen, setTherapeuticCategoryDialogOpen] = React.useState(false)

  // Refresh triggers for selects
  const [drugClassRefreshTrigger, setDrugClassRefreshTrigger] = React.useState(0)
  const [therapeuticCategoryRefreshTrigger, setTherapeuticCategoryRefreshTrigger] = React.useState(0)

  // Handlers for creating new options
  const handleDrugClassCreated = (newDrugClass: { id: string }) => {
    setValue("drug_class", newDrugClass.id)
    setDrugClassRefreshTrigger(prev => prev + 1)
  }

  const handleTherapeuticCategoryCreated = (newCategory: { id: string }) => {
    setValue("therapeutic_category", newCategory.id)
    setTherapeuticCategoryRefreshTrigger(prev => prev + 1)
  }

  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
  } = useForm<DrugFormData>({
    resolver: zodResolver(drugSchema),
    defaultValues: {
      name: initialData?.name || "",
      description: initialData?.description || "",
      brand_names: initialData?.brand_names || "",
      drug_class: initialData?.drug_class || "",
      therapeutic_category: initialData?.therapeutic_category || "",
      mechanism_of_action: initialData?.mechanism_of_action || "",
      indications: initialData?.indications || "",
      contraindications: initialData?.contraindications || "",
      side_effects: initialData?.side_effects || "",
      warnings: initialData?.warnings || "",
      adult_dose: initialData?.adult_dose || "",
      pediatric_dose: initialData?.pediatric_dose || "",
      elderly_dose: initialData?.elderly_dose || "",
      max_daily_dose: initialData?.max_daily_dose || "",
      frequency: initialData?.frequency || "",
      duration: initialData?.duration || "",
      route_of_administration: initialData?.route_of_administration || [],
      pregnancy_category: initialData?.pregnancy_category || undefined,
      controlled_substance: initialData?.controlled_substance || "None",
      monitoring_parameters: initialData?.monitoring_parameters || "",
      clinical_notes: initialData?.clinical_notes || "",
      references: initialData?.references || "",
      search_keywords: initialData?.search_keywords || "",
      categories: initialData?.categories || [],
      tags: initialData?.tags || [],
      who_eml_status: initialData?.who_eml_status || false,
      antimicrobial_status: initialData?.antimicrobial_status || false,
      status: initialData?.status || "active",
      review_status: initialData?.review_status || "pending",
    }
  })

  const handleFormSubmit = async (data: DrugFormData) => {
    await onSubmit(data)
  }

  // Convert categories and tags to options format
  const categoryOptions = categories.map(cat => ({
    value: cat.id,
    label: cat.name,
    color: cat.color
  }))

  const tagOptions = tags.map(tag => ({
    value: tag.id,
    label: tag.name,
    color: tag.color
  }))

  return (
    <>
      <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-6">
        <Tabs defaultValue="basic" className="w-full">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="basic">Basic Info</TabsTrigger>
            <TabsTrigger value="clinical">Clinical</TabsTrigger>
            <TabsTrigger value="dosing">Dosing</TabsTrigger>
            <TabsTrigger value="metadata">Metadata</TabsTrigger>
          </TabsList>

          <TabsContent value="basic" className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Drug Name *</Label>
              <Input
                id="name"
                {...register("name")}
                placeholder="Enter drug name"
                disabled={loading}
              />
              {errors.name && (
                <p className="text-sm text-destructive">{errors.name.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="brand_names">Brand Names</Label>
              <Input
                id="brand_names"
                {...register("brand_names")}
                placeholder="Enter brand names (comma separated)"
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                {...register("description")}
                placeholder="Enter drug description"
                rows={4}
                disabled={loading}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="drug_class">Drug Class</Label>
                <SelectWithCreate
                  value={watch("drug_class")}
                  onValueChange={(value) => setValue("drug_class", value)}
                  placeholder="Select drug class..."
                  loadOptions={drugReferenceService.allClasses}
                  onCreateClick={() => setDrugClassDialogOpen(true)}
                  disabled={loading}
                  refreshTrigger={drugClassRefreshTrigger}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="therapeutic_category">Therapeutic Category</Label>
                <SelectWithCreate
                  value={watch("therapeutic_category")}
                  onValueChange={(value) => setValue("therapeutic_category", value)}
                  placeholder="Select therapeutic category..."
                  loadOptions={drugReferenceService.allTherapeuticCategories}
                  onCreateClick={() => setTherapeuticCategoryDialogOpen(true)}
                  disabled={loading}
                  refreshTrigger={therapeuticCategoryRefreshTrigger}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>Categories</Label>
              <MultiSelect
                options={categoryOptions}
                value={watch("categories")}
                onValueChange={(value) => setValue("categories", value)}
                placeholder="Select categories..."
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label>Tags</Label>
              <MultiSelect
                options={tagOptions}
                value={watch("tags")}
                onValueChange={(value) => setValue("tags", value)}
                placeholder="Select tags..."
                disabled={loading}
              />
            </div>
          </TabsContent>

          <TabsContent value="clinical" className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="mechanism_of_action">Mechanism of Action</Label>
              <Textarea
                id="mechanism_of_action"
                {...register("mechanism_of_action")}
                placeholder="Describe how the drug works"
                rows={3}
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="indications">Indications</Label>
              <Textarea
                id="indications"
                {...register("indications")}
                placeholder="What conditions is this drug used for?"
                rows={3}
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="contraindications">Contraindications</Label>
              <Textarea
                id="contraindications"
                {...register("contraindications")}
                placeholder="When should this drug not be used?"
                rows={3}
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="side_effects">Side Effects</Label>
              <Textarea
                id="side_effects"
                {...register("side_effects")}
                placeholder="List common and serious side effects"
                rows={3}
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="warnings">Warnings</Label>
              <Textarea
                id="warnings"
                {...register("warnings")}
                placeholder="Important warnings and precautions"
                rows={3}
                disabled={loading}
              />
            </div>
          </TabsContent>

          <TabsContent value="dosing" className="space-y-4">
            <div className="space-y-2">
              <Label>Route of Administration</Label>
              <MultiSelect
                options={routeOptions}
                value={watch("route_of_administration") || []}
                onValueChange={(value) => setValue("route_of_administration", value as ("oral" | "IV" | "IM" | "topical" | "inhaled" | "sublingual" | "rectal" | "transdermal" | "intranasal" | "subcutaneous")[])}
                placeholder="Select routes"
                disabled={loading}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="adult_dose">Adult Dose</Label>
                <Input
                  id="adult_dose"
                  {...register("adult_dose")}
                  placeholder="e.g., 10mg once daily"
                  disabled={loading}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="pediatric_dose">Pediatric Dose</Label>
                <Input
                  id="pediatric_dose"
                  {...register("pediatric_dose")}
                  placeholder="e.g., 5mg/kg/day"
                  disabled={loading}
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="elderly_dose">Elderly Dose</Label>
                <Input
                  id="elderly_dose"
                  {...register("elderly_dose")}
                  placeholder="e.g., 5mg once daily"
                  disabled={loading}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="max_daily_dose">Maximum Daily Dose</Label>
                <Input
                  id="max_daily_dose"
                  {...register("max_daily_dose")}
                  placeholder="e.g., 40mg/day"
                  disabled={loading}
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="frequency">Frequency</Label>
                <Input
                  id="frequency"
                  {...register("frequency")}
                  placeholder="e.g., Once daily"
                  disabled={loading}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="duration">Duration</Label>
                <Input
                  id="duration"
                  {...register("duration")}
                  placeholder="e.g., 7-14 days"
                  disabled={loading}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="monitoring_parameters">Monitoring Parameters</Label>
              <Textarea
                id="monitoring_parameters"
                {...register("monitoring_parameters")}
                placeholder="What should be monitored when using this drug?"
                rows={3}
                disabled={loading}
              />
            </div>
          </TabsContent>

          <TabsContent value="metadata" className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Pregnancy Category</Label>
                <Select
                  value={watch("pregnancy_category")}
                  onValueChange={(value) => setValue("pregnancy_category", value as "A" | "B" | "C" | "D" | "X" | "Unknown")}
                  disabled={loading}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select category" />
                  </SelectTrigger>
                  <SelectContent>
                    {pregnancyOptions.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Controlled Substance</Label>
                <Select
                  value={watch("controlled_substance")}
                  onValueChange={(value) => setValue("controlled_substance", value as "None" | "Schedule I" | "Schedule II" | "Schedule III" | "Schedule IV" | "Schedule V")}
                  disabled={loading}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {controlledSubstanceOptions.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="flex items-center space-x-6">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="who_eml_status"
                  checked={watch("who_eml_status")}
                  onCheckedChange={(checked) => setValue("who_eml_status", !!checked)}
                  disabled={loading}
                />
                <Label htmlFor="who_eml_status">WHO Essential Medicine</Label>
              </div>

              <div className="flex items-center space-x-2">
                <Checkbox
                  id="antimicrobial_status"
                  checked={watch("antimicrobial_status")}
                  onCheckedChange={(checked) => setValue("antimicrobial_status", !!checked)}
                  disabled={loading}
                />
                <Label htmlFor="antimicrobial_status">Antimicrobial</Label>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Status</Label>
                <Select
                  value={watch("status")}
                  onValueChange={(value) => setValue("status", value as "active" | "inactive" | "under_review" | "archived")}
                  disabled={loading}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="active">Active</SelectItem>
                    <SelectItem value="inactive">Inactive</SelectItem>
                    <SelectItem value="under_review">Under Review</SelectItem>
                    <SelectItem value="archived">Archived</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Review Status</Label>
                <Select
                  value={watch("review_status")}
                  onValueChange={(value) => setValue("review_status", value as "approved" | "pending" | "needs_update")}
                  disabled={loading}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="approved">Approved</SelectItem>
                    <SelectItem value="pending">Pending</SelectItem>
                    <SelectItem value="needs_update">Needs Update</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="search_keywords">Search Keywords</Label>
              <Input
                id="search_keywords"
                {...register("search_keywords")}
                placeholder="Enter keywords for better searchability"
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="clinical_notes">Clinical Notes</Label>
              <Textarea
                id="clinical_notes"
                {...register("clinical_notes")}
                placeholder="Additional clinical notes"
                rows={3}
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="references">References</Label>
              <Textarea
                id="references"
                {...register("references")}
                placeholder="Medical references and citations"
                rows={3}
                disabled={loading}
              />
            </div>
          </TabsContent>
        </Tabs>

        <div className="flex justify-end space-x-2 pt-6 border-t">
          <Button
            type="button"
            variant="outline"
            onClick={onCancel}
            disabled={loading}
          >
            Cancel
          </Button>
          <Button type="submit" disabled={loading}>
            {loading ? "Saving..." : mode === "create" ? "Create Drug" : "Update Drug"}
          </Button>
        </div>
      </form>

      {/* Create Drug Class Dialog */}
      <CreateDrugClassDialog
        open={drugClassDialogOpen}
        onOpenChange={setDrugClassDialogOpen}
        onSuccess={handleDrugClassCreated}
      />

      {/* Create Therapeutic Category Dialog */}
      <CreateTherapeuticCategoryDialog
        open={therapeuticCategoryDialogOpen}
        onOpenChange={setTherapeuticCategoryDialogOpen}
        onSuccess={handleTherapeuticCategoryCreated}
      />
    </>
  )
}
