"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { useForm, Controller } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import { Save } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { usePermissionContext } from "@/lib/permission-context"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Separator } from "@/components/ui/separator"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"
import { 
  UsersStatusOptions, 
 
  UsersPreferredLanguageOptions 
} from "@/types/backend-types"
import { useRoleOptions, useRoleValidation } from "@/hooks/use-roles-options"

// Create the schema as a function that accepts role validation
const createUserSchemaFn = (validateRole: (key: string) => boolean) => z.object({
  // Required fields
  name: z.string().min(1, "Name is required"),
  email: z.string().email("Invalid email address"),
  phone: z.string().min(1, "Phone number is required").regex(/^[+]?[0-9\s\-\(\)]{7,20}$/, "Invalid phone format"),
  password: z.string().min(8, "Password must be at least 8 characters"),
  passwordConfirm: z.string(),
  role: z.string().min(1, "Role is required").refine(validateRole, { message: "Invalid role selected" }),
  status: z.nativeEnum(UsersStatusOptions),
  
  // Optional fields
  alternativePhone: z.string().optional(),
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
}).refine(data => data.password === data.passwordConfirm, {
  message: "Passwords don't match",
  path: ["passwordConfirm"],
})

// Get the type by inferring from a sample schema
type CreateUserFormData = z.infer<ReturnType<typeof createUserSchemaFn>>

const defaultValues: Partial<CreateUserFormData> = {
  name: "",
  email: "",
  phone: "",
  password: "",
  passwordConfirm: "",
  role: "",
  status: UsersStatusOptions.pendingActivation,
  preferredLanguage: UsersPreferredLanguageOptions.english,
  specialization: "",
  avatar: "",
  alternativePhone: "",
  address: "",
  city: "",
  state: "",
  country: "",
  postalCode: "",
  department: "",
  organization: "",
  jobTitle: "",
  licenseNumber: "",
  timezone: "",
  notes: "",
}

export default function CreateUserPage() {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [isLoading, setIsLoading] = React.useState(false)
  const { roleOptions, loading: rolesLoading } = useRoleOptions()

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("users", "create:any")) {
      router.replace("/users")
    }
  }, [permLoading, hasPermission, router])
  const { validateRoleKey } = useRoleValidation()
  
  // Create the schema with role validation
  const createUserSchema = React.useMemo(() => 
    createUserSchemaFn(validateRoleKey), 
    [validateRoleKey]
  )
  
  const form = useForm<CreateUserFormData>({
    resolver: zodResolver(createUserSchema),
    defaultValues,
  })

  const { handleSubmit, formState: { errors }, control } = form
  
  // No specialization logic needed since it's now a simple string

  const onSubmit = async (data: CreateUserFormData) => {
    setIsLoading(true)
    
    try {
      const pb = getBackendClient()
      
      // Create user record in legacy collection API
      const userData = {
        ...data,
        // Specialization as string
        specialization: data.specialization || "",
        // Always set this field to true
        emailVisibility: true,
      }
      
      await pb.collection('users').create(userData)
      
      showToast.success(
        "User Created Successfully",
        `${data.name} has been added to the system`
      )
      
      // Navigate back to users list
      router.push('/users')
      
    } catch (error: unknown) {
      console.error('Failed to create user:', error)
      if (error && typeof error === 'object' && 'data' in error) {
        console.error('legacy collection API field errors:', JSON.stringify(error.data, null, 2))
      }
      
      let errorMessage = 'Failed to create user'
      if (error && typeof error === 'object' && 'data' in error) {
        // Handle legacy collection API validation errors
        const errorData = error.data as Record<string, unknown>
        const pbErrors = Object.entries(errorData).map(([field, msgs]) => {
          const message = typeof msgs === 'object' && msgs !== null && 'message' in msgs 
            ? String((msgs as { message: unknown }).message)
            : String(msgs)
          return `${field}: ${message}`
        }).join('\n')
        errorMessage = pbErrors || errorMessage
      } else if (error && typeof error === 'object' && 'message' in error) {
        errorMessage = String((error as { message: unknown }).message)
      }
      
      showToast.error("Creation Failed", errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const handleCancel = () => {
    router.push('/users')
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Create New User"
        description="Add a new healthcare worker to the MediGuide platform"
        showBackButton={true}
        onBack={handleCancel}
        actions={[
          {
            label: isLoading ? "Creating..." : "Save User",
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
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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

              <div className="space-y-2">
                <Label htmlFor="email">Email Address *</Label>
                <Controller
                  name="email"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="email"
                      type="email"
                      placeholder="user@example.com"
                      className={errors.email ? "border-destructive" : ""}
                    />
                  )}
                />
                {errors.email && (
                  <p className="text-sm text-destructive">{errors.email.message}</p>
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
                    />
                  )}
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="password">Password *</Label>
                <Controller
                  name="password"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="password"
                      type="password"
                      placeholder="Minimum 8 characters"
                      className={errors.password ? "border-destructive" : ""}
                    />
                  )}
                />
                {errors.password && (
                  <p className="text-sm text-destructive">{errors.password.message}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="passwordConfirm">Confirm Password *</Label>
                <Controller
                  name="passwordConfirm"
                  control={control}
                  render={({ field }) => (
                    <Input
                      {...field}
                      id="passwordConfirm"
                      type="password"
                      placeholder="Re-enter password"
                      className={errors.passwordConfirm ? "border-destructive" : ""}
                    />
                  )}
                />
                {errors.passwordConfirm && (
                  <p className="text-sm text-destructive">{errors.passwordConfirm.message}</p>
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
        <button type="submit" className="hidden" disabled={isLoading} aria-label="Submit form" />
      </form>
    </div>
  )
}