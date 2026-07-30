"use client"

import * as React from "react"
import { useRouter, useParams } from "next/navigation"
import { useForm, Controller } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import { Save } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Separator } from "@/components/ui/separator"
import { Skeleton } from "@/components/ui/skeleton"
import { useQueryClient } from "@tanstack/react-query"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"
import { usersService } from "@/services/user-management.service"
import { backendRecordKeyPrefix } from "@/hooks/use-backend-record"
import { 
  UsersStatusOptions, 
 
  UsersPreferredLanguageOptions,
  UsersResponse 
} from "@/types/backend-types"
import { useRoleOptions, useRoleValidation } from "@/hooks/use-roles-options"
import { usePermissionContext } from "@/lib/permission-context"

// Create the schema as a function that accepts role validation
const editUserSchemaFn = (validateRole: (key: string) => boolean) => z.object({
  // Required fields
  name: z.string().min(1, "Name is required"),
  phone: z.string().min(1, "Phone number is required").regex(/^[+]?[0-9\s\-\(\)]{7,20}$/, "Invalid phone format"),
  role: z.string().min(1, "Role is required").refine(validateRole, { message: "Invalid role selected" }),
  status: z.nativeEnum(UsersStatusOptions),
  
  // Optional fields
  alternativePhone: z.string().optional().refine(
    (val) => !val || /^[+]?[0-9\s\-\(\)]{7,20}$/.test(val), 
    { message: "Invalid phone format" }
  ),
  avatar: z.string().optional(),
  address: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  country: z.string().optional(),
  postalCode: z.string().optional(),
  department: z.string().optional(),
  organization: z.string().optional(),
  jobTitle: z.string().optional(),
  licenseNumber: z.string().optional(),
  specialization: z.string().optional(),
  preferredLanguage: z.nativeEnum(UsersPreferredLanguageOptions).optional(),
  timezone: z.string().optional(),
  notes: z.string().optional(),
})

// Get the type by inferring from a sample schema
type EditUserFormData = z.infer<ReturnType<typeof editUserSchemaFn>>

