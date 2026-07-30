"use client"

import * as React from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

// UI Components
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Switch } from "@/components/ui/switch"
import { PageHeader } from "@/components/ui/page-header"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { EditorFormWrapper } from "@/components/ui/rich-text-editor"
import { MultiGuidelineCategorySelector } from "@/components/ui/guideline-category-selector"
import { GuidelineIndexSelector } from "@/components/ui/guideline-index-selector"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs"

// Icons
import { Save } from "lucide-react"

// Hooks and Utils
import { useQueryClient } from "@tanstack/react-query"
import { showToast } from "@/lib/toast"
import { useGuidelineTags } from "@/hooks/use-guideline-tags"
import { getBackendClient } from "@/lib/backend-client"
import { usePermissionContext } from "@/lib/permission-context"

// Form Schema
const medicalGuidelineSchema = z.object({
  condition_name: z.string().min(1, "Condition name is required"),
  icd10_code: z.string().optional(),
  target_population: z.string().optional(),
  definition: z.string().optional(),
  causes: z.string().optional(),
  clinical_features: z.string().optional(),
  differential_diagnosis: z.string().optional(),
  classification_mild: z.string().optional(),
  classification_moderate: z.string().optional(),
  classification_severe: z.string().optional(),
  classification_critical: z.string().optional(),
  general_management: z.string().optional(),
  medication_primary: z.string().optional(),
  dosage_adult: z.string().optional(),
  dosage_pediatric: z.string().optional(),
  medication_secondary: z.string().optional(),
  dosage_secondary_adult: z.string().optional(),
  dosage_secondary_pediatric: z.string().optional(),
  healthcare_level_required: z.string().optional(),
  route_administration: z.string().optional(),
  monitoring_requirements: z.string().optional(),
  contraindications: z.string().optional(),
  prevention_measures: z.string().optional(),
  special_notes: z.string().optional(),
  status: z.string().optional(),
  is_published: z.boolean().optional(),
  priority: z.string().optional(),
  version: z.string().optional(),
  categories: z.array(z.string()).optional(),
  tags: z.array(z.string()).optional(),
  index_item: z.string().optional(),
})

type MedicalGuidelineForm = z.infer<typeof medicalGuidelineSchema>


// Simple Tags Multi-Selector Component
function TagsMultiSelector({ 
  value = [], 
  onValueChange,
  className 
}: {
  value?: string[]
  onValueChange?: (value: string[]) => void
  className?: string
}) {
  const { tags, loading } = useGuidelineTags()
  const [selectedTags, setSelectedTags] = React.useState<string[]>(value)

  React.useEffect(() => {
    setSelectedTags(value)
  }, [value])

  const handleTagToggle = (tagId: string) => {
    const newSelection = selectedTags.includes(tagId)
      ? selectedTags.filter(id => id !== tagId)
      : [...selectedTags, tagId]
    
    setSelectedTags(newSelection)
    onValueChange?.(newSelection)
  }

  const selectedTagObjects = tags.filter(tag => selectedTags.includes(tag.id))

  if (loading) {
    return <div className="text-sm text-muted-foreground">Loading tags...</div>
  }

  return (
    <div className="space-y-2">
      <Select>
        <SelectTrigger className={className}>
          <SelectValue placeholder="Select tags..." />
        </SelectTrigger>
        <SelectContent>
          {tags.map((tag) => (
            <div
              key={tag.id}
              className="flex items-center space-x-2 px-2 py-1.5 cursor-pointer hover:bg-accent"
              onClick={() => handleTagToggle(tag.id)}
            >
              <input
                type="checkbox"
                checked={selectedTags.includes(tag.id)}
                onChange={() => handleTagToggle(tag.id)}
                className="rounded"
                aria-label={`Toggle ${tag.name} tag`}
              />
              <span className="text-sm">{tag.name}</span>
            </div>
          ))}
        </SelectContent>
      </Select>
      
      {selectedTagObjects.length > 0 && (
        <div className="flex flex-wrap gap-1">
          {selectedTagObjects.map((tag) => (
            <Badge 
              key={tag.id} 
              variant="outline" 
              className="text-xs"
            >
              {tag.name}
              <button
                type="button"
                onClick={() => handleTagToggle(tag.id)}
                className="ml-1 hover:bg-muted-foreground/20 rounded-full p-0.5"
              >
                ×
              </button>
            </Badge>
          ))}
        </div>
      )}
    </div>
  )
}

