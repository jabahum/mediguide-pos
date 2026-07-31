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
import { healthFacilitiesService } from "@/services/health-facilities.service"
import { SubcountiesResponse } from "@/types/backend-types"

const parishFormSchema = z.object({
  name: z.string().min(1, "Parish name is required"),
  subcounty: z.string().min(1, "Subcounty is required"),
  nhpi_code: z.string().min(1, "NHPI code is required"),
  hsdt_code: z.string().min(1, "HSDT code is required"),
})

type ParishFormValues = z.infer<typeof parishFormSchema>

interface CreateParishModalProps {
  open: boolean
  onClose: () => void
  onSuccess?: () => void
}

export function CreateParishModal({ open, onClose, onSuccess }: CreateParishModalProps) {
  const [isLoading, setIsLoading] = React.useState(false)
  const [subcounties, setSubcounties] = React.useState<SubcountiesResponse[]>([])

  const form = useForm<ParishFormValues>({
    resolver: zodResolver(parishFormSchema),
    defaultValues: {
      name: "",
      subcounty: "",
      nhpi_code: "",
      hsdt_code: "",
    },
  })

  // Load subcounties when modal opens
  React.useEffect(() => {
    if (open) {
      const loadSubcounties = async () => {
        try {
          const data = await healthFacilitiesService.subcounties()
          setSubcounties(data as SubcountiesResponse[])
        } catch (error) {
          console.error("Failed to load subcounties:", error)
          showToast.error("Error", "Failed to load subcounties")
        }
      }
      loadSubcounties()
    }
  }, [open])

  const onSubmit = async (data: ParishFormValues) => {
    setIsLoading(true)

    try {
      await healthFacilitiesService.createParish({
        name: data.name,
        subcounty: data.subcounty,
        nhpi_code: data.nhpi_code,
        hsdt_code: data.hsdt_code,
      })
      
      showToast.success("Success", "Parish created successfully")
      onSuccess?.()
      form.reset({
        name: "",
        subcounty: "",
        nhpi_code: "",
        hsdt_code: "",
      })
      onClose()
    } catch (error) {
      console.error("Failed to create parish:", error)
      showToast.error("Error", "Failed to create parish")
    } finally {
      setIsLoading(false)
    }
  }

  const handleClose = () => {
    form.reset({
      name: "",
      subcounty: "",
      nhpi_code: "",
      hsdt_code: "",
    })
    onClose()
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Create Parish</DialogTitle>
          <DialogDescription>
            Add a new parish to the administrative hierarchy.
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form key={open ? 'open' : 'closed'} onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="subcounty"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Subcounty</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select subcounty" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {subcounties.map((subcounty) => (
                        <SelectItem key={subcounty.id} value={subcounty.id}>
                          {subcounty.name}
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
                  <FormLabel>Parish Name</FormLabel>
                  <FormControl>
                    <Input placeholder="Enter parish name" {...field} />
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
                      <Input placeholder="e.g., PAR001" {...field} />
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
                      <Input placeholder="e.g., P/001" {...field} />
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
                {isLoading ? "Creating..." : "Create Parish"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}
