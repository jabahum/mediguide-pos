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
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { FileUpload } from "@/components/ui/file-upload"
import { CalculatorsResponse, CalculatorsTypeOptions, CalculatorsStatusOptions, CalculatorsCategoryOptions, CalculatorsPriorityOptions } from "@/types/backend-types"
import { Calculator, Brain, CheckSquare, Palette, Settings, Info } from "lucide-react"

const decisionToolSchema = z.object({
  name: z.string().min(1, "Name is required").max(200, "Name must be less than 200 characters"),
  description: z.string().optional(),
  version: z.string().min(1, "Version is required").max(20, "Version must be less than 20 characters"),
  type: z.enum(["calculator", "decision_tool", "checklist"]),
  status: z.enum(["active", "draft", "archived"]),
  category: z.enum([
    "surgical",
    "emergency",
    "maternal",
    "pediatric",
    "cardiology",
    "neurology",
    "pharmacy",
    "nutrition",
    "infection_control",
    "safety",
    "general",
  ]),
  priority: z.enum(["critical", "high", "medium", "low"]),
  appFile: z.any().refine(
    (value) => {
      // Check if value exists and is not empty
      if (!value || value === "" || value === null || value === undefined) {
        return false
      }
      // Accept strings (existing file paths) or File objects
      return typeof value === 'string' || (value && typeof value === 'object' && value.constructor && value.constructor.name === 'File')
    },
    "App file is required"
  ),
  icon: z.string().optional(),
  color: z.string().optional(),
  backgroundColor: z.string().optional(),
})

type DecisionToolFormData = z.infer<typeof decisionToolSchema>

interface DecisionToolFormProps {
  initialData?: Partial<CalculatorsResponse>
  onSubmit: (data: DecisionToolFormData) => Promise<void>
  onCancel: () => void
  loading?: boolean
  mode: "create" | "edit"
}

const typeOptions = [
  { 
    value: "calculator", 
    label: "Calculator",
    description: "Mathematical calculators for clinical scoring",
    icon: <Calculator className="h-4 w-4" />
  },
  { 
    value: "decision_tool", 
    label: "Decision Tool",
    description: "Decision trees and clinical pathways",
    icon: <Brain className="h-4 w-4" />
  },
  { 
    value: "checklist", 
    label: "Checklist",
    description: "Step-by-step clinical checklists",
    icon: <CheckSquare className="h-4 w-4" />
  },
]

const statusOptions = [
  { value: "active", label: "Active", description: "Available for use by all users" },
  { value: "draft", label: "Draft", description: "Under development, not yet published" },
  { value: "archived", label: "Archived", description: "No longer available for new use" },
]

const categoryOptions = [
  { value: "surgical", label: "Surgical" },
  { value: "emergency", label: "Emergency" },
  { value: "maternal", label: "Maternal" },
  { value: "pediatric", label: "Pediatric" },
  { value: "cardiology", label: "Cardiology" },
  { value: "neurology", label: "Neurology" },
  { value: "pharmacy", label: "Pharmacy" },
  { value: "nutrition", label: "Nutrition" },
  { value: "infection_control", label: "Infection Control" },
  { value: "safety", label: "Safety" },
  { value: "general", label: "General" },
]

const priorityOptions = [
  { value: "critical", label: "Critical", description: "Life-threatening or time-sensitive" },
  { value: "high", label: "High", description: "Significant clinical impact" },
  { value: "medium", label: "Medium", description: "Standard clinical use" },
  { value: "low", label: "Low", description: "Informational or supportive" },
]