export default function EditUserPage() {
  const router = useRouter()
  const params = useParams()
  const userId = params.id as string
  const queryClient = useQueryClient()
  
  const { hasPermission, loading: permLoading } = usePermissionContext()

  const [isLoading, setIsLoading] = React.useState(false)
  const [isLoadingUser, setIsLoadingUser] = React.useState(true)
  const [user, setUser] = React.useState<UsersResponse | null>(null)
  const { roleOptions, loading: rolesLoading } = useRoleOptions()

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("users", "update:any")) {
      router.replace("/users")
    }
  }, [permLoading, hasPermission, router])
  const { validateRoleKey } = useRoleValidation()
  
  // Create the schema with role validation
  const editUserSchema = React.useMemo(() => 
    editUserSchemaFn(validateRoleKey), 
    [validateRoleKey]
  )
  
  const form = useForm<EditUserFormData>({
    resolver: zodResolver(editUserSchema),
  })

  const { handleSubmit, formState: { errors }, control, reset, setError } = form
  
  // Load user data on component mount
  React.useEffect(() => {
    const abortController = new AbortController()
    
    const loadUser = async () => {
      try {
        // Skip if component is unmounted
        if (abortController.signal.aborted) return
        console.log('Loading user with ID:', userId)
        console.log('User ID type:', typeof userId)
        
        // Validate user ID
        if (!userId || userId === 'undefined' || userId === 'null') {
          console.error('Invalid user ID:', userId)
          showToast.error("Invalid User ID", "The user ID is not valid")
          router.push('/users')
          return
        }
        
        const backend = getBackendClient()
        console.log('legacy collection API URL:', backend.baseUrl)
        
        // Check if authenticated
        if (!backend.authStore.isValid) {
          console.error('Not authenticated')
          showToast.error("Authentication Error", "Please log in to continue")
          router.push('/login')
          return
        }
        
        console.log('Auth store valid, user:', backend.authStore.record?.email)
        
        // Test connection first
        try {
          const testConnection = await usersService.list({ page: 1, per_page: 1 })
          console.log('Connection test successful, found users:', testConnection.total_items)
        } catch (connError) {
          console.error('Connection test failed:', connError)
        }
        
        const userData = await usersService.get<UsersResponse>(userId)
        console.log('Loaded user data:', userData)
        setUser(userData as UsersResponse)
        
        // Reset form with user data
        reset({
          name: userData.name || '',
          phone: userData.phone || '',
          alternativePhone: userData.alternativePhone || '',
          role: userData.role,
          status: userData.status,
          organization: userData.organization || '',
          department: userData.department || '',
          jobTitle: userData.jobTitle || '',
          licenseNumber: userData.licenseNumber || '',
          specialization: Array.isArray(userData.specialization)
            ? userData.specialization.join(", ")
            : userData.specialization || "",
          country: userData.country || '',
          state: userData.state || '',
          city: userData.city || '',
          address: userData.address || '',
          postalCode: userData.postalCode || '',
          preferredLanguage: userData.preferredLanguage || UsersPreferredLanguageOptions.english,
          timezone: userData.timezone || '',
          notes: userData.notes || '',
        })
        
      } catch (error: unknown) {
        // Skip error handling if component was unmounted (auto-cancel)
        if (abortController.signal.aborted) return
        
        console.error('Failed to load user:', error)
        
        // Check if this is an auto-cancel error and ignore it
        if (error && typeof error === 'object' && 'name' in error && 
            (error as { name: string }).name === 'AbortError') {
          console.log('Request was cancelled (component unmounted)')
          return
        }
        
        let errorMessage = 'Could not load user data'
        let errorTitle = 'Load Failed'
        
        if (error && typeof error === 'object') {
          if ('status' in error) {
            const status = (error as { status: number }).status
            if (status === 404) {
              errorTitle = 'User Not Found'
              errorMessage = 'The requested user does not exist'
            } else if (status === 403) {
              errorTitle = 'Access Denied'
              errorMessage = 'You do not have permission to view this user'
            } else if (status === 401) {
              errorTitle = 'Authentication Required'
              errorMessage = 'Please log in to continue'
            }
          }
          
          if ('message' in error) {
            const message = String((error as { message: unknown }).message)
            console.error('Error message:', message)
            if (message.includes('Failed to fetch')) {
              errorTitle = 'Connection Error'
              errorMessage = 'Could not connect to the server. Please check your connection.'
            }
          }
        }
        
        showToast.error(errorTitle, errorMessage)
        router.push('/users')
      } finally {
        if (!abortController.signal.aborted) {
          setIsLoadingUser(false)
        }
      }
    }

    if (userId) {
      loadUser()
    }
    
    // Cleanup function to cancel request if component unmounts
    return () => {
      abortController.abort()
    }
  }, [userId, reset, router])

  // Specialization is now a simple string field

  const onSubmit = async (data: EditUserFormData) => {
    if (!user) return
    
    setIsLoading(true)
    
    try {
      const backend = getBackendClient()
      
      // Update user record in legacy collection API
      const userData = {
        ...data,
        // Ensure specialization is properly formatted for legacy collection API
        specialization: data.specialization || [],
        // Always ensure this field remains true
        emailVisibility: true,
      }
      
      await usersService.update(userId, userData)

      await queryClient.invalidateQueries({ queryKey: backendRecordKeyPrefix('users', userId) })

      showToast.success(
        "User Updated Successfully",
        `${data.name} has been updated`
      )

      // Navigate back to users list
      router.push('/users')
      
    } catch (error: unknown) {
      console.error('Failed to update user:', error)
      
      // Handle legacy collection API validation errors using React Hook Form best practices
      if (error && typeof error === 'object' && 'data' in error) {
        const errorResponse = error as { 
          data: Record<string, { message: string; code: string }>,
          status: number 
        }
        
        // Process each field error from legacy collection API and set using React Hook Form
        const errorMessages: string[] = []
        Object.entries(errorResponse.data).forEach(([fieldName, fieldError]) => {
          if (fieldError && typeof fieldError === 'object' && 'message' in fieldError) {
            // Use setError with exact field name - React Hook Form will handle the rest
            setError(fieldName as keyof EditUserFormData, {
              type: 'server',
              message: fieldError.message
            })
            
            // Collect error messages for toast
            const fieldLabel = fieldName.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())
            errorMessages.push(`${fieldLabel}: ${fieldError.message}`)
          }
        })
        
        // Show specific error messages
        const errorMessage = errorMessages.length === 1 
          ? errorMessages[0]
          : `Multiple validation errors:\n• ${errorMessages.join('\n• ')}`
          
        showToast.error("Validation Failed", errorMessage)
      } else {
        // Handle other types of errors
        const errorMessage = error && typeof error === 'object' && 'message' in error 
          ? String((error as { message: unknown }).message)
          : 'An unexpected error occurred'
        
        showToast.error("Update Failed", errorMessage)
      }
    } finally {
      setIsLoading(false)
    }
  }

  const handleCancel = () => {
    router.push('/users')
  }

  if (isLoadingUser) {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-start">
          <div className="space-y-2">
            <Skeleton className="h-8 w-48" />
            <Skeleton className="h-4 w-96" />
          </div>
          <div className="flex space-x-2">
            <Skeleton className="h-9 w-20" />
            <Skeleton className="h-9 w-28" />
          </div>
        </div>
        
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <Skeleton className="h-6 w-48" />
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <Skeleton className="h-10" />
                <Skeleton className="h-10" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <Skeleton className="h-10" />
                <Skeleton className="h-10" />
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <p className="text-muted-foreground">User not found</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={`Edit User: ${user.name}`}
        description="Update user information and settings"
        showBackButton={true}
        onBack={handleCancel}
        actions={[
          {
            label: isLoading ? "Saving..." : "Save Changes",
            onClick: () => handleSubmit(onSubmit)(),
            icon: <Save className="h-4 w-4" />,
            disabled: isLoading
          }
        ]}
      />

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Personal Information */}
        <Card>
          <CardHeader>
            <CardTitle>Personal Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="name">Full Name *</Label>
                <Controller
                  name="name"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="name"
                      placeholder="Enter full name"
                      className={errors.name ? "border-destructive" : ""}
                    />
                  )}
                />
                {errors.name && (
                  <p className="text-sm text-destructive">{errors.name.message}</p>
                )}
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="phone">Phone Number *</Label>
                <Controller
                  name="phone"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="phone"
                      placeholder="+256 700 000 000"
                      className={errors.phone ? "border-destructive" : ""}
                    />
                  )}
                />
                {errors.phone && (
                  <p className="text-sm text-destructive">{errors.phone.message}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="alternativePhone">Alternative Phone</Label>
                <Controller
                  name="alternativePhone"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="alternativePhone"
                      placeholder="Optional alternative number"
                      className={errors.alternativePhone ? "border-destructive" : ""}
                    />
                  )}
                />
                {errors.alternativePhone && (
                  <p className="text-sm text-destructive">{errors.alternativePhone.message}</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Professional Information */}
        <Card>
          <CardHeader>
            <CardTitle>Professional Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="role">Role *</Label>
                <Controller
                  name="role"
                  control={control}
                  render={({ field }) => (
                    <Select value={field.value} onValueChange={field.onChange} disabled={rolesLoading}>
                      <SelectTrigger className={`w-full ${errors.role ? "border-destructive" : ""}`}>
                        <SelectValue placeholder={rolesLoading ? "Loading roles..." : "Select role"} />
                      </SelectTrigger>
                      <SelectContent>
                        {roleOptions.map((role) => (
                          <SelectItem key={role.value} value={role.value}>
                            {role.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  )}
                />
                {errors.role && (
                  <p className="text-sm text-destructive">{errors.role.message}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="status">Status *</Label>
                <Controller
                  name="status"
                  control={control}
                  render={({ field }) => (
                    <Select value={field.value} onValueChange={field.onChange}>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select status" />
                      </SelectTrigger>
                      <SelectContent>
                        {Object.values(UsersStatusOptions).map((status) => (
                          <SelectItem key={status} value={status}>
                            {status.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  )}
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="organization">Organization</Label>
                <Controller
                  name="organization"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="organization"
                      placeholder="Healthcare organization"
                    />
                  )}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="department">Department</Label>
                <Controller
                  name="department"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="department"
                      placeholder="Department or ward"
                    />
                  )}
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="jobTitle">Job Title</Label>
                <Controller
                  name="jobTitle"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="jobTitle"
                      placeholder="Professional job title"
                    />
                  )}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="licenseNumber">License Number</Label>
                <Controller
                  name="licenseNumber"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="licenseNumber"
                      placeholder="Professional license number"
                    />
                  )}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="specialization">Specialization</Label>
              <Controller
                control={control}
                name="specialization"
                render={({ field }) => (
                  <Input
                    {...field}
                    id="specialization"
                    placeholder="e.g., General Practice, Pediatrics, etc."
                  />
                )}
              />
              {errors.specialization && (
                <p className="text-sm text-destructive">{errors.specialization.message}</p>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Location Information */}
        <Card>
          <CardHeader>
            <CardTitle>Location Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="country">Country</Label>
                <Controller
                  name="country"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="country"
                      placeholder="Country"
                    />
                  )}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="state">State/Region</Label>
                <Controller
                  name="state"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="state"
                      placeholder="State or region"
                    />
                  )}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="city">City</Label>
                <Controller
                  name="city"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="city"
                      placeholder="City"
                    />
                  )}
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="address">Address</Label>
                <Controller
                  name="address"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="address"
                      placeholder="Street address"
                    />
                  )}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="postalCode">Postal Code</Label>
                <Controller
                  name="postalCode"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="postalCode"
                      placeholder="Postal code"
                    />
                  )}
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* System Settings */}
        <Card>
          <CardHeader>
            <CardTitle>System Settings</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="preferredLanguage">Preferred Language</Label>
                <Controller
                  name="preferredLanguage"
                  control={control}
                  render={({ field }) => (
                    <Select value={field.value} onValueChange={field.onChange}>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select language" />
                      </SelectTrigger>
                      <SelectContent>
                        {Object.values(UsersPreferredLanguageOptions).map((lang) => (
                          <SelectItem key={lang} value={lang}>
                            {lang}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  )}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="timezone">Timezone</Label>
                <Controller
                  name="timezone"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="timezone"
                      placeholder="e.g., Africa/Kampala"
                    />
                  )}
                />
              </div>
            </div>



            <Separator />

            <div className="space-y-2">
              <Label htmlFor="notes">Additional Notes</Label>
              <Controller
                name="notes"
                control={control}
                render={({ field }) => (
                  <Textarea
                    {...field}
                    id="notes"
                    placeholder="Any additional information about this user"
                    rows={3}
                  />
                )}
              />
            </div>
          </CardContent>
        </Card>

        {/* Hidden submit button for form handling */}
        <button type="submit" className="hidden" aria-label="Submit form" disabled={isLoading} />
      </form>
    </div>
  )
}
