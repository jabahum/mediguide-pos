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
import { CountiesResponse, DistrictsResponse } from "@/types/backend-types"

const subcountyFormSchema = z.object({
  name: z.string().min(1, "Subcounty name is required"),
  county: z.string().min(1, "County is required"),
  district: z.string().min(1, "District is required"),
  nhpi_code: z.string().min(1, "NHPI code is required"),
  hsdt_code: z.string().min(1, "HSDT code is required"),
})

type SubcountyFormValues = z.infer<typeof subcountyFormSchema>

interface CreateSubcountyModalProps {
  open: boolean
  onClose: () => void
  onSuccess?: () => void
}

export function CreateSubcountyModal({ open, onClose, onSuccess }: CreateSubcountyModalProps) {
  const [isLoading, setIsLoading] = React.useState(false)
  const [counties, setCounties] = React.useState<CountiesResponse[]>([])
  const [districts, setDistricts] = React.useState<DistrictsResponse[]>([])

  const form = useForm<SubcountyFormValues>({
    resolver: zodResolver(subcountyFormSchema),
    defaultValues: {
      name: "",
      county: "",
      district: "",
      nhpi_code: "",
      hsdt_code: "",
    },
  })

  // Load counties and districts when modal opens
  React.useEffect(() => {
    if (open) {
      const loadData = async () => {
        const backend = getBackendClient()
        try {
          const [countiesData, districtsData] = await Promise.all([
            backend.resource('counties').getFullList({
              sort: 'name',
              expand: 'district',
            }),
            backend.resource('districts').getFullList({
              sort: 'name',
            })
          ])
          setCounties(countiesData as CountiesResponse[])
          setDistricts(districtsData as DistrictsResponse[])
        } catch (error) {
          console.error("Failed to load data:", error)
          showToast.error("Error", "Failed to load form data")
        }
      }
      loadData()
    }
  }, [open])

  const onSubmit = async (data: SubcountyFormValues) => {
    setIsLoading(true)
    const backend = getBackendClient()

    try {
      await backend.resource('subcounties').create({
        name: data.name,
        county: data.county,
        district: data.district,
        nhpi_code: data.nhpi_code,
        hsdt_code: data.hsdt_code,
      })
      
      showToast.success("Success", "Subcounty created successfully")
      onSuccess?.()
      form.reset({
        name: "",
        county: "",
        district: "",
        nhpi_code: "",
        hsdt_code: "",
      })
      onClose()
    } catch (error) {
      console.error("Failed to create subcounty:", error)
      showToast.error("Error", "Failed to create subcounty")
    } finally {
      setIsLoading(false)
    }
  }

  const handleClose = () => {
    form.reset({
      name: "",
      county: "",
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
          <DialogTitle>Create Subcounty</DialogTitle>
          <DialogDescription>
            Add a new subcounty to the administrative hierarchy.
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form key={open ? 'open' : 'closed'} onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="county"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>County</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select county" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {counties.map((county) => (
                        <SelectItem key={county.id} value={county.id}>
                          {county.name}
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
                  <FormLabel>Subcounty Name</FormLabel>
                  <FormControl>
                    <Input placeholder="Enter subcounty name" {...field} />
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
                      <Input placeholder="e.g., SUB001" {...field} />
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
                      <Input placeholder="e.g., S/001" {...field} />
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
                {isLoading ? "Creating..." : "Create Subcounty"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}