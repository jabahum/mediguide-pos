"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { notFound } from "next/navigation"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import type { Resolver } from "react-hook-form"
import * as z from "zod"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { Checkbox } from "@/components/ui/checkbox"
import { PageHeader } from "@/components/ui/page-header"
import { useQueryClient } from "@tanstack/react-query"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"
import { backendRecordKeyPrefix } from "@/hooks/use-backend-record"
import { SpecialtyOptions } from "../../columns"
import type { Consultant } from "../../columns"
import { usePermissionContext, WithPermission } from "@/lib/permission-context"

interface EditConsultantPageProps {
  params: Promise<{
    id: string
  }>
}

const consultantFormSchema = z.object({
  // Basic Information
  name: z.string().min(2, "Name must be at least 2 characters"),
  email: z.string().email("Invalid email address"),
  phone: z.string().min(7, "Phone number must be at least 7 characters"),
  alternativePhone: z.string().optional(),
  
  // Professional Information
  specialty: z.string().min(1, "Specialty is required"),
  licenseNumber: z.string().optional(),
  yearsOfExperience: z.coerce.number().optional(),
  qualifications: z.array(z.string()).optional(),
  certifications: z.string().optional(),
  
  // Location Information
  address: z.string().optional(),
  city: z.string().optional(),
  region: z.string().optional(),
  country: z.string().min(1, "Country is required"),
  postalCode: z.string().optional(),
  
  // Organization Information
  organization: z.string().optional(),
  department: z.string().optional(),
  
  // Settings & Preferences
  preferredLanguage: z.string().optional(),
  timezone: z.string().optional(),
  consultationTypes: z.array(z.string()).optional(),
  
  // Performance fields
  rating: z.coerce.number().optional(),
  totalConsultations: z.coerce.number().optional(),
  
  // System Information
  status: z.enum(["active", "inactive", "pending_approval", "suspended"]),
  isVerified: z.boolean().optional(),
  notes: z.string().optional(),
})

type ConsultantFormValues = z.infer<typeof consultantFormSchema>

const LanguageOptions = [
  "English", "French", "Spanish", "Portuguese", "Arabic", "Swahili", "Amharic", "Other"
]

