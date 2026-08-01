"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { notFound } from "next/navigation"
import { PageHeader } from "@/components/ui/page-header"
import { Badge } from "@/components/ui/badge"
import { Label } from "@/components/ui/label"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { DrugWithRelations } from "../columns"
import { useDomainRecord } from "@/hooks/use-domain-record"
import { drugService } from "@/services/drug.service"
import { formatDistanceToNow } from "date-fns"
import { Edit, Copy, Trash2, Pill, AlertTriangle, Calendar, FileText, Activity } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { usePermissionContext } from "@/lib/permission-context"
import { RichContent } from "@/components/ui/rich-content"

interface DrugViewPageProps {
  params: Promise<{ id: string }>
}

export default function DrugViewPage({ params }: DrugViewPageProps) {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  // const [drug, setDrug] = React.useState<DrugWithRelations | null>(null)
  // const [loading, setLoading] = React.useState(true)

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/drugs")
    }
  }, [permLoading, hasPermission, router])

  // Unwrap params using React.use()
  const { id } = React.use(params)

  const { record: drug, loading, error } = useDomainRecord<DrugWithRelations>("drugs", id, drugService.get)

  React.useEffect(() => {
    if (error) {
      console.error("Failed to fetch drug:", error)
      notFound()
    }
  }, [error])

  const handleEdit = () => {
    router.push(`/drugs/${id}/edit`)
  }

  const handleDuplicate = () => {
    router.push(`/drugs/create?duplicate=${id}`)
  }

  const handleDelete = async () => {
    if (window.confirm("Are you sure you want to delete this drug? This action cannot be undone.")) {
      try {
        await drugService.delete(id)
        router.push("/drugs")
      } catch (error) {
        console.error("Failed to delete drug:", error)
      }
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Loading..."
          showBackButton={true}
          onBack={() => router.push("/drugs")}
        />
        <div className="flex items-center justify-center h-64">
          <div className="text-muted-foreground">Loading drug details...</div>
        </div>
      </div>
    )
  }

  if (!drug) {
    notFound()
  }

  const categories = drug.expand?.categories || []
  const tags = drug.expand?.tags || []

  return (
    <div className="space-y-6">
      <PageHeader
        title={drug.name}
        description={drug.brand_names ? `Brand names: ${drug.brand_names}` : undefined}
        showBackButton={true}
        onBack={() => router.push("/drugs")}
        actions={[
          ...(hasPermission("content", "update:any") ? [{
            label: "Edit",
            onClick: handleEdit,
            icon: <Edit className="h-4 w-4" />
          }] : []),
          {
            label: "Duplicate",
            onClick: handleDuplicate,
            icon: <Copy className="h-4 w-4" />,
            variant: "outline" as const
          },
          ...(hasPermission("content", "delete:any") ? [{
            label: "Delete",
            onClick: handleDelete,
            icon: <Trash2 className="h-4 w-4" />,
            variant: "outline" as const
          }] : [])
        ]}
      />

      {/* Status Badges */}
      <div className="flex items-center gap-3">
        <Badge variant={drug.status === 'active' ? 'default' : 'secondary'}>
          {drug.status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
        </Badge>
        <Badge variant={drug.review_status === 'approved' ? 'default' : 'outline'}>
          {drug.review_status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
        </Badge>
        {drug.who_eml_status && (
          <Badge variant="secondary">WHO Essential Medicine</Badge>
        )}
        {drug.antimicrobial_status && (
          <Badge variant="destructive">Antimicrobial</Badge>
        )}
      </div>

      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="overview" className="flex items-center gap-1">
            <Pill className="h-4 w-4" />
            Overview
          </TabsTrigger>
          <TabsTrigger value="clinical" className="flex items-center gap-1">
            <Activity className="h-4 w-4" />
            Clinical
          </TabsTrigger>
          <TabsTrigger value="dosing" className="flex items-center gap-1">
            <FileText className="h-4 w-4" />
            Dosing
          </TabsTrigger>
          <TabsTrigger value="safety" className="flex items-center gap-1">
            <AlertTriangle className="h-4 w-4" />
            Safety
          </TabsTrigger>
          <TabsTrigger value="regulatory" className="flex items-center gap-1">
            <Calendar className="h-4 w-4" />
            Regulatory
          </TabsTrigger>
          <TabsTrigger value="metadata">Metadata</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="mt-8">
          <div className="grid gap-8 md:grid-cols-2 xl:grid-cols-3">
            {/* Basic Information */}
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Basic Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                {drug.expand?.drug_class && (
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Drug Class</Label>
                    <p className="text-sm font-medium">{drug.expand.drug_class.name}</p>
                  </div>
                )}
                
                {drug.expand?.therapeutic_category && (
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Therapeutic Category</Label>
                    <p className="text-sm font-medium">{drug.expand.therapeutic_category.name}</p>
                  </div>
                )}

                {drug.route_of_administration && (
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Route of Administration</Label>
                    <Badge variant="outline" className="font-medium">{drug.route_of_administration}</Badge>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Categories & Tags */}
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Classification</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                {categories.length > 0 && (
                  <div className="space-y-3">
                    <Label className="text-sm font-medium text-muted-foreground">Categories</Label>
                    <div className="flex flex-wrap gap-2">
                      {categories.map((category) => (
                        <Badge key={category.id} variant="outline" className="font-medium">
                          {category.icon && <span className="mr-1">{category.icon}</span>}
                          {category.name}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}

                {tags.length > 0 && (
                  <div className="space-y-3">
                    <Label className="text-sm font-medium text-muted-foreground">Tags</Label>
                    <div className="flex flex-wrap gap-2">
                      {tags.map((tag) => (
                        <Badge key={tag.id} variant="secondary" className="font-medium">
                          {tag.name}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Status Information */}
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Status Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="space-y-3">
                  <div>
                    <Label className="text-sm font-medium text-muted-foreground">Current Status</Label>
                    <div className="mt-2">
                      <Badge variant={drug.status === 'active' ? 'default' : 'secondary'} className="font-medium">
                        {drug.status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                      </Badge>
                    </div>
                  </div>

                  <div>
                    <Label className="text-sm font-medium text-muted-foreground">Review Status</Label>
                    <div className="mt-2">
                      <Badge variant={drug.review_status === 'approved' ? 'default' : 'outline'} className="font-medium">
                        {drug.review_status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                      </Badge>
                    </div>
                  </div>
                </div>

                <div className="space-y-3 border-t pt-4">
                  {drug.who_eml_status && (
                    <Badge variant="secondary" className="font-medium">WHO Essential Medicine</Badge>
                  )}

                  {drug.antimicrobial_status && (
                    <Badge variant="destructive" className="font-medium">Antimicrobial Agent</Badge>
                  )}

                  {drug.controlled_substance && drug.controlled_substance !== "None" && (
                    <div className="space-y-2">
                      <Label className="text-sm font-medium text-muted-foreground">Controlled Substance</Label>
                      <Badge variant="destructive" className="font-medium">{drug.controlled_substance}</Badge>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Description */}
          {drug.description && (
            <Card className="mt-8">
              <CardHeader className="pb-4">
                <CardTitle>Description</CardTitle>
              </CardHeader>
              <CardContent>
                <RichContent className="prose prose-sm max-w-none dark:prose-invert" html={drug.description} />
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="clinical" className="mt-8 space-y-8">
          {drug.mechanism_of_action && (
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Mechanism of Action</CardTitle>
              </CardHeader>
              <CardContent>
                <RichContent className="prose prose-sm max-w-none dark:prose-invert" html={drug.mechanism_of_action} />
              </CardContent>
            </Card>
          )}

          {drug.indications && (
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Indications</CardTitle>
                <CardDescription>Conditions this drug is used to treat</CardDescription>
              </CardHeader>
              <CardContent>
                <RichContent className="prose prose-sm max-w-none dark:prose-invert" html={drug.indications} />
              </CardContent>
            </Card>
          )}

          {drug.contraindications && (
            <Card className="border-destructive/20">
              <CardHeader className="pb-4">
                <CardTitle className="text-destructive">Contraindications</CardTitle>
                <CardDescription>When this drug should NOT be used</CardDescription>
              </CardHeader>
              <CardContent>
                <RichContent className="prose prose-sm max-w-none dark:prose-invert" html={drug.contraindications} />
              </CardContent>
            </Card>
          )}

          {drug.side_effects && (
            <Card>
              <CardHeader className="pb-4">
                <CardTitle className="text-orange-700 dark:text-orange-300">Side Effects</CardTitle>
                <CardDescription>Potential adverse reactions</CardDescription>
              </CardHeader>
              <CardContent>
                <RichContent className="prose prose-sm max-w-none dark:prose-invert" html={drug.side_effects} />
              </CardContent>
            </Card>
          )}

          {drug.warnings && (
            <Card>
              <CardHeader className="pb-4">
                <CardTitle className="text-amber-700 dark:text-amber-300">Warnings & Precautions</CardTitle>
                <CardDescription>Important safety information</CardDescription>
              </CardHeader>
              <CardContent>
                <RichContent className="prose prose-sm max-w-none dark:prose-invert" html={drug.warnings} />
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="dosing" className="mt-8 space-y-8">
          <div className="grid gap-8 lg:grid-cols-2">
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Dosing Information</CardTitle>
                <CardDescription>Standard dosing by patient population</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {drug.adult_dose && (
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Adult Dose</Label>
                    <p className="text-sm font-mono bg-muted p-3 rounded-md">{drug.adult_dose}</p>
                  </div>
                )}

                {drug.pediatric_dose && (
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Pediatric Dose</Label>
                    <p className="text-sm font-mono bg-muted p-3 rounded-md">{drug.pediatric_dose}</p>
                  </div>
                )}

                {drug.elderly_dose && (
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Elderly Dose</Label>
                    <p className="text-sm font-mono bg-muted p-3 rounded-md">{drug.elderly_dose}</p>
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Administration Details</CardTitle>
                <CardDescription>Frequency, duration, and limits</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {drug.frequency && (
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Frequency</Label>
                    <p className="text-sm font-mono bg-muted p-3 rounded-md">{drug.frequency}</p>
                  </div>
                )}

                {drug.duration && (
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Duration</Label>
                    <p className="text-sm font-mono bg-muted p-3 rounded-md">{drug.duration}</p>
                  </div>
                )}

                {drug.max_daily_dose && (
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Maximum Daily Dose</Label>
                    <div className="bg-destructive/5 border border-destructive/20 p-3 rounded-md">
                      <p className="text-sm font-mono font-medium text-destructive">{drug.max_daily_dose}</p>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {drug.monitoring_parameters && (
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Monitoring Parameters</CardTitle>
                <CardDescription>What to monitor during treatment</CardDescription>
              </CardHeader>
              <CardContent>
                <p className="leading-relaxed">{drug.monitoring_parameters}</p>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="safety" className="mt-8 space-y-8">
          {(() => {
            const hasPregnancy = drug.pregnancy_category;
            const hasControlled = drug.controlled_substance && drug.controlled_substance !== "None";
            const bothCards = hasPregnancy && hasControlled;
            
            if (!hasPregnancy && !hasControlled) return null;

            return (
              <div className={bothCards ? "grid gap-8 lg:grid-cols-2" : "space-y-8"}>
                {drug.pregnancy_category && (
                  <Card>
                    <CardHeader className="pb-4">
                      <CardTitle>Pregnancy & Lactation</CardTitle>
                      <CardDescription>Safety during pregnancy and breastfeeding</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div className="space-y-3">
                        <Label className="text-sm font-medium text-muted-foreground">Pregnancy Category</Label>
                        <div>
                          <Badge 
                            variant={drug.pregnancy_category === 'A' || drug.pregnancy_category === 'B' ? 'default' : 'destructive'}
                            className="font-medium"
                          >
                            Category {drug.pregnancy_category}
                          </Badge>
                        </div>
                        <div className="text-sm text-muted-foreground bg-muted p-3 rounded-md">
                          {drug.pregnancy_category === 'A' && 'No risk in controlled studies'}
                          {drug.pregnancy_category === 'B' && 'No risk in animal studies'}
                          {drug.pregnancy_category === 'C' && 'Risk cannot be ruled out'}
                          {drug.pregnancy_category === 'D' && 'Positive evidence of risk'}
                          {drug.pregnancy_category === 'X' && 'Contraindicated in pregnancy'}
                          {drug.pregnancy_category === 'Unknown' && 'Safety profile unknown'}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                )}

                {(drug.controlled_substance && drug.controlled_substance !== "None") && (
                  <Card>
                    <CardHeader className="pb-4">
                      <CardTitle>Controlled Substance</CardTitle>
                      <CardDescription>Regulatory classification</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <Badge variant="destructive" className="font-medium">
                        {drug.controlled_substance}
                      </Badge>
                      <div className="text-sm text-muted-foreground bg-muted p-3 rounded-md">
                        Special handling and prescribing requirements may apply
                      </div>
                    </CardContent>
                  </Card>
                )}
              </div>
            );
          })()}

          {(drug.warnings || drug.side_effects) && (
            <Card className="border-destructive/20">
              <CardHeader className="pb-4">
                <CardTitle className="text-destructive">Important Safety Information</CardTitle>
                <CardDescription>Critical warnings and adverse effects</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {drug.warnings && (
                  <div className="space-y-3">
                    <Label className="text-sm font-semibold text-destructive">Warnings & Precautions</Label>
                    <div className="bg-destructive/5 border border-destructive/20 p-4 rounded-md">
                      <RichContent className="prose prose-sm max-w-none dark:prose-invert" html={drug.warnings} />
                    </div>
                  </div>
                )}
                
                {drug.side_effects && (
                  <div className="space-y-3">
                    <Label className="text-sm font-semibold text-orange-700 dark:text-orange-300">Adverse Effects</Label>
                    <div className="bg-orange-50 dark:bg-orange-950/20 border border-orange-200 dark:border-orange-900 p-4 rounded-md">
                      <RichContent className="prose prose-sm max-w-none dark:prose-invert" html={drug.side_effects} />
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="regulatory" className="mt-8 space-y-8">
          <div className="grid gap-8 lg:grid-cols-2">
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Drug Status</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="space-y-3">
                  <Label className="text-sm font-medium text-muted-foreground">Current Status</Label>
                  <Badge variant={drug.status === 'active' ? 'default' : 'secondary'} className="font-medium">
                    {drug.status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </Badge>
                </div>
                
                <div className="space-y-3">
                  <Label className="text-sm font-medium text-muted-foreground">Review Status</Label>
                  <Badge variant={drug.review_status === 'approved' ? 'default' : 'outline'} className="font-medium">
                    {drug.review_status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </Badge>
                </div>
              </CardContent>
            </Card>

            {(drug.who_eml_status || drug.antimicrobial_status) && (
              <Card>
                <CardHeader className="pb-4">
                  <CardTitle>Special Designations</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  {drug.who_eml_status && (
                    <div className="space-y-2">
                      <Badge variant="secondary" className="font-medium">WHO Essential Medicine List</Badge>
                      <p className="text-sm text-muted-foreground">
                        Listed as essential by the World Health Organization
                      </p>
                    </div>
                  )}
                  
                  {drug.antimicrobial_status && (
                    <div className="space-y-2">
                      <Badge variant="destructive" className="font-medium">Antimicrobial Agent</Badge>
                      <p className="text-sm text-muted-foreground">
                        Subject to antimicrobial stewardship guidelines
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>

        <TabsContent value="metadata" className="mt-8 space-y-8">
          {drug.clinical_notes && (
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Clinical Notes</CardTitle>
                <CardDescription>Additional clinical information and observations</CardDescription>
              </CardHeader>
              <CardContent>
                <RichContent className="prose prose-sm max-w-none dark:prose-invert" html={drug.clinical_notes} />
              </CardContent>
            </Card>
          )}

          {drug.references && (
            <Card>
              <CardHeader className="pb-4">
                <CardTitle>References</CardTitle>
                <CardDescription>Medical literature and citations</CardDescription>
              </CardHeader>
              <CardContent>
                <RichContent className="prose prose-sm max-w-none dark:prose-invert" html={drug.references} />
              </CardContent>
            </Card>
          )}

          <div className="grid gap-8 lg:grid-cols-2">
            {drug.search_keywords && (
              <Card>
                <CardHeader className="pb-4">
                  <CardTitle>Search Keywords</CardTitle>
                  <CardDescription>Terms used for drug lookup and indexing</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="flex flex-wrap gap-2">
                    {drug.search_keywords.split(/[,;]\s*/).map((keyword, index) => (
                      <Badge key={index} variant="outline" className="font-medium">
                        {keyword.trim()}
                      </Badge>
                    ))}
                  </div>
                </CardContent>
              </Card>
            )}

            <Card>
              <CardHeader className="pb-4">
                <CardTitle>Record Metadata</CardTitle>
                <CardDescription>Database record information</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="space-y-2">
                  <Label className="text-sm font-medium text-muted-foreground">Drug ID</Label>
                  <p className="text-sm font-mono bg-muted p-2 rounded-md">{drug.id}</p>
                </div>
                
                <div className="grid grid-cols-2 gap-6 pt-4 border-t">
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Created</Label>
                    <p className="text-sm font-medium">
                      {formatDistanceToNow(new Date(drug.created), { addSuffix: true })}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {new Date(drug.created).toLocaleString()}
                    </p>
                  </div>
                  <div className="space-y-2">
                    <Label className="text-sm font-medium text-muted-foreground">Updated</Label>
                    <p className="text-sm font-medium">
                      {formatDistanceToNow(new Date(drug.updated), { addSuffix: true })}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {new Date(drug.updated).toLocaleString()}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}
