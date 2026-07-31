"use client"

import * as React from "react"
import { useParams, useRouter } from "next/navigation"

import { PageHeader } from "@/components/ui/page-header"
import { usePermissionContext } from "@/lib/permission-context"
import { FacilityForm } from "../../components/facility-form"
import { showToast } from "@/lib/toast"
import { HealthFacilitiesResponse } from "@/types/backend-types"
import { healthFacilitiesService } from "@/services/health-facilities.service"

export default function EditFacilityPage() {
  const params = useParams()
  const router = useRouter()
  const facilityId = params.id as string
  const { hasPermission, loading: permLoading } = usePermissionContext()

  const [facility, setFacility] = React.useState<HealthFacilitiesResponse | null>(null)
  const [isLoading, setIsLoading] = React.useState(true)

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "update:any")) {
      router.replace("/health-facilities")
    }
  }, [permLoading, hasPermission, router])

  React.useEffect(() => {
    const loadFacility = async () => {
      if (!facilityId) return

      try {
        const facilityData = await healthFacilitiesService.getFacility(facilityId)
        setFacility(facilityData as HealthFacilitiesResponse)
      } catch (error) {
        console.error("Failed to load facility:", error)
        showToast.error("Error", "Failed to load facility data")
      } finally {
        setIsLoading(false)
      }
    }

    loadFacility()
  }, [facilityId])

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Edit Health Facility"
          description="Loading facility data..."
          showBackButton={true}
          onBack={() => window.history.back()}
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
          title="Edit Health Facility"
          description="Facility not found"
          showBackButton={true}
          onBack={() => window.history.back()}
        />
        <div className="flex items-center justify-center py-12">
          <div className="text-muted-foreground">Facility not found</div>
        </div>
      </div>
    )
  }

  // Prepare initial data for the form
  const initialData = {
    name: facility.name,
    nhpi_code: facility.nhpi_code,
    hsdt_code: facility.hsdt_code,
    facility_level: Array.isArray(facility.facility_level) ? facility.facility_level[0] : facility.facility_level,
    authority: Array.isArray(facility.authority) ? facility.authority[0] : facility.authority,
    ownership_type: Array.isArray(facility.ownership_type) ? facility.ownership_type[0] : facility.ownership_type,
    region: Array.isArray(facility.region) ? facility.region[0] : facility.region,
    health_sub_region: Array.isArray(facility.health_sub_region) ? facility.health_sub_region[0] : facility.health_sub_region,
    district: Array.isArray(facility.district) ? facility.district[0] : facility.district,
    county: Array.isArray(facility.county) ? facility.county[0] : facility.county,
    health_sub_district: Array.isArray(facility.health_sub_district) ? facility.health_sub_district[0] : facility.health_sub_district,
    subcounty: Array.isArray(facility.subcounty) ? facility.subcounty[0] : facility.subcounty,
    parish: Array.isArray(facility.parish) ? facility.parish[0] : facility.parish,
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Edit Health Facility"
        description={`Update details for ${facility.name}`}
        showBackButton={true}
        onBack={() => window.history.back()}
      />

      <FacilityForm 
        mode="edit" 
        facilityId={facilityId}
        initialData={initialData}
      />
    </div>
  )
}