export default function EditConsultantPage({ params }: EditConsultantPageProps) {
  const router = useRouter()
  const queryClient = useQueryClient()
  const { hasPermission, loading } = usePermissionContext()
  const [id, setId] = React.useState<string | null>(null)
  const [consultant, setConsultant] = React.useState<Consultant | null>(null)
  const [isLoading, setIsLoading] = React.useState(false)
  const [isLoadingData, setIsLoadingData] = React.useState(true)

  const form = useForm<ConsultantFormValues>({
    resolver: zodResolver(consultantFormSchema) as Resolver<ConsultantFormValues>,
  })

  // Get params
  React.useEffect(() => {
    params.then(({ id }) => setId(id))
  }, [params])

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "update:any")) {
      showToast.error("Access Denied", "You do not have permission to edit consultants")
      router.replace("/consultants")
    }
  }, [loading, hasPermission, router])

  React.useEffect(() => {
    if (!id) return

    async function fetchConsultant() {
      try {
        const backend = getBackendClient()
        const record = await backend.resource('consultants').getOne(id!) as Consultant
        setConsultant(record)
        
        // Populate form with existing data
        form.reset({
          name: record.name,
          email: record.email,
          phone: record.phone,
          alternativePhone: record.alternativePhone || '',
          specialty: record.specialty,
          licenseNumber: record.licenseNumber || '',
          yearsOfExperience: record.yearsOfExperience || 0,
          qualifications: record.qualifications || [],
          certifications: record.certifications || '',
          address: record.address || '',
          city: record.city || '',
          region: record.region || '',
          country: record.country,
          postalCode: record.postalCode || '',
          organization: record.organization || '',
          department: record.department || '',
          preferredLanguage: record.preferredLanguage || 'English',
          timezone: record.timezone || '',
          consultationTypes: record.consultationTypes || [],
          rating: record.rating || 0,
          totalConsultations: record.totalConsultations || 0,
          status: record.status,
          isVerified: record.isVerified || false,
          notes: record.notes || '',
        })
      } catch (error) {
        console.error('Error fetching consultant:', error)
        notFound()
      } finally {
        setIsLoadingData(false)
      }
    }

    fetchConsultant()
  }, [id, form])

  async function onSubmit(data: ConsultantFormValues) {
    setIsLoading(true)
    const backend = getBackendClient()
    
    try {
      await backend.resource('consultants').update(id!, data)

      await queryClient.invalidateQueries({ queryKey: backendRecordKeyPrefix('consultants', id!) })

      showToast.success(
        "Consultant Updated",
        `${data.name} has been successfully updated`
      )

      router.push(`/consultants/${id!}`)
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to update consultant'
      showToast.error("Update Failed", message)
      console.error('Error updating consultant:', error)
    } finally {
      setIsLoading(false)
    }
  }

  if (isLoadingData || !id) {
    return (
      <div className="space-y-6">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-1/4 mb-2"></div>
          <div className="h-4 bg-gray-200 rounded w-1/2"></div>
        </div>
        <div className="space-y-4">
          <div className="animate-pulse h-32 bg-gray-200 rounded-lg"></div>
          <div className="animate-pulse h-48 bg-gray-200 rounded-lg"></div>
        </div>
      </div>
    )
  }

  if (!consultant) {
    notFound()
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Edit Consultant"
        description={`Update profile information for ${consultant.name}`}
        showBackButton={true}
        onBack={() => router.push(`/consultants/${consultant.id}`)}
      />

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          {/* Basic Information */}
          <Card>
            <CardHeader>
              <CardTitle>Basic Information</CardTitle>
              <CardDescription>
                Core contact information and identification details
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Full Name *</FormLabel>
                      <FormControl>
                        <Input placeholder="Dr. John Smith" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="email"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Email Address *</FormLabel>
                      <FormControl>
                        <Input type="email" placeholder="john.smith@hospital.com" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="phone"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Primary Phone *</FormLabel>
                      <FormControl>
                        <Input placeholder="+1 (555) 123-4567" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="alternativePhone"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Alternative Phone</FormLabel>
                      <FormControl>
                        <Input placeholder="+1 (555) 765-4321" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            </CardContent>
          </Card>

          {/* Professional Information */}
          <Card>
            <CardHeader>
              <CardTitle>Professional Information</CardTitle>
              <CardDescription>
                Medical specialty, qualifications, and professional credentials
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="specialty"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Medical Specialty *</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select specialty" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {SpecialtyOptions.map((specialty) => (
                            <SelectItem key={specialty} value={specialty}>
                              {specialty}
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
                  name="yearsOfExperience"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Years of Experience</FormLabel>
                      <FormControl>
                        <Input type="number" min="0" placeholder="10" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="licenseNumber"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>License Number</FormLabel>
                      <FormControl>
                        <Input placeholder="MD123456" {...field} />
                      </FormControl>
                      <FormDescription>
                        Professional medical license or registration number
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="certifications"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Additional Certifications</FormLabel>
                      <FormControl>
                        <Input placeholder="Board Certified in Internal Medicine" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            </CardContent>
          </Card>

          {/* Location & Organization */}
          <Card>
            <CardHeader>
              <CardTitle>Location & Organization</CardTitle>
              <CardDescription>
                Geographic location and institutional affiliation
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <FormField
                control={form.control}
                name="organization"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Organization/Institution</FormLabel>
                    <FormControl>
                      <Input placeholder="General Hospital" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="department"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Department</FormLabel>
                      <FormControl>
                        <Input placeholder="Emergency Medicine" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="country"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Country *</FormLabel>
                      <FormControl>
                        <Input placeholder="United States" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <FormField
                  control={form.control}
                  name="city"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>City</FormLabel>
                      <FormControl>
                        <Input placeholder="New York" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="region"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>State/Region</FormLabel>
                      <FormControl>
                        <Input placeholder="NY" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="postalCode"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Postal Code</FormLabel>
                      <FormControl>
                        <Input placeholder="10001" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <FormField
                control={form.control}
                name="address"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Street Address</FormLabel>
                    <FormControl>
                      <Textarea 
                        placeholder="123 Medical Center Drive"
                        className="resize-none"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </CardContent>
          </Card>

          {/* Performance & System Information */}
          <Card>
            <CardHeader>
              <CardTitle>Performance & System Information</CardTitle>
              <CardDescription>
                Professional metrics and account settings
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <FormField
                  control={form.control}
                  name="rating"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Rating</FormLabel>
                      <FormControl>
                        <Input 
                          type="number" 
                          min="0" 
                          max="5" 
                          step="0.1" 
                          placeholder="4.5" 
                          {...field} 
                        />
                      </FormControl>
                      <FormDescription>
                        Average rating (0-5 scale)
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="totalConsultations"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Total Consultations</FormLabel>
                      <FormControl>
                        <Input type="number" min="0" placeholder="25" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="status"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Status</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select status" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="pending_approval">Pending Approval</SelectItem>
                          <SelectItem value="active">Active</SelectItem>
                          <SelectItem value="inactive">Inactive</SelectItem>
                          <SelectItem value="suspended">Suspended</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="preferredLanguage"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Preferred Language</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select language" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {LanguageOptions.map((language) => (
                            <SelectItem key={language} value={language}>
                              {language}
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
                  name="timezone"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Timezone</FormLabel>
                      <FormControl>
                        <Input placeholder="UTC-5 (EST)" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <FormField
                control={form.control}
                name="isVerified"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-start space-x-3 space-y-0">
                    <FormControl>
                      <Checkbox
                        checked={field.value}
                        onCheckedChange={field.onChange}
                      />
                    </FormControl>
                    <div className="space-y-1 leading-none">
                      <FormLabel>
                        Mark as Verified
                      </FormLabel>
                      <FormDescription>
                        Check this if the consultant&apos;s credentials have been verified
                      </FormDescription>
                    </div>
                  </FormItem>
                )}
              />
            </CardContent>
          </Card>

          {/* Notes */}
          <Card>
            <CardHeader>
              <CardTitle>Additional Notes</CardTitle>
              <CardDescription>
                Internal notes and comments about this consultant
              </CardDescription>
            </CardHeader>
            <CardContent>
              <FormField
                control={form.control}
                name="notes"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Notes</FormLabel>
                    <FormControl>
                      <Textarea 
                        placeholder="Any additional notes or comments..."
                        className="resize-none"
                        rows={4}
                        {...field}
                      />
                    </FormControl>
                    <FormDescription>
                      These notes are for internal use only and won&apos;t be visible to consultants
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </CardContent>
          </Card>

          {/* Submit Buttons */}
          <div className="flex gap-4">
            <WithPermission resource="content" action="update:any">
              <Button type="submit" disabled={isLoading}>
                {isLoading ? "Updating..." : "Update Consultant"}
              </Button>
            </WithPermission>
            <Button
              type="button"
              variant="outline"
              onClick={() => router.push(`/consultants/${consultant.id}`)}
            >
              Cancel
            </Button>
          </div>
        </form>
      </Form>
    </div>
  )
}