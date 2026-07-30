"use client"

import * as React from "react"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { z } from "zod"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"
import { RegionsResponse } from "@/types/backend-types"

const regionFormSchema = z.object({
  name: z.string().min(1, "Region name is required"),
  nhpi_code: z.string().min(1, "NHPI code is required"),
  hsdt_code: z.string().min(1, "HSDT code is required"),
})

type RegionFormValues = z.infer<typeof regionFormSchema>

interface CreateRegionModalProps {
  open: boolean
  onClose: () => void
  onSuccess?: () => void
  /** Pass an existing region to switch the modal into edit mode. */
  region?: RegionsResponse | null
}

const EMPTY_VALUES: RegionFormValues = { name: "", nhpi_code: "", hsdt_code: "" }

export function CreateRegionModal({ open, onClose, onSuccess, region }: CreateRegionModalProps) {
  const [isLoading, setIsLoading] = React.useState(false)
  const isEdit = !!region

  const form = useForm<RegionFormValues>({
    resolver: zodResolver(regionFormSchema),
    defaultValues: EMPTY_VALUES,
  })

  React.useEffect(() => {
    if (!open) return
    form.reset(
      region
        ? {
            name: region.name ?? "",
            nhpi_code: region.nhpi_code ?? "",
            hsdt_code: region.hsdt_code ?? "",
          }
        : EMPTY_VALUES
    )
  }, [open, region, form])

  const onSubmit = async (data: RegionFormValues) => {
    setIsLoading(true)
    const pb = getBackendClient()

    try {
      if (isEdit && region) {
        await pb.collection('regions').update(region.id, {
          name: data.name,
          nhpi_code: data.nhpi_code,
          hsdt_code: data.hsdt_code,
        })
        showToast.success("Success", "Region updated successfully")
      } else {
        await pb.collection('regions').create({
          name: data.name,
          nhpi_code: data.nhpi_code,
          hsdt_code: data.hsdt_code,
        })
        showToast.success("Success", "Region created successfully")
      }

      onSuccess?.()
      form.reset(EMPTY_VALUES)
      onClose()
    } catch (error) {
      console.error(`Failed to ${isEdit ? 'update' : 'create'} region:`, error)
      showToast.error("Error", `Failed to ${isEdit ? 'update' : 'create'} region`)
    } finally {
      setIsLoading(false)
    }
  }

  const handleClose = () => {
    form.reset(EMPTY_VALUES)
    onClose()
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit Region" : "Create Region"}</DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Update this region's details."
              : "Add a new region to the administrative hierarchy."}
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form key={open ? 'open' : 'closed'} onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Region Name</FormLabel>
                  <FormControl>
                    <Input placeholder="Enter region name" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="nhpi_code"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>NHPI Code</FormLabel>
                    <FormControl>
                      <Input placeholder="e.g., REG001" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="hsdt_code"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>HSDT Code</FormLabel>
                    <FormControl>
                      <Input placeholder="e.g., R/001" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

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
                  ? (isEdit ? "Saving..." : "Creating...")
                  : (isEdit ? "Save Changes" : "Create Region")}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}