export default function CreateGuidelinePage() {
  const router = useRouter()
  const queryClient = useQueryClient()
  const searchParams = useSearchParams()
  const duplicateFromId = searchParams.get("duplicate")
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [isSubmitting, setIsSubmitting] = React.useState(false)
  const [loadingDuplicate, setLoadingDuplicate] = React.useState(!!duplicateFromId)

  // Keep loadingDuplicate in sync if the `duplicate` query param changes while
  // the page stays mounted (App Router can update searchParams in-place).
  React.useEffect(() => {
    setLoadingDuplicate(!!duplicateFromId)
  }, [duplicateFromId])

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "create:any")) {
      router.replace("/guidelines")
    }
  }, [permLoading, hasPermission, router])

  const form = useForm<MedicalGuidelineForm>({
    resolver: zodResolver(medicalGuidelineSchema),
    defaultValues: {
      condition_name: "",
      icd10_code: "",
      target_population: "",
      definition: "",
      causes: "",
      clinical_features: "",
      differential_diagnosis: "",
      classification_mild: "",
      classification_moderate: "",
      classification_severe: "",
      classification_critical: "",
      general_management: "",
      medication_primary: "",
      dosage_adult: "",
      dosage_pediatric: "",
      medication_secondary: "",
      dosage_secondary_adult: "",
      dosage_secondary_pediatric: "",
      healthcare_level_required: "",
      route_administration: "",
      monitoring_requirements: "",
      contraindications: "",
      prevention_measures: "",
      special_notes: "",
      status: "draft",
      is_published: false,
      priority: "",
      version: "1.0",
      categories: [],
      tags: [],
      index_item: "",
    },
  })

  React.useEffect(() => {
    if (!duplicateFromId) return
    let cancelled = false

    const loadSource = async () => {
      try {
        const pb = getBackendClient()
        const result = await pb
          .collection("medical_guidelines")
          .getOne(duplicateFromId, { expand: "categories,tags,index_item" })

        if (cancelled) return

        form.reset({
          // Mark as a copy and force status/publish back to safe defaults so the
          // duplicate isn't accidentally published as-is.
          condition_name: result.condition_name
            ? `${result.condition_name} (Copy)`
            : "",
          icd10_code: (result.icd10_code as string) || "",
          target_population: (result.target_population as string) || "",
          definition: (result.definition as string) || "",
          causes: (result.causes as string) || "",
          clinical_features: (result.clinical_features as string) || "",
          differential_diagnosis: (result.differential_diagnosis as string) || "",
          classification_mild: (result.classification_mild as string) || "",
          classification_moderate: (result.classification_moderate as string) || "",
          classification_severe: (result.classification_severe as string) || "",
          classification_critical: (result.classification_critical as string) || "",
          general_management: (result.general_management as string) || "",
          medication_primary: (result.medication_primary as string) || "",
          dosage_adult: (result.dosage_adult as string) || "",
          dosage_pediatric: (result.dosage_pediatric as string) || "",
          medication_secondary: (result.medication_secondary as string) || "",
          dosage_secondary_adult: (result.dosage_secondary_adult as string) || "",
          dosage_secondary_pediatric: (result.dosage_secondary_pediatric as string) || "",
          healthcare_level_required: (result.healthcare_level_required as string) || "",
          route_administration: (result.route_administration as string) || "",
          monitoring_requirements: (result.monitoring_requirements as string) || "",
          contraindications: (result.contraindications as string) || "",
          prevention_measures: (result.prevention_measures as string) || "",
          special_notes: (result.special_notes as string) || "",
          status: "draft",
          is_published: false,
          priority: (result.priority as string) || "",
          version: "1.0",
          categories: (result.categories as string[]) || [],
          tags: (result.tags as string[]) || [],
          index_item: (result.index_item as string) || "",
        })
      } catch (error) {
        console.error("Failed to load guideline to duplicate:", error)
        if (!cancelled) {
          showToast.error(
            "Duplicate Failed",
            "Couldn't load the source guideline to duplicate"
          )
        }
      } finally {
        if (!cancelled) setLoadingDuplicate(false)
      }
    }

    loadSource()
    return () => {
      cancelled = true
    }
  }, [duplicateFromId, form])

  const onSubmit = async (data: MedicalGuidelineForm) => {
    setIsSubmitting(true)
    try {
      const pb = getBackendClient()
      
      // Create the medical guideline record in legacy collection API
      const result = await pb.collection('medical_guidelines').create(data)

      console.log("Medical guideline created:", result)
      // Invalidate the guidelines list cache so the new record is visible
      // immediately on return to /guidelines (global staleTime is 60s otherwise).
      await queryClient.invalidateQueries({ queryKey: ["backend", "medical_guidelines"] })
      showToast.success("Success", "Medical guideline created successfully")
      router.push("/guidelines")
    } catch (error: unknown) {
      console.error("Failed to create medical guideline:", error)
      
      // Handle specific error types
      const errorObj = error as { status?: number }
      if (errorObj?.status === 403) {
        showToast.error("Permission Denied", "You don't have permission to create guidelines")
      } else if (errorObj?.status === 400) {
        showToast.error("Validation Error", "Please check your form data and try again")
      } else {
        showToast.error("Error", "Failed to create medical guideline. Please try again.")
      }
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title={duplicateFromId ? "Duplicate Medical Guideline" : "Create Medical Guideline"}
        description={
          duplicateFromId
            ? loadingDuplicate
              ? "Loading source guideline to duplicate…"
              : "Edit the prefilled fields, then save as a new guideline"
            : "Create a comprehensive clinical guideline for health workers"
        }
        showBackButton={true}
        onBack={() => router.push('/guidelines')}
        actions={[
          {
            label: isSubmitting ? "Saving..." : "Save",
            onClick: () => form.handleSubmit(onSubmit)(),
            icon: <Save className="h-4 w-4" />,
            disabled: isSubmitting || loadingDuplicate
          }
        ]}
      />

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="w-full space-y-6">
              {/* Basic Information */}
              <Card>
                <CardHeader>
                  <CardTitle>Basic Information</CardTitle>
                  <CardDescription>Essential details about the medical condition</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <FormField
                    control={form.control}
                    name="condition_name"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Condition Name *</FormLabel>
                        <FormControl>
                          <Input placeholder="e.g., Acute Respiratory Infection" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  
                  <div className="grid grid-cols-2 gap-4">
                    <FormField
                      control={form.control}
                      name="icd10_code"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>ICD-10 Code</FormLabel>
                          <FormControl>
                            <Input placeholder="e.g., J06.9" {...field} />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                    
                    <FormField
                      control={form.control}
                      name="target_population"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Target Population</FormLabel>
                          <FormControl>
                            <Input placeholder="e.g., Adults, Children 0-5 years" {...field} />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                  </div>
                  
                  <FormField
                    control={form.control}
                    name="categories"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Categories</FormLabel>
                        <FormControl>
                          <MultiGuidelineCategorySelector
                            value={field.value || []}
                            onValueChange={field.onChange}
                            placeholder="Select categories..."
                            className="w-full"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  
                  <FormField
                    control={form.control}
                    name="tags"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Tags</FormLabel>
                        <FormControl>
                          <TagsMultiSelector
                            value={field.value || []}
                            onValueChange={field.onChange}
                            className="w-full"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="index_item"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Index Assignment</FormLabel>
                        <FormControl>
                          <GuidelineIndexSelector
                            value={field.value || undefined}
                            onValueChange={(value) => field.onChange(value || "")}
                            placeholder="Select index item"
                            searchPlaceholder="Search index items..."
                            showRootOption={true}
                            rootOptionLabel="No Assignment (Root Level)"
                            allowClear={true}
                            className="w-full"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <FormField
                      control={form.control}
                      name="healthcare_level_required"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Healthcare Level Required</FormLabel>
                          <FormControl>
                            <Input placeholder="e.g., Primary Care, Hospital" {...field} />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />

                    <FormField
                      control={form.control}
                      name="route_administration"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Route of Administration</FormLabel>
                          <FormControl>
                            <Input placeholder="e.g., Oral, IV, IM" {...field} />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />

                    <FormField
                      control={form.control}
                      name="version"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Version</FormLabel>
                          <FormControl>
                            <Input placeholder="1.0" {...field} />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <FormField
                      control={form.control}
                      name="status"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Status</FormLabel>
                          <Select onValueChange={field.onChange} defaultValue={field.value}>
                            <FormControl>
                              <SelectTrigger className="w-full">
                                <SelectValue placeholder="Select status" />
                              </SelectTrigger>
                            </FormControl>
                            <SelectContent>
                              <SelectItem value="draft">Draft</SelectItem>
                              <SelectItem value="review">Under Review</SelectItem>
                              <SelectItem value="published">Published</SelectItem>
                              <SelectItem value="archived">Archived</SelectItem>
                            </SelectContent>
                          </Select>
                          <FormMessage />
                        </FormItem>
                      )}
                    />

                    <FormField
                      control={form.control}
                      name="priority"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Priority</FormLabel>
                          <Select onValueChange={field.onChange} defaultValue={field.value}>
                            <FormControl>
                              <SelectTrigger className="w-full">
                                <SelectValue placeholder="Select priority" />
                              </SelectTrigger>
                            </FormControl>
                            <SelectContent>
                              <SelectItem value="high">High</SelectItem>
                              <SelectItem value="medium">Medium</SelectItem>
                              <SelectItem value="low">Low</SelectItem>
                            </SelectContent>
                          </Select>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                  </div>
                  
                  <FormField
                    control={form.control}
                    name="is_published"
                    render={({ field }) => (
                      <FormItem className="flex flex-row items-center justify-between rounded-lg border p-3">
                        <div className="space-y-0.5">
                          <FormLabel>Published</FormLabel>
                          <div className="text-sm text-muted-foreground">
                            Make this guideline publicly available
                          </div>
                        </div>
                        <FormControl>
                          <Switch
                            checked={field.value}
                            onCheckedChange={field.onChange}
                          />
                        </FormControl>
                      </FormItem>
                    )}
                  />
                </CardContent>
              </Card>

              {/* Medical Content Tabs */}
              <Card>
                <CardHeader>
                  <CardTitle>Medical Content</CardTitle>
                  <CardDescription>Comprehensive medical information organized by category</CardDescription>
                </CardHeader>
                <CardContent>
                  <Tabs defaultValue="overview" className="space-y-6">
                    <TabsList className="grid grid-cols-4 w-full">
                      <TabsTrigger value="overview">Overview</TabsTrigger>
                      <TabsTrigger value="classification">Classification</TabsTrigger>
                      <TabsTrigger value="treatment">Treatment</TabsTrigger>
                      <TabsTrigger value="safety">Safety & Prevention</TabsTrigger>
                    </TabsList>

                    <TabsContent value="overview" className="space-y-6">
                      <EditorFormWrapper
                        title="Definition"
                        description="Medical definition of the condition"
                        value={form.watch("definition")}
                        onChange={(value) => form.setValue("definition", value)}
                        placeholder="Enter medical definition of the condition..."
                        minHeight="180px"
                        error={form.formState.errors.definition?.message}
                      />

                      <EditorFormWrapper
                        title="Causes"
                        description="Etiology and risk factors"
                        value={form.watch("causes")}
                        onChange={(value) => form.setValue("causes", value)}
                        placeholder="Enter causes and risk factors..."
                        minHeight="180px"
                        error={form.formState.errors.causes?.message}
                      />

                      <EditorFormWrapper
                        title="Clinical Features"
                        description="Signs and symptoms"
                        value={form.watch("clinical_features")}
                        onChange={(value) => form.setValue("clinical_features", value)}
                        placeholder="Enter clinical signs and symptoms..."
                        minHeight="180px"
                        error={form.formState.errors.clinical_features?.message}
                      />

                      <EditorFormWrapper
                        title="Differential Diagnosis"
                        description="Other conditions to consider and rule out"
                        value={form.watch("differential_diagnosis")}
                        onChange={(value) => form.setValue("differential_diagnosis", value)}
                        placeholder="Enter conditions to consider and rule out..."
                        minHeight="180px"
                        error={form.formState.errors.differential_diagnosis?.message}
                      />
                    </TabsContent>

                    <TabsContent value="classification" className="space-y-6">
                      <div className="space-y-6">
                        <div className="text-sm text-muted-foreground">
                          Define criteria for each severity level to help healthcare workers properly classify cases.
                        </div>
                        
                        <EditorFormWrapper
                          title="Mild Classification"
                          value={form.watch("classification_mild")}
                          onChange={(value) => form.setValue("classification_mild", value)}
                          placeholder="Enter mild classification criteria..."
                          minHeight="180px"
                          error={form.formState.errors.classification_mild?.message}
                        />
                        
                        <EditorFormWrapper
                          title="Moderate Classification"
                          value={form.watch("classification_moderate")}
                          onChange={(value) => form.setValue("classification_moderate", value)}
                          placeholder="Enter moderate classification criteria..."
                          minHeight="180px"
                          error={form.formState.errors.classification_moderate?.message}
                        />
                        
                        <EditorFormWrapper
                          title="Severe Classification"
                          value={form.watch("classification_severe")}
                          onChange={(value) => form.setValue("classification_severe", value)}
                          placeholder="Enter severe classification criteria..."
                          minHeight="180px"
                          error={form.formState.errors.classification_severe?.message}
                        />
                        
                        <EditorFormWrapper
                          title="Critical Classification"
                          value={form.watch("classification_critical")}
                          onChange={(value) => form.setValue("classification_critical", value)}
                          placeholder="Enter critical classification criteria..."
                          minHeight="180px"
                          error={form.formState.errors.classification_critical?.message}
                        />
                      </div>
                    </TabsContent>

                    <TabsContent value="treatment" className="space-y-6">
                      <EditorFormWrapper
                        title="General Management"
                        description="Treatment approach and general care"
                        value={form.watch("general_management")}
                        onChange={(value) => form.setValue("general_management", value)}
                        placeholder="Enter treatment approach and general care..."
                        minHeight="180px"
                        error={form.formState.errors.general_management?.message}
                      />

                      {/* Medications */}
                      <div className="space-y-6 border-t pt-6">
                        <div>
                          <h4 className="font-medium text-lg mb-2">Medications</h4>
                          <p className="text-sm text-muted-foreground">Primary and secondary medication options</p>
                        </div>
                        
                        {/* Primary Medication */}
                        <div className="space-y-4">
                          <h5 className="font-medium">Primary Medication</h5>
                          <FormField
                            control={form.control}
                            name="medication_primary"
                            render={({ field }) => (
                              <FormItem>
                                <FormLabel>Medication Name</FormLabel>
                                <FormControl>
                                  <Input placeholder="e.g., Amoxicillin" {...field} />
                                </FormControl>
                                <FormMessage />
                              </FormItem>
                            )}
                          />
                          
                          <EditorFormWrapper
                            title="Adult Dosage"
                            value={form.watch("dosage_adult")}
                            onChange={(value) => form.setValue("dosage_adult", value)}
                            placeholder="Enter adult dosage information..."
                            minHeight="180px"
                            error={form.formState.errors.dosage_adult?.message}
                          />
                          
                          <EditorFormWrapper
                            title="Pediatric Dosage"
                            value={form.watch("dosage_pediatric")}
                            onChange={(value) => form.setValue("dosage_pediatric", value)}
                            placeholder="Enter pediatric dosage information..."
                            minHeight="180px"
                            error={form.formState.errors.dosage_pediatric?.message}
                          />
                        </div>

                        {/* Secondary Medication */}
                        <div className="space-y-4">
                          <h5 className="font-medium">Secondary Medication (Alternative)</h5>
                          <FormField
                            control={form.control}
                            name="medication_secondary"
                            render={({ field }) => (
                              <FormItem>
                                <FormLabel>Medication Name</FormLabel>
                                <FormControl>
                                  <Input placeholder="e.g., Azithromycin" {...field} />
                                </FormControl>
                                <FormMessage />
                              </FormItem>
                            )}
                          />
                          
                          <EditorFormWrapper
                            title="Adult Dosage"
                            value={form.watch("dosage_secondary_adult")}
                            onChange={(value) => form.setValue("dosage_secondary_adult", value)}
                            placeholder="Enter secondary adult dosage information..."
                            minHeight="180px"
                            error={form.formState.errors.dosage_secondary_adult?.message}
                          />
                          
                          <EditorFormWrapper
                            title="Pediatric Dosage"
                            value={form.watch("dosage_secondary_pediatric")}
                            onChange={(value) => form.setValue("dosage_secondary_pediatric", value)}
                            placeholder="Enter secondary pediatric dosage information..."
                            minHeight="180px"
                            error={form.formState.errors.dosage_secondary_pediatric?.message}
                          />
                        </div>
                      </div>
                    </TabsContent>

                    <TabsContent value="safety" className="space-y-6">
                      <EditorFormWrapper
                        title="Monitoring Requirements"
                        description="Patient monitoring and safety considerations"
                        value={form.watch("monitoring_requirements")}
                        onChange={(value) => form.setValue("monitoring_requirements", value)}
                        placeholder="Enter patient monitoring requirements..."
                        minHeight="180px"
                        error={form.formState.errors.monitoring_requirements?.message}
                      />
                      
                      <EditorFormWrapper
                        title="Contraindications"
                        description="Contraindications and precautions"
                        value={form.watch("contraindications")}
                        onChange={(value) => form.setValue("contraindications", value)}
                        placeholder="Enter contraindications and precautions..."
                        minHeight="180px"
                        error={form.formState.errors.contraindications?.message}
                      />

                      <EditorFormWrapper
                        title="Prevention Measures"
                        description="Prevention strategies and measures"
                        value={form.watch("prevention_measures")}
                        onChange={(value) => form.setValue("prevention_measures", value)}
                        placeholder="Enter prevention strategies and measures..."
                        minHeight="180px"
                        error={form.formState.errors.prevention_measures?.message}
                      />
                      
                      <EditorFormWrapper
                        title="Special Notes"
                        description="Special considerations and additional notes"
                        value={form.watch("special_notes")}
                        onChange={(value) => form.setValue("special_notes", value)}
                        placeholder="Enter special considerations and additional notes..."
                        minHeight="180px"
                        error={form.formState.errors.special_notes?.message}
                      />
                    </TabsContent>
                  </Tabs>
                </CardContent>
              </Card>


          </div>
        </form>
      </Form>
    </div>
  )
}
