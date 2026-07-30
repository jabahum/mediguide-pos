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
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"
import { RegionsResponse, HealthSubRegionsResponse } from "@/types/backend-types"

const districtFormSchema = z.object({
  name: z.string().min(1, "District name is required"),
  region: z.string().min(1, "Region is required"),
  health_sub_region: z.string().min(1, "Health sub region is required"),
  nhpi_code: z.string().min(1, "NHPI code is required"),
  hsdt_code: z.string().min(1, "HSDT code is required"),
})

type DistrictFormValues = z.infer<typeof districtFormSchema>

interface CreateDistrictModalProps {
  open: boolean
  onClose: () => void
  onSuccess?: () => void
}

export function CreateDistrictModal({ open, onClose, onSuccess }: CreateDistrictModalProps) {
  const [isLoading, setIsLoading] = React.useState(false)
  const [regions, setRegions] = React.useState<RegionsResponse[]>([])
  const [healthSubRegions, setHealthSubRegions] = React.useState<HealthSubRegionsResponse[]>([])

  const form = useForm<DistrictFormValues>({
    resolver: zodResolver(districtFormSchema),
    defaultValues: {
      name: "",
      region: "",
      health_sub_region: "",
      nhpi_code: "",
      hsdt_code: "",
    },
  })

  // Load regions and health sub regions when modal opens
  React.useEffect(() => {
    if (open) {
      const loadData = async () => {
        const backend = getBackendClient()
        try {
          const [regionsData, healthSubRegionsData] = await Promise.all([
            backend.resource('regions').getFullList({
              sort: 'name',
            }),
            backend.resource('health_sub_regions').getFullList({
              sort: 'name',
            })
          ])
          setRegions(regionsData as RegionsResponse[])
          setHealthSubRegions(healthSubRegionsData as HealthSubRegionsResponse[])
        } catch (error) {
          console.error("Failed to load data:", error)
          showToast.error("Error", "Failed to load form data")
        }
      }
      loadData()
    }
  }, [open])

  const onSubmit = async (data: DistrictFormValues) => {
    setIsLoading(true)
    const backend = getBackendClient()

    try {
      await backend.resource('districts').create({
        name: data.name,
        region: data.region,
        health_sub_region: data.health_sub_region,
        nhpi_code: data.nhpi_code,
        hsdt_code: data.hsdt_code,
      })
      
      showToast.success("Success", "District created successfully")
      onSuccess?.()
      form.reset({
        name: "",
        region: "",
        health_sub_region: "",
        nhpi_code: "",
        hsdt_code: "",
      })
      onClose()
    } catch (error) {
      console.error("Failed to create district:", error)
      showToast.error("Error", "Failed to create district")
    } finally {
      setIsLoading(false)
    }
  }

  const handleClose = () => {
    form.reset({
      name: "",
      region: "",
      health_sub_region: "",
      nhpi_code: "",
      hsdt_code: "",
    })
    onClose()
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Create District</DialogTitle>
          <DialogDescription>
            Add a new district to the administrative hierarchy.
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form key={open ? 'open' : 'closed'} onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="region"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Region</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select region" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {regions.map((region) => (
                        <SelectItem key={region.id} value={region.id}>
                          {region.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="health_sub_region"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Health Sub Region</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select health sub region" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {healthSubRegions.map((hsr) => (
                        <SelectItem key={hsr.id} value={hsr.id}>
                          {hsr.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>District Name</FormLabel>
                  <FormControl>
                    <Input placeholder="Enter district name" {...field} />
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
                      <Input placeholder="e.g., DIS001" {...field} />
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
                      <Input placeholder="e.g., D/001" {...field} />
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
                {isLoading ? "Creating..." : "Create District"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}