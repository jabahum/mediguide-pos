"use client"

import * as React from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Textarea } from "@/components/ui/textarea"
import {
  EmergencyProtocolsCategoryOptions,
  EmergencyProtocolsPriorityOptions,
  EmergencyProtocolsStatusOptions,
} from "@/types/backend-types"
import {
  EmergencyProtocolRecord,
  parseOptionalJsonField,
  parseTags,
  stringifyJsonField,
} from "../protocol-helpers"

const emergencyProtocolSchema = z.object({
  title: z.string().min(1, "Title is required").max(200, "Title must be less than 200 characters"),
  description: z.string().optional(),
  category: z.nativeEnum(EmergencyProtocolsCategoryOptions),
  priority: z.nativeEnum(EmergencyProtocolsPriorityOptions),
  status: z.nativeEnum(EmergencyProtocolsStatusOptions),
  timeframe: z.string().optional(),
  tagsText: z.string().optional(),
  stepsText: z.string().optional(),
  criticalActionsText: z.string().optional(),
  medicationsText: z.string().optional(),
  vitalSignsText: z.string().optional(),
  transferChecklistText: z.string().optional(),
  contactInfoText: z.string().optional(),
})

type EmergencyProtocolFormValues = z.infer<typeof emergencyProtocolSchema>

export type EmergencyProtocolPayload = {
  title: string
  description?: string
  category: EmergencyProtocolsCategoryOptions
  priority: EmergencyProtocolsPriorityOptions
  status: EmergencyProtocolsStatusOptions
  timeframe?: string
  tags?: string[]
  steps?: unknown
  critical_actions?: unknown
  medications?: unknown
  vital_signs?: unknown
  transfer_checklist?: unknown
  contact_info?: unknown
}

interface EmergencyProtocolFormProps {
  initialData?: EmergencyProtocolRecord | null
  onSubmit: (data: EmergencyProtocolPayload) => Promise<void>
  onCancel: () => void
  loading?: boolean
  mode: "create" | "edit"
}

const categoryOptions = Object.values(EmergencyProtocolsCategoryOptions)
const priorityOptions = Object.values(EmergencyProtocolsPriorityOptions)
const statusOptions = Object.values(EmergencyProtocolsStatusOptions)

function normalizeText(value?: string | null) {
  return value || ""
}

