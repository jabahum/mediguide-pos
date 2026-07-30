'use client'

import * as React from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Progress } from "@/components/ui/progress"
import { PageHeader } from "@/components/ui/page-header"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  AlertTriangle,
  Clock,
  Activity,
  Stethoscope,
  Zap,
  Phone,
  FileText,
  CheckCircle2,
  Loader2,
  ArrowLeft
} from "lucide-react"
import { backendClient } from "@/lib/backend-client"
import { Collections } from "@/types/backend-types"
import type { EmergencyProtocolsResponse } from "@/types/backend-types"
import { showToast } from "@/lib/toast"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"

export default function TraumaProtocolsPage() {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [protocols, setProtocols] = React.useState<EmergencyProtocolsResponse[]>([])
  const [activeTab, setActiveTab] = React.useState("protocols")
  const [completedSteps, setCompletedSteps] = React.useState<{ [key: string]: number }>({})
  const [loading, setLoading] = React.useState(true)
  const [quickRefOpen, setQuickRefOpen] = React.useState(false)

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/emergency-protocols")
    }
  }, [permLoading, hasPermission, router])

  React.useEffect(() => {
    fetchTraumaProtocols()
  }, [])

  const fetchTraumaProtocols = async () => {
    try {
      const result = await backendClient.resource(Collections.EmergencyProtocols).getList(1, 50, {
        filter: "category = 'Trauma' && status = 'active'",
        sort: "priority"
      })
      setProtocols(result.items as EmergencyProtocolsResponse[])
    } catch (error) {
      console.error("Failed to fetch trauma protocols:", error)
      showToast.error("Error", "Failed to load trauma protocols")
    } finally {
      setLoading(false)
    }
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case "critical": return "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
      case "high": return "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300"
      case "medium": return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300"
      default: return "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300"
    }
  }

  const getPriorityIcon = (priority: string) => {
    switch (priority) {
      case "critical": return <AlertTriangle className="h-4 w-4 text-red-600" />
      case "high": return <Zap className="h-4 w-4 text-orange-600" />
      default: return <Activity className="h-4 w-4 text-blue-600" />
    }
  }

  const toggleStep = (protocolId: string, stepIndex: number) => {
    setCompletedSteps(prev => ({
      ...prev,
      [protocolId]: prev[protocolId] === stepIndex + 1 ? stepIndex : stepIndex + 1
    }))
  }

  // Get vital signs from the first protocol that has them (Primary Survey)
  const primaryProtocol = protocols.find(p => p.title?.includes("Primary Survey"))
  const vitalSigns = primaryProtocol?.vital_signs as {
    normal?: Record<string, string>
    concerning?: Record<string, string>
    critical?: Record<string, string>
  } | undefined

  // Get medications from protocols
  const allMedications = protocols.flatMap(p => {
    const meds = p.medications as Array<{ category: string; name: string; dose: string }> | undefined
    return meds || []
  })
  const medicationsByCategory = allMedications.reduce((acc, med) => {
    if (!acc[med.category]) acc[med.category] = []
    acc[med.category].push(med)
    return acc
  }, {} as Record<string, typeof allMedications>)

  // Get transfer checklist from the first protocol that has it
  const transferChecklist = primaryProtocol?.transfer_checklist as string[] | undefined
  const contactInfo = primaryProtocol?.contact_info as {
    trauma_center?: { name: string; phone: string; ambulance: string }
    hems?: { name: string; dispatch: string; available: string }
    blood_bank?: { name: string; emergency: string; on_call: string }
  } | undefined

  const traumaCenterPhone = contactInfo?.trauma_center?.phone

  const handleEmergencyContact = () => {
    if (!traumaCenterPhone) {
      showToast.error("No contact configured", "Set a trauma center phone on a Primary Survey protocol")
      return
    }
    window.location.href = `tel:${traumaCenterPhone.replace(/[^+\d]/g, "")}`
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Trauma Protocols"
        description="Emergency trauma management protocols and guidelines"
        showBackButton={true}
        onBack={() => router.push('/emergency-protocols')}
        actions={[
          {
            label: traumaCenterPhone ? `Call ${traumaCenterPhone}` : "Emergency Contact",
            variant: "outline",
            icon: <Phone className="h-4 w-4" />,
            onClick: handleEmergencyContact,
          },
          {
            label: "Quick Reference",
            variant: "outline",
            icon: <FileText className="h-4 w-4" />,
            onClick: () => setQuickRefOpen(true),
          },
        ]}
      />

      {/* Critical Alert */}
      <Alert className="border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950">
        <AlertTriangle className="h-4 w-4 text-red-600" />
        <AlertDescription className="text-red-800 dark:text-red-200">
          <strong>Time-Critical:</strong> Golden hour is crucial for trauma outcomes. Begin primary survey immediately upon patient arrival.
        </AlertDescription>
      </Alert>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="protocols">Protocols</TabsTrigger>
          <TabsTrigger value="vitals">Vital Signs</TabsTrigger>
          <TabsTrigger value="medications">Medications</TabsTrigger>
          <TabsTrigger value="transfer">Transfer</TabsTrigger>
        </TabsList>

        <TabsContent value="protocols" className="space-y-6">
          {/* Protocol Cards */}
          <div className="grid gap-6 lg:grid-cols-2">
            {protocols.length === 0 ? (
              <Card>
                <CardContent className="p-8 text-center">
                  <p className="text-muted-foreground">No trauma protocols found</p>
                </CardContent>
              </Card>
            ) : (
              protocols.map((protocol) => {
                const steps = (protocol.steps as string[]) || []
                const criticalActions = (protocol.critical_actions as string[]) || []
                const completed = completedSteps[protocol.id] || 0
                const progress = steps.length > 0 ? (completed / steps.length) * 100 : 0

                return (
                  <Card key={protocol.id} className="hover:shadow-lg transition-shadow">
                    <CardHeader>
                      <div className="flex items-start justify-between">
                        <div className="space-y-2">
                          <div className="flex items-center space-x-2">
                            {getPriorityIcon(protocol.priority)}
                            <CardTitle className="text-lg">{protocol.title}</CardTitle>
                          </div>
                          <div className="flex items-center space-x-4">
                            <Badge className={getPriorityColor(protocol.priority)}>
                              {protocol.priority}
                            </Badge>
                            {protocol.timeframe && (
                              <div className="flex items-center space-x-1 text-sm text-muted-foreground">
                                <Clock className="h-3 w-3" />
                                {protocol.timeframe}
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                      {progress > 0 && (
                        <div className="space-y-2">
                          <div className="flex justify-between text-sm">
                            <span>Progress</span>
                            <span>{completed}/{steps.length}</span>
                          </div>
                          <Progress value={progress} className="h-2" />
                        </div>
                      )}
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-4">
                        {steps.length > 0 && (
                          <div>
                            <h4 className="font-medium text-sm text-muted-foreground mb-2">Protocol Steps</h4>
                            <div className="space-y-2">
                              {steps.map((step, index) => (
                                <div
                                  key={index}
                                  className={`flex items-start space-x-2 p-2 rounded-md cursor-pointer transition-colors ${index < completed
                                      ? 'bg-green-50 dark:bg-green-950 border border-green-200 dark:border-green-800'
                                      : 'hover:bg-muted'
                                    }`}
                                  onClick={() => toggleStep(protocol.id, index)}
                                >
                                  <div className="mt-0.5">
                                    {index < completed ? (
                                      <CheckCircle2 className="h-4 w-4 text-green-600" />
                                    ) : (
                                      <div className="h-4 w-4 rounded-full border-2 border-muted-foreground" />
                                    )}
                                  </div>
                                  <span className={`text-sm ${index < completed ? 'text-green-800 dark:text-green-200' : ''}`}>
                                    {step}
                                  </span>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}

                        {criticalActions.length > 0 && (
                          <div>
                            <h4 className="font-medium text-sm text-muted-foreground mb-2">Critical Actions</h4>
                            <div className="flex flex-wrap gap-1">
                              {criticalActions.map((action, index) => (
                                <Badge key={index} variant="secondary" className="text-xs">
                                  {action}
                                </Badge>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                )
              })
            )}
          </div>
        </TabsContent>

        <TabsContent value="vitals" className="space-y-6">
          {vitalSigns ? (
            <div className="grid gap-6 md:grid-cols-3">
              {['normal', 'concerning', 'critical'].map((category) => {
                const ranges = vitalSigns[category as keyof typeof vitalSigns]
                if (!ranges) return null
                return (
                  <Card key={category}>
                    <CardHeader>
                      <CardTitle className="flex items-center space-x-2">
                        <Stethoscope className="h-5 w-5" />
                        <span className="capitalize">{category} Ranges</span>
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-3">
                        {ranges.systolic && (
                          <div className="flex justify-between">
                            <span className="text-sm">Systolic BP:</span>
                            <span className="text-sm font-medium">{ranges.systolic} mmHg</span>
                          </div>
                        )}
                        {ranges.diastolic && (
                          <div className="flex justify-between">
                            <span className="text-sm">Diastolic BP:</span>
                            <span className="text-sm font-medium">{ranges.diastolic} mmHg</span>
                          </div>
                        )}
                        {ranges.hr && (
                          <div className="flex justify-between">
                            <span className="text-sm">Heart Rate:</span>
                            <span className="text-sm font-medium">{ranges.hr} bpm</span>
                          </div>
                        )}
                        {ranges.rr && (
                          <div className="flex justify-between">
                            <span className="text-sm">Respiratory Rate:</span>
                            <span className="text-sm font-medium">{ranges.rr} /min</span>
                          </div>
                        )}
                        {ranges.temp && (
                          <div className="flex justify-between">
                            <span className="text-sm">Temperature:</span>
                            <span className="text-sm font-medium">{ranges.temp} °C</span>
                          </div>
                        )}
                        {ranges.spo2 && (
                          <div className="flex justify-between">
                            <span className="text-sm">SpO2:</span>
                            <span className="text-sm font-medium">{ranges.spo2}%</span>
                          </div>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                )
              })}
            </div>
          ) : (
            <Card>
              <CardContent className="p-8 text-center">
                <p className="text-muted-foreground">No vital signs data configured</p>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="medications" className="space-y-6">
          {Object.keys(medicationsByCategory).length > 0 ? (
            <div className="grid gap-4 md:grid-cols-2">
              {Object.entries(medicationsByCategory).map(([category, meds]) => (
                <Card key={category}>
                  <CardHeader>
                    <CardTitle>{category}</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-2 text-sm">
                      {meds.map((med, index) => (
                        <div key={index}><strong>{med.name}:</strong> {med.dose}</div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : (
            <Card>
              <CardContent className="p-8 text-center">
                <p className="text-muted-foreground">No medications configured</p>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="transfer" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Transfer Checklist</CardTitle>
              </CardHeader>
              <CardContent>
                {transferChecklist && transferChecklist.length > 0 ? (
                  <div className="space-y-3">
                    {transferChecklist.map((item, index) => (
                      <div key={index} className="flex items-center space-x-2">
                        <div className="h-4 w-4 rounded border-2 border-muted-foreground" />
                        <span className="text-sm">{item}</span>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-muted-foreground">No transfer checklist configured</p>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Contact Information</CardTitle>
              </CardHeader>
              <CardContent>
                {contactInfo ? (
                  <div className="space-y-3 text-sm">
                    {contactInfo.trauma_center && (
                      <div>
                        <strong>{contactInfo.trauma_center.name}:</strong><br />
                        Phone: {contactInfo.trauma_center.phone}<br />
                        Ambulance: {contactInfo.trauma_center.ambulance}
                      </div>
                    )}
                    {contactInfo.hems && (
                      <div>
                        <strong>{contactInfo.hems.name}:</strong><br />
                        Dispatch: {contactInfo.hems.dispatch}<br />
                        Available: {contactInfo.hems.available}
                      </div>
                    )}
                    {contactInfo.blood_bank && (
                      <div>
                        <strong>{contactInfo.blood_bank.name}:</strong><br />
                        Emergency: {contactInfo.blood_bank.emergency}<br />
                        On-call: {contactInfo.blood_bank.on_call}
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-muted-foreground">No contact information configured</p>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>

      <Dialog open={quickRefOpen} onOpenChange={setQuickRefOpen}>
        <DialogContent className="max-w-2xl max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              <FileText className="h-5 w-5 text-red-600" />
              <span>Trauma Quick Reference</span>
            </DialogTitle>
            <DialogDescription>
              At-a-glance cheat sheet for trauma management
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-5 text-sm">
            <div className="rounded-md border border-red-200 bg-red-50 p-3 dark:border-red-800 dark:bg-red-950">
              <div className="flex items-start space-x-2 text-red-800 dark:text-red-200">
                <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
                <span>
                  <strong>Golden hour:</strong> Begin primary survey (ABCDE) immediately. Definitive care within 60 min of injury.
                </span>
              </div>
            </div>

            {vitalSigns?.normal && (
              <div>
                <h4 className="mb-2 font-semibold">Normal Adult Vitals</h4>
                <div className="grid grid-cols-2 gap-x-4 gap-y-1">
                  {Object.entries(vitalSigns.normal).map(([key, value]) => (
                    <div key={key} className="flex justify-between">
                      <span className="capitalize text-muted-foreground">{key.replace(/_/g, " ")}</span>
                      <span className="font-medium">{value}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {vitalSigns?.critical && (
              <div>
                <h4 className="mb-2 font-semibold text-red-700 dark:text-red-400">Critical Thresholds</h4>
                <div className="grid grid-cols-2 gap-x-4 gap-y-1">
                  {Object.entries(vitalSigns.critical).map(([key, value]) => (
                    <div key={key} className="flex justify-between">
                      <span className="capitalize text-muted-foreground">{key.replace(/_/g, " ")}</span>
                      <span className="font-medium">{value}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {Object.keys(medicationsByCategory).length > 0 && (
              <div>
                <h4 className="mb-2 font-semibold">Key Medications</h4>
                <div className="space-y-3">
                  {Object.entries(medicationsByCategory).map(([category, meds]) => (
                    <div key={category}>
                      <div className="mb-1 text-xs font-medium uppercase tracking-wide text-muted-foreground">{category}</div>
                      <div className="space-y-0.5">
                        {meds.map((med, i) => (
                          <div key={i}>
                            <strong>{med.name}:</strong> {med.dose}
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {contactInfo?.trauma_center && (
              <div>
                <h4 className="mb-2 font-semibold">Emergency Contacts</h4>
                <div className="space-y-1">
                  <div>
                    <strong>{contactInfo.trauma_center.name}:</strong> {contactInfo.trauma_center.phone}
                  </div>
                  {contactInfo.hems && (
                    <div>
                      <strong>{contactInfo.hems.name}:</strong> {contactInfo.hems.dispatch}
                    </div>
                  )}
                  {contactInfo.blood_bank && (
                    <div>
                      <strong>{contactInfo.blood_bank.name}:</strong> {contactInfo.blood_bank.emergency}
                    </div>
                  )}
                </div>
              </div>
            )}

            {!vitalSigns && !Object.keys(medicationsByCategory).length && !contactInfo && (
              <p className="text-muted-foreground">
                No reference data configured. Add vitals, medications, and contact info to a Primary Survey protocol.
              </p>
            )}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