export function DecisionToolForm({ 
  initialData, 
  onSubmit, 
  onCancel, 
  loading = false,
  mode 
}: DecisionToolFormProps) {
  const [activeTab, setActiveTab] = React.useState("basic")
  const [appFile, setAppFile] = React.useState<File | string | null>(initialData?.appFile || null)

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    setValue,
    watch,
  } = useForm<DecisionToolFormData>({
    resolver: zodResolver(decisionToolSchema),
    defaultValues: {
      name: initialData?.name || "",
      description: initialData?.description || "",
      version: initialData?.version || "1.0.0",
      type: initialData?.type || CalculatorsTypeOptions.calculator,
      status: initialData?.status || CalculatorsStatusOptions.draft,
      category: initialData?.category || CalculatorsCategoryOptions.general,
      priority: initialData?.priority || CalculatorsPriorityOptions.medium,
      appFile: initialData?.appFile || null,
      icon: initialData?.icon || "",
      color: initialData?.color || "",
      backgroundColor: initialData?.backgroundColor || "",
    },
  })

  const watchedType = watch("type")
  const watchedStatus = watch("status")
  const watchedCategory = watch("category")
  const watchedPriority = watch("priority")

  const onFormSubmit = async (data: DecisionToolFormData) => {
    try {
      // Include the app file from state
      const submitData = {
        ...data,
        appFile: appFile
      }
      await onSubmit(submitData)
    } catch (error) {
      console.error("Form submission error:", error)
    }
  }

  const getTypeIcon = (type: string) => {
    const option = typeOptions.find(opt => opt.value === type)
    return option?.icon || <Calculator className="h-4 w-4" />
  }

  const isFormLoading = loading || isSubmitting

  return (
    <form onSubmit={handleSubmit(onFormSubmit)} className="space-y-6">
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="basic" className="flex items-center gap-1">
            <Info className="h-4 w-4" />
            Basic Info
          </TabsTrigger>
          <TabsTrigger value="config" className="flex items-center gap-1">
            <Settings className="h-4 w-4" />
            Configuration
          </TabsTrigger>
          <TabsTrigger value="advanced" className="flex items-center gap-1">
            <Palette className="h-4 w-4" />
            Advanced
          </TabsTrigger>
        </TabsList>

        <TabsContent value="basic" className="mt-6 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Basic Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Tool Name */}
              <div className="space-y-2">
                <Label htmlFor="name">Tool Name *</Label>
                <Input
                  id="name"
                  {...register("name")}
                  placeholder="Enter the decision tool name"
                  className={errors.name ? "border-destructive" : ""}
                  disabled={isFormLoading}
                />
                {errors.name && (
                  <p className="text-sm text-destructive">{errors.name.message}</p>
                )}
              </div>

              {/* Description */}
              <div className="space-y-2">
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  {...register("description")}
                  placeholder="Describe what this tool does and how it should be used"
                  rows={4}
                  className={errors.description ? "border-destructive" : ""}
                  disabled={isFormLoading}
                />
                {errors.description && (
                  <p className="text-sm text-destructive">{errors.description.message}</p>
                )}
              </div>

              {/* Type Selection */}
              <div className="space-y-2">
                <Label htmlFor="type">Tool Type *</Label>
                <Select 
                  value={watchedType} 
                  onValueChange={(value) => setValue("type", value as CalculatorsTypeOptions)}
                  disabled={isFormLoading}
                >
                  <SelectTrigger className={`w-full ${errors.type ? "border-destructive" : ""}`}>
                    <SelectValue>
                      <div className="flex items-center gap-2">
                        {getTypeIcon(watchedType)}
                        <span>{typeOptions.find(opt => opt.value === watchedType)?.label}</span>
                      </div>
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent>
                    {typeOptions.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        <div className="flex items-start gap-3 py-2">
                          {option.icon}
                          <div>
                            <div className="font-medium">{option.label}</div>
                            <div className="text-sm text-muted-foreground">{option.description}</div>
                          </div>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.type && (
                  <p className="text-sm text-destructive">{errors.type.message}</p>
                )}
              </div>

              {/* Status Selection */}
              <div className="space-y-2">
                <Label htmlFor="status">Status *</Label>
                <Select 
                  value={watchedStatus} 
                  onValueChange={(value) => setValue("status", value as CalculatorsStatusOptions)}
                  disabled={isFormLoading}
                >
                  <SelectTrigger className={`w-full ${errors.status ? "border-destructive" : ""}`}>
                    <SelectValue placeholder="Select status" />
                  </SelectTrigger>
                  <SelectContent>
                    {statusOptions.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        <div className="py-1">
                          <div className="font-medium">{option.label}</div>
                          <div className="text-sm text-muted-foreground">{option.description}</div>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.status && (
                  <p className="text-sm text-destructive">{errors.status.message}</p>
                )}
              </div>

              {/* Category Selection */}
              <div className="space-y-2">
                <Label htmlFor="category">Category *</Label>
                <Select
                  value={watchedCategory}
                  onValueChange={(value) => setValue("category", value as CalculatorsCategoryOptions)}
                  disabled={isFormLoading}
                >
                  <SelectTrigger className={`w-full ${errors.category ? "border-destructive" : ""}`}>
                    <SelectValue placeholder="Select category" />
                  </SelectTrigger>
                  <SelectContent>
                    {categoryOptions.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.category && (
                  <p className="text-sm text-destructive">{errors.category.message}</p>
                )}
              </div>

              {/* Priority Selection */}
              <div className="space-y-2">
                <Label htmlFor="priority">Priority *</Label>
                <Select
                  value={watchedPriority}
                  onValueChange={(value) => setValue("priority", value as CalculatorsPriorityOptions)}
                  disabled={isFormLoading}
                >
                  <SelectTrigger className={`w-full ${errors.priority ? "border-destructive" : ""}`}>
                    <SelectValue placeholder="Select priority" />
                  </SelectTrigger>
                  <SelectContent>
                    {priorityOptions.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        <div className="py-1">
                          <div className="font-medium">{option.label}</div>
                          <div className="text-sm text-muted-foreground">{option.description}</div>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.priority && (
                  <p className="text-sm text-destructive">{errors.priority.message}</p>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="config" className="mt-6 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Technical Configuration</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Version */}
              <div className="space-y-2">
                <Label htmlFor="version">Version *</Label>
                <Input
                  id="version"
                  {...register("version")}
                  placeholder="1.0.0"
                  className={errors.version ? "border-destructive" : ""}
                  disabled={isFormLoading}
                />
                <p className="text-sm text-muted-foreground">
                  Semantic versioning recommended (e.g., 1.0.0)
                </p>
                {errors.version && (
                  <p className="text-sm text-destructive">{errors.version.message}</p>
                )}
              </div>

              {/* App File */}
              <div className="space-y-2">
                <Label>App File *</Label>
                <FileUpload
                  value={appFile || undefined}
                  onValueChange={(file) => {
                    setAppFile(file)
                    setValue("appFile", file)
                  }}
                  accept=".html,.htm,.js,.jsx,.ts,.tsx,.vue,.svelte"
                  maxSize={50}
                  placeholder="Upload your decision tool application file"
                  disabled={isFormLoading}
                  error={errors.appFile?.message as string}
                />
                <p className="text-sm text-muted-foreground">
                  Upload the HTML, JavaScript, or web application file for this tool
                </p>
              </div>

              {/* Icon */}
              <div className="space-y-2">
                <Label htmlFor="icon">Icon</Label>
                <Input
                  id="icon"
                  {...register("icon")}
                  placeholder="🧮"
                  className={errors.icon ? "border-destructive" : ""}
                  disabled={isFormLoading}
                />
                <p className="text-sm text-muted-foreground">
                  Emoji or icon identifier (optional)
                </p>
                {errors.icon && (
                  <p className="text-sm text-destructive">{errors.icon.message}</p>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="advanced" className="mt-6 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Visual & Advanced Settings</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Color */}
              <div className="space-y-2">
                <Label htmlFor="color">Primary Color</Label>
                <div className="flex gap-2">
                  <Input
                    id="color"
                    {...register("color")}
                    placeholder="#3b82f6"
                    className={`${errors.color ? "border-destructive" : ""} font-mono`}
                    disabled={isFormLoading}
                  />
                  <input
                    type="color"
                    value={watch("color") || "#3b82f6"}
                    onChange={(e) => setValue("color", e.target.value)}
                    className="w-12 h-10 border border-input rounded cursor-pointer"
                    disabled={isFormLoading}
                  />
                </div>
                <p className="text-sm text-muted-foreground">
                  Primary color for the tool interface
                </p>
                {errors.color && (
                  <p className="text-sm text-destructive">{errors.color.message}</p>
                )}
              </div>

              {/* Background Color */}
              <div className="space-y-2">
                <Label htmlFor="backgroundColor">Background Color</Label>
                <div className="flex gap-2">
                  <Input
                    id="backgroundColor"
                    {...register("backgroundColor")}
                    placeholder="#f8fafc"
                    className={`${errors.backgroundColor ? "border-destructive" : ""} font-mono`}
                    disabled={isFormLoading}
                  />
                  <input
                    type="color"
                    value={watch("backgroundColor") || "#f8fafc"}
                    onChange={(e) => setValue("backgroundColor", e.target.value)}
                    className="w-12 h-10 border border-input rounded cursor-pointer"
                    disabled={isFormLoading}
                  />
                </div>
                <p className="text-sm text-muted-foreground">
                  Background color for the tool interface
                </p>
                {errors.backgroundColor && (
                  <p className="text-sm text-destructive">{errors.backgroundColor.message}</p>
                )}
              </div>

            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Form Actions */}
      <div className="flex items-center justify-end gap-4 pt-6 border-t">
        <Button
          type="button"
          variant="outline"
          onClick={onCancel}
          disabled={isFormLoading}
        >
          Cancel
        </Button>
        <Button
          type="submit"
          disabled={isFormLoading}
        >
          {isFormLoading && (
            <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" />
          )}
          {mode === "create" ? "Create Tool" : "Update Tool"}
        </Button>
      </div>
    </form>
  )
}