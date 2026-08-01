"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { notFound } from "next/navigation"
import { 
  Edit, 
  Mail, 
  Phone, 
  MapPin, 
  Building2, 
  Star, 
  Award, 
  Shield, 
  Clock,
  Globe,
  Calendar,
  FileText,
} from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { PageHeader } from "@/components/ui/page-header"
import { useDomainRecord } from "@/hooks/use-domain-record"
import { formatLocation, getStatusBadgeVariant } from "../columns"
import type { Consultant } from "../columns"
import { usePermissionContext, WithPermission } from "@/lib/permission-context"
import { consultantService } from "@/services/consultant.service"

interface ConsultantDetailPageProps {
  params: Promise<{
    id: string
  }>
}

export default function ConsultantDetailPage({ params }: ConsultantDetailPageProps) {
  const { hasPermission, loading } = usePermissionContext()
  const router = useRouter()
  const { id } = React.use(params)

  const { record: consultant, loading: isLoading, error } = useDomainRecord<Consultant & { id: string }>(
    "consultants",
    id,
    consultantService.get,
  )

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/consultants")
    }
  }, [loading, hasPermission, router])

  React.useEffect(() => {
    if (error) {
      notFound()
    }
  }, [error])

  if (isLoading || !id) {
    return (
      <div className="space-y-6">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-1/4 mb-2"></div>
          <div className="h-4 bg-gray-200 rounded w-1/2"></div>
        </div>
        <div className="grid gap-6">
          <div className="animate-pulse h-48 bg-gray-200 rounded-lg"></div>
          <div className="animate-pulse h-32 bg-gray-200 rounded-lg"></div>
        </div>
      </div>
    )
  }

  if (!consultant) {
    notFound()
  }

  const location = formatLocation(consultant.city, consultant.region, consultant.country)

  return (
    <div className="space-y-6">
      <PageHeader
        title={consultant.name}
        description={`${consultant.specialty} • ${consultant.organization || 'Independent Consultant'}`}
        showBackButton={true}
        onBack={() => router.push('/consultants')}
        actions={hasPermission("content", "update:any") ? [
          {
            label: "Edit",
            onClick: () => router.push(`/consultants/${consultant.id}/edit`),
            icon: <Edit className="h-4 w-4" />
          },
        ] : []}
      />

      <div className="grid gap-6 md:grid-cols-3">
        {/* Main Profile Card */}
        <Card className="md:col-span-2">
          <CardHeader>
            <div className="flex items-start space-x-4">
              <Avatar className="h-16 w-16">
                <AvatarImage
                  src={consultant.profilePicture || consultant.avatar || `/avatars/${consultant.id}.png`}
                  alt={consultant.name}
                />
                <AvatarFallback className="text-lg">
                  {consultant.name
                    .split(' ')
                    .map(n => n[0])
                    .join('')
                    .toUpperCase()
                    .slice(0, 2)
                  }
                </AvatarFallback>
              </Avatar>
              <div className="flex-1 space-y-2">
                <div className="flex items-center space-x-2">
                  <CardTitle className="text-2xl">{consultant.name}</CardTitle>
                  {consultant.isVerified && (
                    <Shield className="h-5 w-5 text-green-500" />
                  )}
                </div>
                <div className="flex items-center space-x-4">
                  <Badge variant="outline" className="text-sm">
                    {consultant.specialty}
                  </Badge>
                  <Badge variant={getStatusBadgeVariant(consultant.status)}>
                    {consultant.status === 'pending_approval' ? 'Pending Approval' : 
                     consultant.status.charAt(0).toUpperCase() + consultant.status.slice(1)}
                  </Badge>
                </div>
                {consultant.rating && (
                  <div className="flex items-center space-x-2">
                    <Star className="h-4 w-4 text-yellow-500" />
                    <span className="text-sm font-medium">{consultant.rating.toFixed(1)}</span>
                    {consultant.totalConsultations && (
                      <span className="text-sm text-muted-foreground">
                        • {consultant.totalConsultations} consultations
                      </span>
                    )}
                  </div>
                )}
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Contact Information */}
            <div>
              <h3 className="font-semibold mb-3">Contact Information</h3>
              <div className="space-y-2">
                <div className="flex items-center space-x-3">
                  <Mail className="h-4 w-4 text-muted-foreground" />
                  <a href={`mailto:${consultant.email}`} className="text-sm hover:underline">
                    {consultant.email}
                  </a>
                </div>
                <div className="flex items-center space-x-3">
                  <Phone className="h-4 w-4 text-muted-foreground" />
                  <a href={`tel:${consultant.phone}`} className="text-sm hover:underline">
                    {consultant.phone}
                  </a>
                </div>
                {consultant.alternativePhone && (
                  <div className="flex items-center space-x-3">
                    <Phone className="h-4 w-4 text-muted-foreground" />
                    <a href={`tel:${consultant.alternativePhone}`} className="text-sm hover:underline">
                      {consultant.alternativePhone} <span className="text-muted-foreground">(Alt)</span>
                    </a>
                  </div>
                )}
              </div>
            </div>

            <Separator />

            {/* Professional Information */}
            <div>
              <h3 className="font-semibold mb-3">Professional Details</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {consultant.yearsOfExperience && (
                  <div className="flex items-center space-x-3">
                    <Clock className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm">{consultant.yearsOfExperience} years experience</span>
                  </div>
                )}
                {consultant.licenseNumber && (
                  <div className="flex items-center space-x-3">
                    <Award className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm font-mono">{consultant.licenseNumber}</span>
                  </div>
                )}
                {consultant.preferredLanguage && (
                  <div className="flex items-center space-x-3">
                    <Globe className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm">{consultant.preferredLanguage}</span>
                  </div>
                )}
                {consultant.timezone && (
                  <div className="flex items-center space-x-3">
                    <Clock className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm">{consultant.timezone}</span>
                  </div>
                )}
              </div>
              
              {consultant.qualifications && consultant.qualifications.length > 0 && (
                <div className="mt-4">
                  <h4 className="font-medium mb-2">Qualifications</h4>
                  <div className="flex flex-wrap gap-2">
                    {consultant.qualifications.map((qual, index) => (
                      <Badge key={index} variant="secondary" className="text-xs">
                        {qual}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}

              {consultant.certifications && (
                <div className="mt-4">
                  <h4 className="font-medium mb-2">Additional Certifications</h4>
                  <p className="text-sm text-muted-foreground">{consultant.certifications}</p>
                </div>
              )}
            </div>

            <Separator />

            {/* Location & Organization */}
            <div>
              <h3 className="font-semibold mb-3">Location & Organization</h3>
              <div className="space-y-2">
                {consultant.organization && (
                  <div className="flex items-center space-x-3">
                    <Building2 className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm">
                      {consultant.organization}
                      {consultant.department && ` • ${consultant.department}`}
                    </span>
                  </div>
                )}
                {location && (
                  <div className="flex items-center space-x-3">
                    <MapPin className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm">{location}</span>
                  </div>
                )}
                {consultant.address && (
                  <div className="mt-2">
                    <p className="text-sm text-muted-foreground pl-7">{consultant.address}</p>
                  </div>
                )}
              </div>
            </div>

            {consultant.consultationTypes && consultant.consultationTypes.length > 0 && (
              <>
                <Separator />
                <div>
                  <h3 className="font-semibold mb-3">Available Consultation Types</h3>
                  <div className="flex flex-wrap gap-2">
                    {consultant.consultationTypes.map((type, index) => (
                      <Badge key={index} variant="outline" className="text-xs">
                        {type}
                      </Badge>
                    ))}
                  </div>
                </div>
              </>
            )}

            {consultant.notes && (
              <>
                <Separator />
                <div>
                  <h3 className="font-semibold mb-3">Internal Notes</h3>
                  <div className="flex items-start space-x-3">
                    <FileText className="h-4 w-4 text-muted-foreground mt-0.5" />
                    <p className="text-sm text-muted-foreground">{consultant.notes}</p>
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Side Information */}
        <div className="space-y-6">
          {/* Quick Stats */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Quick Stats</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-primary">
                  {consultant.rating?.toFixed(1) || 'N/A'}
                </div>
                <div className="text-sm text-muted-foreground">Average Rating</div>
              </div>
              <Separator />
              <div className="text-center">
                <div className="text-2xl font-bold text-primary">
                  {consultant.totalConsultations || 0}
                </div>
                <div className="text-sm text-muted-foreground">Total Consultations</div>
              </div>
              <Separator />
              <div className="text-center">
                <div className="text-2xl font-bold text-primary">
                  {consultant.yearsOfExperience || 'N/A'}
                </div>
                <div className="text-sm text-muted-foreground">Years Experience</div>
              </div>
            </CardContent>
          </Card>

          {/* Account Information */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Account Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Status</span>
                <Badge variant={getStatusBadgeVariant(consultant.status)} className="text-xs">
                  {consultant.status === 'pending_approval' ? 'Pending Approval' : 
                   consultant.status.charAt(0).toUpperCase() + consultant.status.slice(1)}
                </Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Verified</span>
                <Badge variant={consultant.isVerified ? 'default' : 'secondary'} className="text-xs">
                  {consultant.isVerified ? 'Yes' : 'No'}
                </Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Created</span>
                <span className="text-sm">
                  {new Date(consultant.created).toLocaleDateString()}
                </span>
              </div>
              {consultant.updated && (
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Last Updated</span>
                  <span className="text-sm">
                    {new Date(consultant.updated).toLocaleDateString()}
                  </span>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Actions */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <WithPermission resource="content" action="update:any">
                <Button
                  onClick={() => router.push(`/consultants/${consultant.id}/edit`)}
                  className="w-full"
                >
                  <Edit className="h-4 w-4 mr-2" />
                  Edit Profile
                </Button>
              </WithPermission>
              <Button 
                variant="outline" 
                className="w-full"
                onClick={() => {
                  // This would integrate with consultation scheduling
                  alert('Consultation scheduling coming soon!')
                }}
                disabled={consultant.status !== 'active' || !consultant.isVerified}
              >
                <Calendar className="h-4 w-4 mr-2" />
                Schedule Consultation
              </Button>
              <Button 
                variant="outline" 
                className="w-full"
                asChild
              >
                <a href={`mailto:${consultant.email}`} target="_blank" rel="noopener noreferrer">
                  <Mail className="h-4 w-4 mr-2" />
                  Send Email
                </a>
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