export function EmergencyProtocolForm({
  initialData,
  onSubmit,
  onCancel,
  loading = false,
  mode,
}: EmergencyProtocolFormProps) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    setValue,
    watch,
  } = useForm<EmergencyProtocolFormValues>({
    resolver: zodResolver(emergencyProtocolSchema),
    defaultValues: {
      title: initialData?.title || "",
      description: normalizeText(initialData?.description),
      category: initialData?.category || EmergencyProtocolsCategoryOptions["Emergency Medicine"],
      priority: initialData?.priority || EmergencyProtocolsPriorityOptions.medium,
      status: initialData?.status || EmergencyProtocolsStatusOptions.draft,
      timeframe: normalizeText(initialData?.timeframe),
      tagsText: Array.isArray(initialData?.tags) ? initialData.tags.join(", ") : "",
      stepsText: stringifyJsonField(initialData?.steps),
      criticalActionsText: stringifyJsonField(initialData?.critical_actions),
      medicationsText: stringifyJsonField(initialData?.medications),
      vitalSignsText: stringifyJsonField(initialData?.vital_signs),
      transferChecklistText: stringifyJsonField(initialData?.transfer_checklist),
      contactInfoText: stringifyJsonField(initialData?.contact_info),
    },
  })

  const watchedCategory = watch("category")
  const watchedPriority = watch("priority")
  const watchedStatus = watch("status")

  const isFormLoading = loading || isSubmitting

  const submitForm = async (values: EmergencyProtocolFormValues) => {
    const payload: EmergencyProtocolPayload = {
      title: values.title.trim(),
      description: values.description?.trim() || undefined,
      category: values.category,
      priority: values.priority,
      status: values.status,
      timeframe: values.timeframe?.trim() || undefined,
    }

    const tags = parseTags(values.tagsText || "")
    if (tags.length > 0) {
      payload.tags = tags
    }

    payload.steps = parseOptionalJsonField(values.stepsText || "", "Steps")
    payload.critical_actions = parseOptionalJsonField(
      values.criticalActionsText || "",
      "Critical actions"
    )
    payload.medications = parseOptionalJsonField(values.medicationsText || "", "Medications")
    payload.vital_signs = parseOptionalJsonField(values.vitalSignsText || "", "Vital signs")
    payload.transfer_checklist = parseOptionalJsonField(
      values.transferChecklistText || "",
      "Transfer checklist"
    )
    payload.contact_info = parseOptionalJsonField(values.contactInfoText || "", "Contact info")

    await onSubmit(payload)
  }

  return (
    <form onSubmit={handleSubmit(submitForm)} className="space-y-6">
      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="workflow">Workflow Data</TabsTrigger>
          <TabsTrigger value="supporting">Supporting Data</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>
                {mode === "create" ? "Create Protocol" : "Edit Protocol"}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="title">Title *</Label>
                <Input
                  id="title"
                  {...register("title")}
                  placeholder="e.g. Adult Cardiac Arrest"
                  disabled={isFormLoading}
                />
                {errors.title && (
                  <p className="text-sm text-destructive">{errors.title.message}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  {...register("description")}
                  rows={4}
                  placeholder="Short operational summary for this protocol"
                  disabled={isFormLoading}
                />
              </div>

              <div className="grid gap-4 md:grid-cols-3">
                <div className="space-y-2">
                  <Label>Category *</Label>
                  <Select
                    value={watchedCategory}
                    onValueChange={(value) =>
                      setValue("category", value as EmergencyProtocolsCategoryOptions)
                    }
                    disabled={isFormLoading}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select category" />
                    </SelectTrigger>
                    <SelectContent>
                      {categoryOptions.map((option) => (
                        <SelectItem key={option} value={option}>
                          {option}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Priority *</Label>
                  <Select
                    value={watchedPriority}
                    onValueChange={(value) =>
                      setValue("priority", value as EmergencyProtocolsPriorityOptions)
                    }
                    disabled={isFormLoading}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select priority" />
                    </SelectTrigger>
                    <SelectContent>
                      {priorityOptions.map((option) => (
                        <SelectItem key={option} value={option}>
                          {option}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Status *</Label>
                  <Select
                    value={watchedStatus}
                    onValueChange={(value) =>
                      setValue("status", value as EmergencyProtocolsStatusOptions)
                    }
                    disabled={isFormLoading}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select status" />
                    </SelectTrigger>
                    <SelectContent>
                      {statusOptions.map((option) => (
                        <SelectItem key={option} value={option}>
                          {option}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="timeframe">Timeframe</Label>
                  <Input
                    id="timeframe"
                    {...register("timeframe")}
                    placeholder="e.g. First 5 minutes"
                    disabled={isFormLoading}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="tagsText">Tags</Label>
                  <Input
                    id="tagsText"
                    {...register("tagsText")}
                    placeholder="coma, airway, triage"
                    disabled={isFormLoading}
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="workflow" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Workflow JSON</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="stepsText">Steps</Label>
                <Textarea
                  id="stepsText"
                  {...register("stepsText")}
                  rows={10}
                  placeholder='[{"step":"Assess airway","order":1}]'
                  disabled={isFormLoading}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="criticalActionsText">Critical Actions</Label>
                <Textarea
                  id="criticalActionsText"
                  {...register("criticalActionsText")}
                  rows={8}
                  placeholder='["Call senior clinician","Prepare oxygen"]'
                  disabled={isFormLoading}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="transferChecklistText">Transfer Checklist</Label>
                <Textarea
                  id="transferChecklistText"
                  {...register("transferChecklistText")}
                  rows={8}
                  placeholder='["Stabilize airway","Document handover summary"]'
                  disabled={isFormLoading}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="supporting" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Supporting JSON</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="medicationsText">Medications</Label>
                <Textarea
                  id="medicationsText"
                  {...register("medicationsText")}
                  rows={8}
                  placeholder='[{"name":"Adrenaline","dose":"1mg IV"}]'
                  disabled={isFormLoading}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="vitalSignsText">Vital Signs</Label>
                <Textarea
                  id="vitalSignsText"
                  {...register("vitalSignsText")}
                  rows={8}
                  placeholder='{"pulse":"60-100 bpm","spo2":">94%"}'
                  disabled={isFormLoading}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="contactInfoText">Contact Info</Label>
                <Textarea
                  id="contactInfoText"
                  {...register("contactInfoText")}
                  rows={8}
                  placeholder='{"referralDesk":"+256...","ambulance":"+256..."}'
                  disabled={isFormLoading}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <div className="flex items-center justify-end gap-3">
        <Button type="button" variant="outline" onClick={onCancel} disabled={isFormLoading}>
          Cancel
        </Button>
        <Button type="submit" disabled={isFormLoading}>
          {mode === "create" ? "Create Protocol" : "Save Changes"}
        </Button>
      </div>
    </form>
  )
}
