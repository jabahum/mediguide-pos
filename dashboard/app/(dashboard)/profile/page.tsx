"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Edit, Mail, Phone, MapPin, Building2, Shield, Globe, Clock, FileText } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Skeleton } from "@/components/ui/skeleton"
import { showToast } from "@/lib/toast"
import { getCurrentUser } from "@/lib/backend-client"
import { UsersResponse } from "@/types/backend-types"
import { usersService } from "@/services/user-management.service"

export default function MyProfilePage() {
  const router = useRouter()
  const [isLoading, setIsLoading] = React.useState(true)
  const [user, setUser] = React.useState<UsersResponse | null>(null)

  React.useEffect(() => {
    const abortController = new AbortController()

    const loadUser = async () => {
      try {
        const authUser = getCurrentUser()
        if (!authUser?.id) {
          showToast.error("Authentication Required", "Please log in to view your profile")
          router.push("/login")
          return
        }

        const fresh = await usersService.get<UsersResponse>(String(authUser.id))
        if (!abortController.signal.aborted) {
          setUser(fresh as UsersResponse)
        }
      } catch (error: unknown) {
        if (abortController.signal.aborted) return
        if (
          error &&
          typeof error === "object" &&
          "name" in error &&
          (error as { name: string }).name === "AbortError"
        ) {
          return
        }
        console.error("Failed to load profile:", error)
        showToast.error("Load Failed", "Could not load your profile")
      } finally {
        if (!abortController.signal.aborted) setIsLoading(false)
      }
    }

    loadUser()
    return () => abortController.abort()
  }, [router])

  const handleEdit = () => {
    if (user?.id) router.push(`/users/${user.id}/edit`)
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case "active":
        return "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      case "inactive":
        return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      case "suspended":
        return "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      case "pending_activation":
        return "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
      default:
        return "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    }
  }

  const formatRole = (role: string) =>
    role.replace(/_/g, " ").replace(/\b\w/g, (l) => l.toUpperCase())

  const formatDate = (dateString?: string) => {
    if (!dateString) return "Not set"
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
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
          <Skeleton className="h-9 w-28" />
        </div>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center space-x-4">
              <Skeleton className="h-24 w-24 rounded-full" />
              <div className="space-y-2">
                <Skeleton className="h-6 w-48" />
                <Skeleton className="h-4 w-32" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="space-y-6">
        <PageHeader title="My Profile" description="View your account information" />
        <div className="text-center py-12">
          <p className="text-muted-foreground">Profile not available</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="My Profile"
        description="View and manage your account information"
        actions={[
          {
            label: "Edit Profile",
            onClick: handleEdit,
            icon: <Edit className="h-4 w-4" />,
          },
        ]}
      />

      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Mail className="h-5 w-5" />
              <span>Contact Information</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="flex flex-col sm:flex-row items-center sm:items-start space-y-4 sm:space-y-0 sm:space-x-6 pb-6 border-b border-border">
              <Avatar className="h-24 w-24 flex-shrink-0">
                <AvatarImage
                  src={user.avatar || `/avatars/${user.id}.png`}
                  alt={user.name}
                />
                <AvatarFallback className="text-lg">
                  {user.name
                    .split(" ")
                    .map((n) => n[0])
                    .join("")
                    .toUpperCase()
                    .slice(0, 2)}
                </AvatarFallback>
              </Avatar>

              <div className="text-center sm:text-left space-y-2">
                <h3 className="text-2xl font-semibold">{user.name}</h3>
                <div className="flex flex-col sm:flex-row items-center sm:items-start gap-2">
                  <Badge className={getStatusColor(user.status)}>
                    {user.status
                      .replace(/_/g, " ")
                      .replace(/\b\w/g, (l) => l.toUpperCase())}
                  </Badge>
                  <span className="text-sm text-muted-foreground">
                    {formatRole(user.role)}
                  </span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <div>
                <label className="text-sm font-medium text-muted-foreground">Email</label>
                <p className="flex items-center space-x-2 mt-1">
                  <Mail className="h-4 w-4" />
                  <span>{user.email}</span>
                  {user.verified && <Badge variant="secondary">Verified</Badge>}
                </p>
              </div>
              {user.phone && (
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Phone</label>
                  <p className="flex items-center space-x-2 mt-1">
                    <Phone className="h-4 w-4" />
                    <span>{user.phone}</span>
                  </p>
                </div>
              )}
              {user.alternativePhone && (
                <div>
                  <label className="text-sm font-medium text-muted-foreground">
                    Alternative Phone
                  </label>
                  <p className="flex items-center space-x-2 mt-1">
                    <Phone className="h-4 w-4" />
                    <span>{user.alternativePhone}</span>
                  </p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

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
                  <label className="text-sm font-medium text-muted-foreground">
                    Organization
                  </label>
                  <p>{user.organization}</p>
                </div>
              )}
              {user.department && (
                <div>
                  <label className="text-sm font-medium text-muted-foreground">
                    Department
                  </label>
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
                  <label className="text-sm font-medium text-muted-foreground">
                    License Number
                  </label>
                  <p>{user.licenseNumber}</p>
                </div>
              )}
            </div>

            {user.specialization && (
              <div>
                <label className="text-sm font-medium text-muted-foreground">
                  Specialization
                </label>
                <div className="flex flex-wrap gap-2 mt-2">
                  <Badge variant="outline">{user.specialization}</Badge>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {(user.country || user.state || user.city || user.address) && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <MapPin className="h-5 w-5" />
                <span>Location Information</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {user.country && (
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">Country</label>
                    <p>{user.country}</p>
                  </div>
                )}
                {user.state && (
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">
                      State/Region
                    </label>
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
                    <label className="text-sm font-medium text-muted-foreground">
                      Postal Code
                    </label>
                    <p>{user.postalCode}</p>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        )}

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Globe className="h-5 w-5" />
              <span>System Information</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {user.preferredLanguage && (
                <div>
                  <label className="text-sm font-medium text-muted-foreground">
                    Preferred Language
                  </label>
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
