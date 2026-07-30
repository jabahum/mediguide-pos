"use client"

import * as React from "react"
import { useForm, ControllerRenderProps } from "react-hook-form"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { RelationCombobox, RelationSelectConfig } from "@/components/ui/datatable-filter-value-input"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"

export type AdminFieldDef =
  | {
      name: string
      label: string
      type: "text"
      required?: boolean
      placeholder?: string
      /** layout column span when used in the 2-col grid; defaults to full width */
      span?: "full" | "half"
    }
  | {
      name: string
      label: string
      type: "relation"
      required?: boolean
      placeholder?: string
      relation: RelationSelectConfig
      span?: "full" | "half"
    }

interface AdminEntityModalProps {
  open: boolean
  onClose: () => void
  collection: string
  entityLabel: string
  fields: AdminFieldDef[]
  record?: Record<string, unknown> | null
  onSuccess?: () => void
}

type FormValues = Record<string, string>

function buildDefaults(fields: AdminFieldDef[], record?: Record<string, unknown> | null): FormValues {
  const out: FormValues = {}
  for (const f of fields) {
    const raw = record?.[f.name]
    out[f.name] = raw == null ? "" : String(raw)
  }
  return out
}

export function AdminEntityModal({
  open,
  onClose,
  collection,
  entityLabel,
  fields,
  record,
  onSuccess,
}: AdminEntityModalProps) {
  const [isLoading, setIsLoading] = React.useState(false)
  const isEdit = !!record

  const form = useForm<FormValues>({
    defaultValues: buildDefaults(fields),
  })

  React.useEffect(() => {
    if (!open) return
    form.reset(buildDefaults(fields, record))
  }, [open, record, fields, form])

  const validate = (values: FormValues): { ok: boolean; firstError?: string } => {
    for (const f of fields) {
      if (f.required !== false) {
        const v = values[f.name]?.trim?.()
        if (!v) {
          form.setError(f.name, { type: "required", message: `${f.label} is required` })
          return { ok: false, firstError: f.name }
        }
      }
    }
    return { ok: true }
  }

  const onSubmit = async (values: FormValues) => {
    const result = validate(values)
    if (!result.ok) return

    setIsLoading(true)
    const backend = getBackendClient()
    try {
      const payload: Record<string, string> = {}
      for (const f of fields) {
        payload[f.name] = values[f.name]
      }

      if (isEdit && record) {
        await backend.resource(collection).update(String(record.id), payload)
        showToast.success("Success", `${entityLabel} updated successfully`)
      } else {
        await backend.resource(collection).create(payload)
        showToast.success("Success", `${entityLabel} created successfully`)
      }

      onSuccess?.()
      form.reset(buildDefaults(fields))
      onClose()
    } catch (error) {
      console.error(`Failed to ${isEdit ? "update" : "create"} ${entityLabel}:`, error)
      const message =
        error instanceof Error
          ? error.message
          : `Failed to ${isEdit ? "update" : "create"} ${entityLabel.toLowerCase()}`
      showToast.error("Error", message)
    } finally {
      setIsLoading(false)
    }
  }

  const handleClose = () => {
    form.reset(buildDefaults(fields))
    onClose()
  }

  // Group fields by span for layout (consecutive halves get paired)
  const renderField = (def: AdminFieldDef, field: ControllerRenderProps<FormValues, string>) => {
    if (def.type === "relation") {
      return (
        <RelationCombobox
          relation={def.relation}
          value={field.value || ""}
          onChange={(v) => field.onChange(v)}
          placeholder={def.placeholder ?? `Select ${def.label.toLowerCase()}`}
        />
      )
    }
    return (
      <Input
        placeholder={def.placeholder ?? `Enter ${def.label.toLowerCase()}`}
        {...field}
      />
    )
  }

  // Layout: text fields with span="half" pair up; everything else is full-width
  const layout: { kind: "single"; field: AdminFieldDef }[] | { kind: "pair"; a: AdminFieldDef; b: AdminFieldDef }[] = []
  type Row = { kind: "single"; field: AdminFieldDef } | { kind: "pair"; a: AdminFieldDef; b: AdminFieldDef }
  const rows: Row[] = []
  for (let i = 0; i < fields.length; i++) {
    const f = fields[i]
    const next = fields[i + 1]
    if (f.span === "half" && next?.span === "half") {
      rows.push({ kind: "pair", a: f, b: next })
      i++
    } else {
      rows.push({ kind: "single", field: f })
    }
  }
  void layout

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>
            {isEdit ? `Edit ${entityLabel}` : `Create ${entityLabel}`}
          </DialogTitle>
          <DialogDescription>
            {isEdit
              ? `Update this ${entityLabel.toLowerCase()}'s details.`
              : `Add a new ${entityLabel.toLowerCase()}.`}
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form
            key={open ? "open" : "closed"}
            onSubmit={form.handleSubmit(onSubmit)}
            className="space-y-4"
          >
            {rows.map((row, idx) => {
              if (row.kind === "pair") {
                return (
                  <div key={idx} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {[row.a, row.b].map((def) => (
                      <FormField
                        key={def.name}
                        control={form.control}
                        name={def.name}
                        render={({ field }) => (
                          <FormItem>
                            <FormLabel>{def.label}</FormLabel>
                            <FormControl>{renderField(def, field)}</FormControl>
                            <FormMessage />
                          </FormItem>
                        )}
                      />
                    ))}
                  </div>
                )
              }
              const def = row.field
              return (
                <FormField
                  key={def.name}
                  control={form.control}
                  name={def.name}
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>{def.label}</FormLabel>
                      <FormControl>{renderField(def, field)}</FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              )
            })}

            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={handleClose}
                disabled={isLoading}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={isLoading}>
                {isLoading
                  ? isEdit
                    ? "Saving..."
                    : "Creating..."
                  : isEdit
                    ? "Save Changes"
                    : `Create ${entityLabel}`}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}
