"use client"

import * as React from "react"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { useRouter } from "next/navigation"
import { useQueryClient } from "@tanstack/react-query"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Separator } from "@/components/ui/separator"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"
import { backendRecordKeyPrefix } from "@/hooks/use-backend-record"
import { 
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

// Form validation schema
const facilityFormSchema = z.object({
  name: z.string().min(1, "Facility name is required"),
  nhpi_code: z.string().min(1, "NHPI code is required"),
  hsdt_code: z.string().min(1, "HSDT code is required"),
  
  // Classification
  facility_level: z.string().min(1, "Facility level is required"),
  authority: z.string().min(1, "Authority is required"),
  ownership_type: z.string().min(1, "Ownership type is required"),
  
  // Geographic hierarchy
  region: z.string().min(1, "Region is required"),
  health_sub_region: z.string().min(1, "Health sub region is required"),
  district: z.string().min(1, "District is required"),
  county: z.string().min(1, "County is required"),
  health_sub_district: z.string().min(1, "Health sub district is required"),
  subcounty: z.string().min(1, "Subcounty is required"),
  parish: z.string().min(1, "Parish is required"),
})

type FacilityFormValues = z.infer<typeof facilityFormSchema>

interface FacilityFormProps {
  initialData?: Partial<FacilityFormValues>
  mode: "create" | "edit"
  facilityId?: string
}

export function FacilityForm({ initialData, mode, facilityId }: FacilityFormProps) {
  const router = useRouter()
  const queryClient = useQueryClient()
  const [isLoading, setIsLoading] = React.useState(false)
  
  // State for dropdown options
  const [facilityLevels, setFacilityLevels] = React.useState<FacilityLevelsResponse[]>([])
  const [authorities, setAuthorities] = React.useState<AuthoritiesResponse[]>([])
  const [ownershipTypes, setOwnershipTypes] = React.useState<OwnershipTypesResponse[]>([])
  const [regions, setRegions] = React.useState<RegionsResponse[]>([])
  const [healthSubRegions, setHealthSubRegions] = React.useState<HealthSubRegionsResponse[]>([])
  const [districts, setDistricts] = React.useState<DistrictsResponse[]>([])
  const [counties, setCounties] = React.useState<CountiesResponse[]>([])
  const [healthSubDistricts, setHealthSubDistricts] = React.useState<HealthSubDistrictsResponse[]>([])
  const [subcounties, setSubcounties] = React.useState<SubcountiesResponse[]>([])
  const [parishes, setParishes] = React.useState<ParishesResponse[]>([])

  const form = useForm<FacilityFormValues>({
    resolver: zodResolver(facilityFormSchema),
    defaultValues: {
      name: "",
      nhpi_code: "",
      hsdt_code: "",
      facility_level: "",
      authority: "",
      ownership_type: "",
      region: "",
      health_sub_region: "",
      district: "",
      county: "",
      health_sub_district: "",
      subcounty: "",
      parish: "",
      ...initialData,
    },
  })

  // Watch form values for cascading dropdowns
  const selectedRegion = form.watch("region")
  const selectedDistrict = form.watch("district")
  const selectedCounty = form.watch("county")
  const selectedSubcounty = form.watch("subcounty")

  // Load dropdown options on component mount
  React.useEffect(() => {
    const loadOptions = async () => {
      const pb = getBackendClient()
      try {
        const [
          facilityLevelsData,
          authoritiesData,
          ownershipTypesData,
          regionsData,
        ] = await Promise.all([
          pb.collection('facility_levels').getFullList({ sort: 'name' }),
          pb.collection('authorities').getFullList({ sort: 'name' }),
          pb.collection('ownership_types').getFullList({ sort: 'name' }),
          pb.collection('regions').getFullList({ sort: 'name' }),
        ])

        setFacilityLevels(facilityLevelsData as FacilityLevelsResponse[])
        setAuthorities(authoritiesData as AuthoritiesResponse[])
        setOwnershipTypes(ownershipTypesData as OwnershipTypesResponse[])
        setRegions(regionsData as RegionsResponse[])
      } catch (error) {
        console.error("Failed to load form options:", error)
        showToast.error("Error", "Failed to load form options")
      }
    }

    loadOptions()
  }, [])

  // Load cascading options based on selections
  React.useEffect(() => {
    if (!selectedRegion) {
      setHealthSubRegions([])
      return
    }

    if (selectedRegion) {
      const loadHealthSubRegions = async () => {
        const pb = getBackendClient()
        try {
          const data = await pb.collection('health_sub_regions').getFullList({
            filter: `region = "${selectedRegion}"`,
            sort: 'name',
          })
          setHealthSubRegions(data as HealthSubRegionsResponse[])
        } catch (error) {
          console.error("Failed to load health sub regions:", error)
        }
      }
      loadHealthSubRegions()
    }
  }, [selectedRegion])

  React.useEffect(() => {
    if (!selectedRegion) {
      setDistricts([])
      return
    }

    if (selectedRegion) {
      const loadDistricts = async () => {
        const pb = getBackendClient()
        try {
          const data = await pb.collection('districts').getFullList({
            filter: `region = "${selectedRegion}"`,
            sort: 'name',
          })
          setDistricts(data as DistrictsResponse[])
        } catch (error) {
          console.error("Failed to load districts:", error)
        }
      }
      loadDistricts()
    }
  }, [selectedRegion])

  React.useEffect(() => {
    if (!selectedDistrict) {
      setCounties([])
      setHealthSubDistricts([])
      return
    }

    if (selectedDistrict) {
      const loadCounties = async () => {
        const pb = getBackendClient()
        try {
          const data = await pb.collection('counties').getFullList({
            filter: `district = "${selectedDistrict}"`,
            sort: 'name',
          })
          setCounties(data as CountiesResponse[])
        } catch (error) {
          console.error("Failed to load counties:", error)
        }
      }

      const loadHealthSubDistricts = async () => {
        const pb = getBackendClient()
        try {
          const data = await pb.collection('health_sub_districts').getFullList({
            filter: `district = "${selectedDistrict}"`,
            sort: 'name',
          })
          setHealthSubDistricts(data as HealthSubDistrictsResponse[])
        } catch (error) {
          console.error("Failed to load health sub districts:", error)
        }
      }

      loadCounties()
      loadHealthSubDistricts()
    }
  }, [selectedDistrict])

  React.useEffect(() => {
    if (!selectedCounty) {
      setSubcounties([])
      return
    }

    if (selectedCounty) {
      const loadSubcounties = async () => {
        const pb = getBackendClient()
        try {
          const data = await pb.collection('subcounties').getFullList({
            filter: `county = "${selectedCounty}"`,
            sort: 'name',
          })
          setSubcounties(data as SubcountiesResponse[])
        } catch (error) {
          console.error("Failed to load subcounties:", error)
        }
      }
      loadSubcounties()
    }
  }, [selectedCounty])

  React.useEffect(() => {
    if (!selectedSubcounty) {
      setParishes([])
      return
    }

    if (selectedSubcounty) {
      const loadParishes = async () => {
        const pb = getBackendClient()
        try {
          const data = await pb.collection('parishes').getFullList({
            filter: `subcounty = "${selectedSubcounty}"`,
            sort: 'name',
          })
          setParishes(data as ParishesResponse[])
        } catch (error) {
          console.error("Failed to load parishes:", error)
        }
      }
      loadParishes()
    }
  }, [selectedSubcounty])

  const resetLocationFields = React.useCallback((fields: Array<keyof FacilityFormValues>) => {
    fields.forEach((fieldName) => {
      form.setValue(fieldName, "", { shouldDirty: true, shouldValidate: false })
    })
  }, [form])

  const handleRegionChange = React.useCallback((value: string) => {
    form.setValue("region", value, { shouldDirty: true, shouldValidate: true })
    resetLocationFields(["health_sub_region", "district", "county", "health_sub_district", "subcounty", "parish"])
    setHealthSubRegions([])
    setDistricts([])
    setCounties([])
    setHealthSubDistricts([])
    setSubcounties([])
    setParishes([])
  }, [form, resetLocationFields])

  const handleDistrictChange = React.useCallback((value: string) => {
    form.setValue("district", value, { shouldDirty: true, shouldValidate: true })
    resetLocationFields(["county", "health_sub_district", "subcounty", "parish"])
    setCounties([])
    setHealthSubDistricts([])
    setSubcounties([])
    setParishes([])
  }, [form, resetLocationFields])

  const handleCountyChange = React.useCallback((value: string) => {
    form.setValue("county", value, { shouldDirty: true, shouldValidate: true })
    resetLocationFields(["subcounty", "parish"])
    setSubcounties([])
    setParishes([])
  }, [form, resetLocationFields])

  const handleSubcountyChange = React.useCallback((value: string) => {
    form.setValue("subcounty", value, { shouldDirty: true, shouldValidate: true })
    resetLocationFields(["parish"])
    setParishes([])
  }, [form, resetLocationFields])

  const onSubmit = async (data: FacilityFormValues) => {
    setIsLoading(true)
    const pb = getBackendClient()

    try {
      if (mode === "create") {
        await pb.collection('health_facilities').create(data)
        showToast.success("Success", "Health facility created successfully")
      } else if (mode === "edit" && facilityId) {
        await pb.collection('health_facilities').update(facilityId, data)
        await queryClient.invalidateQueries({ queryKey: backendRecordKeyPrefix('health_facilities', facilityId) })
        showToast.success("Success", "Health facility updated successfully")
      }

      router.push('/health-facilities')
    } catch (error) {
      console.error("Failed to save facility:", error)
      showToast.error(
        "Error", 
        `Failed to ${mode === "create" ? "create" : "update"} facility`
      )
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        {/* Basic Information */}
        <Card>
          <CardHeader>
            <CardTitle>Basic Information</CardTitle>
            <CardDescription>
              Enter the basic details of the health facility
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Facility Name</FormLabel>
                  <FormControl>
                    <Input placeholder="e.g., Abim General Hospital" {...field} />
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
                      <Input placeholder="e.g., HFA6Q7GB2" {...field} />
                    </FormControl>
                    <FormDescription>
                      National Health Planning Identifier code
                    </FormDescription>
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
                      <Input placeholder="e.g., SCL79ULU0/PA95VLAL8/8001" {...field} />
                    </FormControl>
                    <FormDescription>
                      Health Service Delivery Tree code
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
          </CardContent>
        </Card>

        {/* Classification */}
        <Card>
          <CardHeader>
            <CardTitle>Classification</CardTitle>
            <CardDescription>
              Classify the facility by level, authority, and ownership
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <FormField
                control={form.control}
                name="facility_level"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Facility Level</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger className="w-full">
                          <SelectValue placeholder="Select level" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {facilityLevels.map((level) => (
                          <SelectItem key={level.id} value={level.id}>
                            {level.name} ({level.code})
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
                name="authority"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Authority</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger className="w-full">
                          <SelectValue placeholder="Select authority" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {authorities.map((authority) => (
                          <SelectItem key={authority.id} value={authority.id}>
                            {authority.name}
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
                name="ownership_type"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Ownership Type</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger className="w-full">
                          <SelectValue placeholder="Select ownership" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {ownershipTypes.map((ownership) => (
                          <SelectItem key={ownership.id} value={ownership.id}>
                            {ownership.name} ({ownership.code})
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
          </CardContent>
        </Card>

        {/* Geographic Location */}
        <Card>
          <CardHeader>
            <CardTitle>Geographic Location</CardTitle>
            <CardDescription>
              Select the administrative hierarchy location of the facility
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Region and Health Sub Region */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="region"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Region</FormLabel>
                    <Select onValueChange={handleRegionChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger className="w-full">
                          <SelectValue placeholder="Select region" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {regions.map((region) => (
                          <SelectItem key={region.id} value={region.id}>
                            {region.name}
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
                name="health_sub_region"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Health Sub Region</FormLabel>
                    <Select 
                      onValueChange={field.onChange} 
                      value={field.value}
                      disabled={!selectedRegion}
                    >
                      <FormControl>
                        <SelectTrigger className="w-full">
                          <SelectValue placeholder="Select health sub region" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {healthSubRegions.map((hsr) => (
                          <SelectItem key={hsr.id} value={hsr.id}>
                            {hsr.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            {/* District and Health Sub District */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="district"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>District</FormLabel>
                    <Select 
                      onValueChange={handleDistrictChange} 
                      value={field.value}
                      disabled={!selectedRegion}
                    >
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
                name="health_sub_district"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Health Sub District</FormLabel>
                    <Select 
                      onValueChange={field.onChange} 
                      value={field.value}
                      disabled={!selectedDistrict}
                    >
                      <FormControl>
                        <SelectTrigger className="w-full">
                          <SelectValue placeholder="Select health sub district" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {healthSubDistricts.map((hsd) => (
                          <SelectItem key={hsd.id} value={hsd.id}>
                            {hsd.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            {/* County, Subcounty, Parish */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <FormField
                control={form.control}
                name="county"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>County</FormLabel>
                    <Select 
                      onValueChange={handleCountyChange} 
                      value={field.value}
                      disabled={!selectedDistrict}
                    >
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
                name="subcounty"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Subcounty</FormLabel>
                    <Select 
                      onValueChange={handleSubcountyChange} 
                      value={field.value}
                      disabled={!selectedCounty}
                    >
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
                name="parish"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Parish</FormLabel>
                    <Select 
                      onValueChange={field.onChange} 
                      value={field.value}
                      disabled={!selectedSubcounty}
                    >
                      <FormControl>
                        <SelectTrigger className="w-full">
                          <SelectValue placeholder="Select parish" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {parishes.map((parish) => (
                          <SelectItem key={parish.id} value={parish.id}>
                            {parish.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
          </CardContent>
        </Card>

        <Separator />

        {/* Form Actions */}
        <div className="flex items-center justify-end space-x-2">
          <Button
            type="button"
            variant="outline"
            onClick={() => router.back()}
            disabled={isLoading}
          >
            Cancel
          </Button>
          <Button type="submit" disabled={isLoading}>
            {isLoading ? (mode === "create" ? "Creating..." : "Updating...") : (mode === "create" ? "Create Facility" : "Update Facility")}
          </Button>
        </div>
      </form>
    </Form>
  )
}
