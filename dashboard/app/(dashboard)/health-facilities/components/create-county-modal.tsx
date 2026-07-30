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
import { DistrictsResponse } from "@/types/backend-types"

const countyFormSchema = z.object({
  name: z.string().min(1, "County name is required"),
  district: z.string().min(1, "District is required"),
  nhpi_code: z.string().min(1, "NHPI code is required"),
  hsdt_code: z.string().min(1, "HSDT code is required"),
})

type CountyFormValues = z.infer<typeof countyFormSchema>

interface CreateCountyModalProps {
  open: boolean
  onClose: () => void
  onSuccess?: () => void
}

export function CreateCountyModal({ open, onClose, onSuccess }: CreateCountyModalProps) {
  const [isLoading, setIsLoading] = React.useState(false)
  const [districts, setDistricts] = React.useState<DistrictsResponse[]>([])

  const form = useForm<CountyFormValues>({
    resolver: zodResolver(countyFormSchema),
    defaultValues: {
      name: "",
      district: "",
      nhpi_code: "",
      hsdt_code: "",
    },
  })

  // Load districts when modal opens
  React.useEffect(() => {
    if (open) {
      const loadDistricts = async () => {
        const backend = getBackendClient()
        try {
          const data = await backend.resource('districts').getFullList({
            sort: 'name',
          })
          setDistricts(data as DistrictsResponse[])
        } catch (error) {
          console.error("Failed to load districts:", error)
          showToast.error("Error", "Failed to load districts")
        }
      }
      loadDistricts()
    }
  }, [open])

  const onSubmit = async (data: CountyFormValues) => {
    setIsLoading(true)
    const backend = getBackendClient()

    try {
      await backend.resource('counties').create({
        name: data.name,
        district: data.district,
        nhpi_code: data.nhpi_code,
        hsdt_code: data.hsdt_code,
      })
      
      showToast.success("Success", "County created successfully")
      onSuccess?.()
      form.reset({
        name: "",
        district: "",
        nhpi_code: "",
        hsdt_code: "",
      })
      onClose()
    } catch (error) {
      console.error("Failed to create county:", error)
      showToast.error("Error", "Failed to create county")
    } finally {
      setIsLoading(false)
    }
  }

  const handleClose = () => {
    form.reset({
      name: "",
      district: "",
      nhpi_code: "",
      hsdt_code: "",
    })
    onClose()
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Create County</DialogTitle>
          <DialogDescription>
            Add a new county to the administrative hierarchy.
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form key={open ? 'open' : 'closed'} onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="district"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>District</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select district" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {districts.map((district) => (
                        <SelectItem key={district.id} value={district.id}>
                          {district.name}
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
                  <FormLabel>County Name</FormLabel>
                  <FormControl>
                    <Input placeholder="Enter county name" {...field} />
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
                      <Input placeholder="e.g., CTY001" {...field} />
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
                      <Input placeholder="e.g., C/001" {...field} />
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
                {isLoading ? "Creating..." : "Create County"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}