"use client"

import * as React from "react"
import { useParams, useRouter } from "next/navigation"
import { format } from "date-fns"
import { Edit, Map, FileText, Copy, Building2, Shield, MapPin, Hash, Calendar } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { PageHeader } from "@/components/ui/page-header"
import { useDomainRecord } from "@/hooks/use-domain-record"
import { healthFacilitiesService } from "@/services/health-facilities.service"
import { showToast } from "@/lib/toast"
import { usePermissionContext } from "@/lib/permission-context"
import { 
  HealthFacilitiesResponse, 
  FacilityLevelsResponse, 
  AuthoritiesResponse, 
  OwnershipTypesResponse,
  RegionsResponse,
  DistrictsResponse,
  CountiesResponse,
  SubcountiesResponse,
  ParishesResponse,
  HealthSubDistrictsResponse,
  HealthSubRegionsResponse
} from "@/types/backend-types"

type FacilityWithExpand = HealthFacilitiesResponse<{
  facility_level: FacilityLevelsResponse
  authority: AuthoritiesResponse
  ownership_type: OwnershipTypesResponse
  region: RegionsResponse
  health_sub_region: HealthSubRegionsResponse
  district: DistrictsResponse
  county: CountiesResponse
  health_sub_district: HealthSubDistrictsResponse
  subcounty: SubcountiesResponse
  parish: ParishesResponse
}>

