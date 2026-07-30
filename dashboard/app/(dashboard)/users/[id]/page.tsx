"use client"

import * as React from "react"
import { useRouter, useParams } from "next/navigation"
import { Edit, Mail, Phone, MapPin, Building2, Shield, Globe, Clock, FileText } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Skeleton } from "@/components/ui/skeleton"
import { showToast } from "@/lib/toast"
import { useBackendRecord } from "@/hooks/use-backend-record"
import { UsersResponse } from "@/types/backend-types"
import { usePermissionContext } from "@/lib/permission-context"

export default function UserProfilePage() {
  const router = useRouter()
  const params = useParams()
  const userId = params.id as string

  const { record: user, loading: isLoading, error } = useBackendRecord<UsersResponse>(
    "users",
    userId
  )

  React.useEffect(() => {
    if (!error) return
    const err = error as { status?: number; message?: string }
    let title = "Load Failed"
    let message = "Could not load user data"
    if (err?.status === 404) {
      title = "User Not Found"
      message = "The requested user does not exist"
    } else if (err?.status === 403) {
      title = "Access Denied"
      message = "You do not have permission to view this user"
    } else if (err?.status === 401) {
      title = "Authentication Required"
      message = "Please log in to continue"
    } else if (err?.message?.includes("Failed to fetch")) {
      title = "Connection Error"
      message = "Could not connect to the server. Please check your connection."
    }
    showToast.error(title, message)
    router.push("/users")
  }, [error, router])

  const handleEdit = () => {
    router.push(`/users/${userId}/edit`)
  }

  const handleBack = () => {
    router.push('/users')
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
      case 'inactive': return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
      case 'suspended': return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
      case 'pending_activation': return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
    }
  }

  const formatRole = (role: string) => {
    return role.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
  }

  const formatDate = (dateString?: string) => {
    if (!dateString) return 'Not set'
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  if (isLoading) {
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
        
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <Card>
            <CardContent className="pt-6">
              <div className="flex flex-col items-center space-y-4">
                <Skeleton className="h-24 w-24 rounded-full" />
                <Skeleton className="h-6 w-32" />
                <Skeleton className="h-4 w-24" />
              </div>
            </CardContent>
          </Card>
          
          <div className="lg:col-span-2 space-y-6">
            <Card>
              <CardHeader>
                <Skeleton className="h-6 w-48" />
              </CardHeader>
              <CardContent className="space-y-4">
                <Skeleton className="h-4 w-full" />
                <Skeleton className="h-4 w-full" />
                <Skeleton className="h-4 w-3/4" />
              </CardContent>
            </Card>
          </div>
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
        title={`User Profile: ${user.name}`}
        description="View user information and activity"
        showBackButton={true}
        onBack={handleBack}
        actions={[
          {
            label: "Edit User",
            onClick: handleEdit,
            icon: <Edit className="h-4 w-4" />
          }
        ]}
      />

      <div className="space-y-6">
        {/* Contact Information with User Profile */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Mail className="h-5 w-5" />
              <span>Contact Information</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* User Profile Section */}
            <div className="flex flex-col sm:flex-row items-center sm:items-start space-y-4 sm:space-y-0 sm:space-x-6 pb-6 border-b border-border">
              <Avatar className="h-24 w-24 flex-shrink-0">
                <AvatarImage 
                  src={user.avatar || `/avatars/${user.id}.png`} 
                  alt={user.name}
                />
                <AvatarFallback className="text-lg">
                  {user.name
                    .split(' ')
                    .map(n => n[0])
                    .join('')
                    .toUpperCase()
                    .slice(0, 2)
                  }
                </AvatarFallback>
              </Avatar>
              
              <div className="text-center sm:text-left space-y-2">
                <h3 className="text-2xl font-semibold">{user.name}</h3>
                <div className="flex flex-col sm:flex-row items-center sm:items-start gap-2">
                  <Badge className={getStatusColor(user.status)}>
                    {user.status.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </Badge>
                  <span className="text-sm text-muted-foreground">
                    {formatRole(user.role)}
                  </span>
                </div>
              </div>
            </div>
            
            {/* Contact Details */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <div>
                <label className="text-sm font-medium text-muted-foreground">Email</label>
                <p className="flex items-center space-x-2 mt-1">
                  <Mail className="h-4 w-4" />
                  <span>{user.email}</span>
                  {user.verified && <Badge variant="secondary">Verified</Badge>}
                </p>
              </div>
              <div>
                <label className="text-sm font-medium text-muted-foreground">Phone</label>
                <p className="flex items-center space-x-2 mt-1">
                  <Phone className="h-4 w-4" />
                  <span>{user.phone}</span>
                </p>
              </div>
              {user.alternativePhone && (
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Alternative Phone</label>
                  <p className="flex items-center space-x-2 mt-1">
                    <Phone className="h-4 w-4" />
                    <span>{user.alternativePhone}</span>
                  </p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

          {/* Professional Information */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Building2 className="h-5 w-5" />
                <span>Professional Information</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Role</label>
                  <p className="flex items-center space-x-2 mt-1">
                    <Shield className="h-4 w-4" />
                    <span>{formatRole(user.role)}</span>
                  </p>
                </div>
                {user.organization && (
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">Organization</label>
                    <p>{user.organization}</p>
                  </div>
                )}
                {user.department && (
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">Department</label>
                    <p>{user.department}</p>
                  </div>
                )}
                {user.jobTitle && (
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">Job Title</label>
                    <p>{user.jobTitle}</p>
                  </div>
                )}
                {user.licenseNumber && (
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">License Number</label>
                    <p>{user.licenseNumber}</p>
                  </div>
                )}
              </div>
              
              {user.specialization && (
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Specialization</label>
                  <div className="flex flex-wrap gap-2 mt-2">
                    <Badge variant="outline">
                      {user.specialization}
                    </Badge>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Location Information */}
          {(user.country || user.state || user.city || user.address) && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <MapPin className="h-5 w-5" />
                  <span>Location Information</span>
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {user.country && (
                    <div>
                      <label className="text-sm font-medium text-muted-foreground">Country</label>
                      <p>{user.country}</p>
                    </div>
                  )}
                  {user.state && (
                    <div>
                      <label className="text-sm font-medium text-muted-foreground">State/Region</label>
                      <p>{user.state}</p>
                    </div>
                  )}
                  {user.city && (
                    <div>
                      <label className="text-sm font-medium text-muted-foreground">City</label>
                      <p>{user.city}</p>
                    </div>
                  )}
                  {user.address && (
                    <div>
                      <label className="text-sm font-medium text-muted-foreground">Address</label>
                      <p>{user.address}</p>
                    </div>
                  )}
                  {user.postalCode && (
                    <div>
                      <label className="text-sm font-medium text-muted-foreground">Postal Code</label>
                      <p>{user.postalCode}</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          {/* System Information */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Globe className="h-5 w-5" />
                <span>System Information</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {user.preferredLanguage && (
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">Preferred Language</label>
                    <p>{user.preferredLanguage}</p>
                  </div>
                )}
                {user.timezone && (
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">Timezone</label>
                    <p className="flex items-center space-x-2">
                      <Clock className="h-4 w-4" />
                      <span>{user.timezone}</span>
                    </p>
                  </div>
                )}
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Member Since</label>
                  <p>{formatDate(user.created)}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Last Updated</label>
                  <p>{formatDate(user.updated)}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Additional Notes */}
          {user.notes && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <FileText className="h-5 w-5" />
                  <span>Additional Notes</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground">{user.notes}</p>
              </CardContent>
            </Card>
          )}
      </div>
    </div>
  )
}