export default function FacilityDetailsPage() {
  const params = useParams()
  const router = useRouter()
  const facilityId = params.id as string
  const { hasPermission, loading: permLoading } = usePermissionContext()

  const { record: facility, loading: isLoading, error } = useDomainRecord<FacilityWithExpand>(
    "health_facilities",
    facilityId,
    healthFacilitiesService.getFacility as (id: string) => Promise<FacilityWithExpand>,
  )

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/health-facilities")
    }
  }, [permLoading, hasPermission, router])

  React.useEffect(() => {
    if (!error) return
    console.error("Failed to load facility:", error)
    showToast.error("Error", "Failed to load facility data")
  }, [error])

  const handleCopyCodes = async () => {
    if (!facility) return
    
    const codes = `NHPI: ${facility.nhpi_code}\nHSDT: ${facility.hsdt_code}`
    try {
      await navigator.clipboard.writeText(codes)
      showToast.success("Copied", "Facility codes copied to clipboard")
    } catch {
      showToast.error("Error", "Failed to copy codes")
    }
  }

  const handleViewOnMap = () => {
    showToast.info("Map View", `Opening map view for ${facility?.name}`)
  }

  const handleGenerateReport = () => {
    showToast.info("Report", `Generating report for ${facility?.name}`)
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Health Facility Details"
          description="Loading facility information..."
          showBackButton={true}
          onBack={() => router.back()}
        />
        <div className="flex items-center justify-center py-12">
          <div className="text-muted-foreground">Loading...</div>
        </div>
      </div>
    )
  }

  if (!facility) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Health Facility Details"
          description="Facility not found"
          showBackButton={true}
          onBack={() => router.back()}
        />
        <div className="flex items-center justify-center py-12">
          <div className="text-muted-foreground">Facility not found</div>
        </div>
      </div>
    )
  }

  const { expand } = facility

  return (
    <div className="space-y-6">
      <PageHeader
        title={facility.name}
        description="Health facility details and administrative information"
        showBackButton={true}
        onBack={() => router.back()}
        actions={[
          ...(hasPermission("content", "update:any") ? [{
            label: "Edit Facility",
            onClick: () => router.push(`/health-facilities/${facilityId}/edit`),
            icon: <Edit className="h-4 w-4" />
          }] : []),
          {
            label: "View on Map",
            onClick: handleViewOnMap,
            icon: <Map className="h-4 w-4" />,
            variant: "outline" as const
          },
          {
            label: "Generate Report",
            onClick: handleGenerateReport,
            icon: <FileText className="h-4 w-4" />,
            variant: "outline" as const
          },
          {
            label: "Copy Codes",
            onClick: handleCopyCodes,
            icon: <Copy className="h-4 w-4" />,
            variant: "outline" as const
          }
        ]}
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Information */}
        <div className="lg:col-span-2 space-y-6">
          {/* Basic Information */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Building2 className="h-5 w-5" />
                <span>Basic Information</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Facility Name</label>
                  <p className="text-sm font-medium">{facility.name}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Facility Level</label>
                  <div className="mt-1">
                    {expand?.facility_level ? (
                      <Badge variant="default">
                        {expand.facility_level.name}
                      </Badge>
                    ) : (
                      <span className="text-sm text-muted-foreground">—</span>
                    )}
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">NHPI Code</label>
                  <div className="flex items-center space-x-2 mt-1">
                    <Hash className="h-3 w-3 text-muted-foreground" />
                    <code className="text-sm font-mono bg-muted px-2 py-1 rounded">
                      {facility.nhpi_code}
                    </code>
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">HSDT Code</label>
                  <div className="flex items-center space-x-2 mt-1">
                    <Hash className="h-3 w-3 text-muted-foreground" />
                    <code className="text-sm font-mono bg-muted px-2 py-1 rounded">
                      {facility.hsdt_code}
                    </code>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Classification */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Shield className="h-5 w-5" />
                <span>Classification</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Authority</label>
                  <div className="mt-1">
                    {expand?.authority ? (
                      <Badge variant="default">
                        {expand.authority.name}
                      </Badge>
                    ) : (
                      <span className="text-sm text-muted-foreground">—</span>
                    )}
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Ownership Type</label>
                  <div className="mt-1">
                    {expand?.ownership_type ? (
                      <Badge variant="secondary">
                        {expand.ownership_type.name}
                      </Badge>
                    ) : (
                      <span className="text-sm text-muted-foreground">—</span>
                    )}
                  </div>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Facility Code</label>
                  <div className="mt-1">
                    {expand?.facility_level ? (
                      <Badge variant="outline">
                        {expand.facility_level.code}
                      </Badge>
                    ) : (
                      <span className="text-sm text-muted-foreground">—</span>
                    )}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Location Hierarchy */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <MapPin className="h-5 w-5" />
                <span>Administrative Location</span>
              </CardTitle>
              <CardDescription>
                Complete administrative hierarchy location
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Region</label>
                  <p className="text-sm">{expand?.region?.name || "—"}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Health Sub Region</label>
                  <p className="text-sm">{expand?.health_sub_region?.name || "—"}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">District</label>
                  <p className="text-sm">{expand?.district?.name || "—"}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Health Sub District</label>
                  <p className="text-sm">{expand?.health_sub_district?.name || "—"}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">County</label>
                  <p className="text-sm">{expand?.county?.name || "—"}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Subcounty</label>
                  <p className="text-sm">{expand?.subcounty?.name || "—"}</p>
                </div>
                <div className="md:col-span-2">
                  <label className="text-sm font-medium text-muted-foreground">Parish</label>
                  <p className="text-sm">{expand?.parish?.name || "—"}</p>
                </div>
              </div>
              
              <Separator />
              
              {/* Hierarchy Path */}
              <div>
                <label className="text-sm font-medium text-muted-foreground">Full Administrative Path</label>
                <div className="mt-2 p-3 bg-muted rounded-lg">
                  <p className="text-sm text-muted-foreground leading-relaxed">
                    {[
                      expand?.region?.name,
                      expand?.district?.name,
                      expand?.county?.name,
                      expand?.subcounty?.name,
                      expand?.parish?.name,
                      facility.name
                    ].filter(Boolean).join(' → ')}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar Information */}
        <div className="space-y-6">
          {/* System Information */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Calendar className="h-5 w-5" />
                <span>System Information</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium text-muted-foreground">Created</label>
                <p className="text-sm">
                  {format(new Date(facility.created), 'PPpp')}
                </p>
              </div>
              {facility.updated && (
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Last Updated</label>
                  <p className="text-sm">
                    {format(new Date(facility.updated), 'PPpp')}
                  </p>
                </div>
              )}
              <div>
                <label className="text-sm font-medium text-muted-foreground">Facility ID</label>
                <code className="text-sm font-mono bg-muted px-2 py-1 rounded block mt-1">
                  {facility.id}
                </code>
              </div>
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <Card>
            <CardHeader>
              <CardTitle>Quick Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <Button 
                variant="outline" 
                className="w-full justify-start" 
                onClick={() => router.push(`/health-facilities/${facilityId}/edit`)}
              >
                <Edit className="h-4 w-4 mr-2" />
                Edit Facility
              </Button>
              <Button 
                variant="outline" 
                className="w-full justify-start" 
                onClick={handleViewOnMap}
              >
                <Map className="h-4 w-4 mr-2" />
                View on Map
              </Button>
              <Button 
                variant="outline" 
                className="w-full justify-start" 
                onClick={handleGenerateReport}
              >
                <FileText className="h-4 w-4 mr-2" />
                Generate Report
              </Button>
              <Button 
                variant="outline" 
                className="w-full justify-start" 
                onClick={handleCopyCodes}
              >
                <Copy className="h-4 w-4 mr-2" />
                Copy Codes
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
