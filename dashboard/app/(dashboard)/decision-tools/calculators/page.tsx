'use client'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { PageHeader } from "@/components/ui/page-header"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import {
  Calculator,
  Plus,
  Activity,
  TrendingUp,
  FileText,
  Target,
  Loader2,
  ExternalLink,
  Play
} from "lucide-react"
import { useState, useEffect, useCallback } from "react"
import * as React from "react"
import { useRouter } from "next/navigation"
import { pb, getCurrentUser } from "@/lib/pocketbase"
import { Collections } from "@/types/pocketbase-types"
import type { CalculatorsResponse } from "@/types/pocketbase-types"
import { showToast } from "@/lib/toast"
import { Skeleton } from "@/components/ui/skeleton"
import { usePermissionContext } from "@/lib/permission-context"
import { getBundledAppFileUrl } from "../app-file"

// Built-in calculators that don't require uploaded files
const builtInCalculators = [
  {
    id: "bmi",
    name: "BMI Calculator",
    category: "Nutritional",
    description: "Calculate Body Mass Index and classify weight status",
    type: "calculator" as const,
    status: "active" as const,
    fields: [
      { name: "weight", label: "Weight (kg)", type: "number", placeholder: "70" },
      { name: "height", label: "Height (cm)", type: "number", placeholder: "170" }
    ],
    formula: "BMI = weight(kg) / height(m)²",
    isBuiltIn: true
  },
  {
    id: "gcs",
    name: "Glasgow Coma Scale",
    category: "Emergency",
    description: "Assess level of consciousness in emergency situations",
    type: "calculator" as const,
    status: "active" as const,
    fields: [
      {
        name: "eye", label: "Eye Opening", type: "select", options: [
          { value: "4", label: "Spontaneous (4)" },
          { value: "3", label: "To speech (3)" },
          { value: "2", label: "To pain (2)" },
          { value: "1", label: "None (1)" }
        ]
      },
      {
        name: "verbal", label: "Verbal Response", type: "select", options: [
          { value: "5", label: "Oriented (5)" },
          { value: "4", label: "Confused (4)" },
          { value: "3", label: "Inappropriate words (3)" },
          { value: "2", label: "Incomprehensible sounds (2)" },
          { value: "1", label: "None (1)" }
        ]
      },
      {
        name: "motor", label: "Motor Response", type: "select", options: [
          { value: "6", label: "Obeys commands (6)" },
          { value: "5", label: "Localizes pain (5)" },
          { value: "4", label: "Withdrawal from pain (4)" },
          { value: "3", label: "Flexion to pain (3)" },
          { value: "2", label: "Extension to pain (2)" },
          { value: "1", label: "None (1)" }
        ]
      }
    ],
    isBuiltIn: true
  },
  {
    id: "apgar",
    name: "APGAR Score",
    category: "Obstetrics",
    description: "Assess newborn condition at birth",
    type: "calculator" as const,
    status: "active" as const,
    fields: [
      {
        name: "appearance", label: "Appearance (Color)", type: "select", options: [
          { value: "2", label: "Pink all over (2)" },
          { value: "1", label: "Pink body, blue extremities (1)" },
          { value: "0", label: "Blue/pale all over (0)" }
        ]
      },
      {
        name: "pulse", label: "Pulse (Heart Rate)", type: "select", options: [
          { value: "2", label: ">100 bpm (2)" },
          { value: "1", label: "<100 bpm (1)" },
          { value: "0", label: "Absent (0)" }
        ]
      },
      {
        name: "grimace", label: "Grimace (Reflex)", type: "select", options: [
          { value: "2", label: "Cough/sneeze/cry (2)" },
          { value: "1", label: "Grimace (1)" },
          { value: "0", label: "No response (0)" }
        ]
      },
      {
        name: "activity", label: "Activity (Muscle Tone)", type: "select", options: [
          { value: "2", label: "Active movement (2)" },
          { value: "1", label: "Some flexion (1)" },
          { value: "0", label: "Limp (0)" }
        ]
      },
      {
        name: "respiration", label: "Respiration", type: "select", options: [
          { value: "2", label: "Strong cry (2)" },
          { value: "1", label: "Weak cry (1)" },
          { value: "0", label: "Absent (0)" }
        ]
      }
    ],
    isBuiltIn: true
  },
  {
    id: "wells",
    name: "Wells Score (DVT)",
    category: "Vascular",
    description: "Assess probability of deep vein thrombosis",
    type: "calculator" as const,
    status: "active" as const,
    fields: [
      { name: "cancer", label: "Active cancer", type: "checkbox", points: 1 },
      { name: "paralysis", label: "Paralysis/paresis/immobilization", type: "checkbox", points: 1 },
      { name: "bedrest", label: "Bedrest >3 days or surgery <4 weeks", type: "checkbox", points: 1 },
      { name: "tenderness", label: "Localized tenderness along deep veins", type: "checkbox", points: 1 },
      { name: "swelling", label: "Entire leg swollen", type: "checkbox", points: 1 },
      { name: "calf", label: "Calf swelling >3cm compared to other leg", type: "checkbox", points: 1 },
      { name: "pitting", label: "Pitting edema", type: "checkbox", points: 1 },
      { name: "veins", label: "Collateral superficial veins", type: "checkbox", points: 1 },
      { name: "alternative", label: "Alternative diagnosis as likely", type: "checkbox", points: -2 }
    ],
    isBuiltIn: true
  },
  {
    id: "creatinine",
    name: "Creatinine Clearance",
    category: "Renal",
    description: "Estimate kidney function using Cockcroft-Gault equation",
    type: "calculator" as const,
    status: "active" as const,
    fields: [
      { name: "age", label: "Age (years)", type: "number", placeholder: "65" },
      { name: "weight", label: "Weight (kg)", type: "number", placeholder: "70" },
      {
        name: "sex", label: "Sex", type: "select", options: [
          { value: "male", label: "Male" },
          { value: "female", label: "Female" }
        ]
      },
      { name: "creatinine", label: "Serum Creatinine (mg/dL)", type: "number", placeholder: "1.2" }
    ],
    formula: "CrCl = [(140-age) × weight] / (72 × SCr) × 0.85 (if female)",
    isBuiltIn: true
  },
  {
    id: "hba1c",
    name: "HbA1c Converter",
    category: "Diabetes",
    description: "Convert between HbA1c percentage and estimated average glucose",
    type: "calculator" as const,
    status: "active" as const,
    fields: [
      { name: "hba1c", label: "HbA1c (%)", type: "number", placeholder: "7.0" }
    ],
    formula: "eAG (mg/dL) = 28.7 × HbA1c - 46.7",
    isBuiltIn: true
  }
]

interface CalculatorDef {
  id: string
  name: string
  category: string
  description: string
  type: string
  status: string
  fields?: Array<{
    name: string
    label: string
    type: string
    placeholder?: string
    options?: Array<{ value: string; label: string }>
    points?: number
  }>
  formula?: string
  isBuiltIn?: boolean
  appFile?: unknown
}

export default function CalculatorsPage() {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [dbCalculators, setDbCalculators] = useState<CalculatorsResponse[]>([])
  const [selectedCalculator, setSelectedCalculator] = useState<string>("bmi")
  const [calculatorInputs, setCalculatorInputs] = useState<Record<string, Record<string, string | number | boolean>>>({})
  const [results, setResults] = useState<Record<string, { value: number; category?: string; description?: string; recommendation?: string }>>({})
  const [loading, setLoading] = useState(true)
  const [requestOpen, setRequestOpen] = useState(false)
  const [requestSubmitting, setRequestSubmitting] = useState(false)
  const [requestForm, setRequestForm] = useState({
    name: "",
    category: "",
    description: "",
    justification: "",
  })

  const resetRequestForm = () => {
    setRequestForm({ name: "", category: "", description: "", justification: "" })
  }

  const handleSubmitRequest = async () => {
    const name = requestForm.name.trim()
    const description = requestForm.description.trim()
    if (!name || !description) {
      showToast.error("Missing fields", "Please provide a name and description")
      return
    }
    const user = getCurrentUser()
    if (!user?.id) {
      showToast.error("Authentication required", "Please log in to submit a request")
      return
    }

    const category = requestForm.category.trim()
    const justification = requestForm.justification.trim()

    const ticketDescription = [
      `<p><strong>Calculator name:</strong> ${name}</p>`,
      category ? `<p><strong>Category:</strong> ${category}</p>` : "",
      `<p><strong>Description:</strong></p><p>${description.replace(/\n/g, "<br/>")}</p>`,
      justification
        ? `<p><strong>Clinical justification:</strong></p><p>${justification.replace(/\n/g, "<br/>")}</p>`
        : "",
    ]
      .filter(Boolean)
      .join("")

    setRequestSubmitting(true)
    let requestRecordId: string | null = null
    try {
      const requestRecord = await pb.collection("calculator_requests").create({
        name,
        category: category || undefined,
        description,
        justification: justification || undefined,
        requestedBy: user.id,
        status: "pending",
      })
      requestRecordId = requestRecord.id

      const ticket = await pb.collection("support_tickets").create({
        subject: `Calculator Request: ${name}`,
        description: ticketDescription,
        status: "open",
        priority: "normal",
        category: "Calculator Request",
        user_id: user.id,
      })

      try {
        await pb.collection("calculator_requests").update(requestRecord.id, {
          supportTicket: ticket.id,
        })
      } catch (linkError) {
        console.warn("Created ticket but failed to link it back to the request:", linkError)
      }

      showToast.success(
        "Request submitted",
        "Your calculator request was logged as a support ticket"
      )
      setRequestOpen(false)
      resetRequestForm()
    } catch (error) {
      console.error("Failed to submit calculator request:", error)
      if (requestRecordId) {
        showToast.error(
          "Partial submission",
          "Request saved but creating the support ticket failed. An admin will follow up."
        )
        setRequestOpen(false)
        resetRequestForm()
      } else {
        showToast.error("Submission failed", "Could not submit your request. Try again later.")
      }
    } finally {
      setRequestSubmitting(false)
    }
  }

  useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/decision-tools")
    }
  }, [permLoading, hasPermission, router])

  React.useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/decision-tools")
    }
  }, [permLoading, hasPermission, router])

  const fetchCalculators = useCallback(async () => {
    try {
      const result = await pb.collection(Collections.Calculators).getList(1, 50, {
        filter: "status = 'active'",
        sort: "-featured,name"
      })
      setDbCalculators(result.items as CalculatorsResponse[])
    } catch (error) {
      console.error("Failed to fetch calculators:", error)
      showToast.error("Error", "Failed to load calculators")
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchCalculators()
  }, [fetchCalculators])

  // Combine built-in calculators with database calculators
  const allCalculators: CalculatorDef[] = [
    ...builtInCalculators,
    ...dbCalculators.map(c => ({
      id: c.id,
      name: c.name,
      category: c.type === "decision_tool" ? "Decision Tool" : c.type === "checklist" ? "Checklist" : "Calculator",
      description: c.description || "",
      type: c.type,
      status: c.status,
      appFile: c.appFile,
      isBuiltIn: false
    }))
  ]

  const calculator = allCalculators.find(c => c.id === selectedCalculator)
  const isBuiltIn = calculator?.isBuiltIn

  const handleInputChange = (field: string, value: string | boolean) => {
    setCalculatorInputs(prev => ({
      ...prev,
      [selectedCalculator]: {
        ...prev[selectedCalculator],
        [field]: value
      }
    }))
  }

  const calculate = () => {
    const inputs = calculatorInputs[selectedCalculator] || {}
    let result: { value: number; category?: string; description?: string; recommendation?: string } = { value: 0 }

    switch (selectedCalculator) {
      case "bmi":
        const weight = parseFloat(String(inputs.weight))
        const height = parseFloat(String(inputs.height)) / 100
        if (weight && height) {
          const bmi = weight / (height * height)
          let category = ""
          if (bmi < 18.5) { category = "Underweight" }
          else if (bmi < 25) { category = "Normal weight" }
          else if (bmi < 30) { category = "Overweight" }
          else { category = "Obese" }

          result = { value: parseFloat(bmi.toFixed(1)), category }
        }
        break

      case "gcs":
        const eye = parseInt(String(inputs.eye) || "0")
        const verbal = parseInt(String(inputs.verbal) || "0")
        const motor = parseInt(String(inputs.motor) || "0")
        const total = eye + verbal + motor
        let interpretation = ""
        if (total >= 13) interpretation = "Mild brain injury"
        else if (total >= 9) interpretation = "Moderate brain injury"
        else if (total >= 3) interpretation = "Severe brain injury"

        result = { value: total, category: interpretation, description: `E${eye} V${verbal} M${motor}` }
        break

      case "apgar":
        const appearance = parseInt(String(inputs.appearance) || "0")
        const pulse = parseInt(String(inputs.pulse) || "0")
        const grimace = parseInt(String(inputs.grimace) || "0")
        const activity = parseInt(String(inputs.activity) || "0")
        const respiration = parseInt(String(inputs.respiration) || "0")
        const apgarTotal = appearance + pulse + grimace + activity + respiration
        let apgarInterpretation = ""
        if (apgarTotal >= 7) apgarInterpretation = "Normal"
        else if (apgarTotal >= 4) apgarInterpretation = "Moderate depression"
        else apgarInterpretation = "Severe depression"

        result = { value: apgarTotal, category: apgarInterpretation }
        break

      case "wells":
        let wellsScore = 0
        const builtInCalc = builtInCalculators.find(c => c.id === "wells")
        builtInCalc?.fields?.forEach(field => {
          if (inputs[field.name] && 'points' in field && field.points) {
            wellsScore += field.points
          }
        })
        let dvtProbability = ""
        if (wellsScore >= 3) dvtProbability = "High probability (>75%)"
        else if (wellsScore >= 1) dvtProbability = "Moderate probability (17-33%)"
        else dvtProbability = "Low probability (<5%)"

        result = { value: wellsScore, category: dvtProbability }
        break

      case "creatinine":
        const age = parseInt(String(inputs.age))
        const weightKg = parseFloat(String(inputs.weight))
        const creatinine = parseFloat(String(inputs.creatinine))
        const isFemale = inputs.sex === "female"

        if (age && weightKg && creatinine) {
          let crCl = ((140 - age) * weightKg) / (72 * creatinine)
          if (isFemale) crCl *= 0.85

          let stage = ""
          if (crCl >= 90) stage = "Normal (Stage 1)"
          else if (crCl >= 60) stage = "Mild CKD (Stage 2)"
          else if (crCl >= 30) stage = "Moderate CKD (Stage 3)"
          else if (crCl >= 15) stage = "Severe CKD (Stage 4)"
          else stage = "End-stage CKD (Stage 5)"

          result = { value: parseFloat(crCl.toFixed(1)), category: stage, description: "mL/min" }
        }
        break

      case "hba1c":
        const hba1cValue = parseFloat(String(inputs.hba1c))
        if (hba1cValue) {
          const eag = 28.7 * hba1cValue - 46.7
          result = { value: parseFloat(eag.toFixed(0)), category: `HbA1c: ${hba1cValue}%`, description: "mg/dL estimated average glucose" }
        }
        break
    }

    setResults(prev => ({
      ...prev,
      [selectedCalculator]: result
    }))
  }

  const currentInputs = calculatorInputs[selectedCalculator] || {}
  const currentResult = results[selectedCalculator]

  // Calculate stats
  const totalCalculations = dbCalculators.reduce((sum, c) => sum + (c.usageCount || 0), 0)
  const mostUsed = dbCalculators.length > 0
    ? dbCalculators.reduce((max, c) => (c.usageCount || 0) > (max.usageCount || 0) ? c : max, dbCalculators[0])?.name
    : "BMI Calculator"
  const activeCalculators = allCalculators.length

  if (loading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Medical Calculators"
          description="Clinical calculators and assessment tools for healthcare decisions"
        />
        <div className="flex items-center justify-center h-64">
          <Loader2 className="h-8 w-8 animate-spin" />
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Medical Calculators"
        description="Clinical calculators and assessment tools for healthcare decisions"
        actions={[
          {
            label: "All Calculators",
            variant: "outline",
            icon: <FileText className="h-4 w-4" />,
            onClick: () => router.push("/decision-tools?type=calculator"),
          },
          {
            label: "Request Calculator",
            icon: <Plus className="h-4 w-4" />,
            onClick: () => setRequestOpen(true),
          },
        ]}
      />

      {/* Overview Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Calculations</CardTitle>
            <Calculator className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalCalculations.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">All time</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Most Popular</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{mostUsed}</div>
            <p className="text-xs text-muted-foreground">Most frequently used</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Daily Average</CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{Math.round(totalCalculations / 30) || 156}</div>
            <p className="text-xs text-muted-foreground">Calculations per day</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Available Tools</CardTitle>
            <Target className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activeCalculators}</div>
            <p className="text-xs text-muted-foreground">Active calculators</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Calculator List */}
        <Card>
          <CardHeader>
            <CardTitle>Available Calculators</CardTitle>
            <CardDescription>Select a calculator to use</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {allCalculators.map((calc) => (
                <button
                  key={calc.id}
                  onClick={() => setSelectedCalculator(calc.id)}
                  className={`w-full text-left p-3 rounded-lg border transition-colors ${selectedCalculator === calc.id
                      ? 'bg-primary/5 border-primary'
                      : 'hover:bg-muted border-border'
                    }`}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="font-medium">{calc.name}</h4>
                      <p className="text-sm text-muted-foreground">{calc.description}</p>
                    </div>
                    <Badge variant="outline">{calc.category}</Badge>
                  </div>
                </button>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Calculator Input */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Calculator className="h-5 w-5" />
              <span>{calculator?.name}</span>
            </CardTitle>
            <CardDescription>{calculator?.description}</CardDescription>
          </CardHeader>
          <CardContent>
            {isBuiltIn && calculator?.fields ? (
              <div className="space-y-4">
                {calculator.fields.map((field) => (
                  <div key={field.name}>
                    <label className="text-sm font-medium">{field.label}</label>
                    {field.type === "number" && (
                      <Input
                        type="number"
                        placeholder={'placeholder' in field ? field.placeholder : ''}
                        value={String(currentInputs[field.name] || "")}
                        onChange={(e) => handleInputChange(field.name, e.target.value)}
                        className="mt-1"
                      />
                    )}
                    {field.type === "select" && 'options' in field && field.options && (
                      <Select
                        value={String(currentInputs[field.name] || "")}
                        onValueChange={(value) => handleInputChange(field.name, value)}
                      >
                        <SelectTrigger className="mt-1">
                          <SelectValue placeholder="Select..." />
                        </SelectTrigger>
                        <SelectContent>
                          {field.options.map((option) => (
                            <SelectItem key={option.value} value={option.value}>
                              {option.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    )}
                    {field.type === "checkbox" && (
                      <div className="flex items-center space-x-2 mt-1">
                        <input
                          id={`checkbox-${field.name}`}
                          type="checkbox"
                          checked={Boolean(currentInputs[field.name]) || false}
                          onChange={(e) => handleInputChange(field.name, e.target.checked)}
                          className="rounded"
                        />
                        <label htmlFor={`checkbox-${field.name}`} className="text-sm cursor-pointer">
                          +{'points' in field ? field.points : 0} points
                        </label>
                      </div>
                    )}
                  </div>
                ))}

                <Button onClick={calculate} className="w-full">
                  Calculate
                </Button>

                {calculator.formula && (
                  <div className="text-xs text-muted-foreground p-2 bg-muted rounded">
                    <strong>Formula:</strong> {calculator.formula}
                  </div>
                )}
              </div>
            ) : calculator?.appFile ? (
              <div className="space-y-4">
                <p className="text-sm text-muted-foreground">
                  This is a custom calculator application. Click below to launch it.
                </p>
                <Button className="w-full" onClick={() => {
                  const record = dbCalculators.find(c => c.id === calculator.id)
                  if (!record) {
                    showToast.error("Launch failed", "Calculator record not found")
                    return
                  }
                  if (!calculator.appFile) {
                    showToast.error("Launch failed", "No application file is attached to this calculator")
                    return
                  }
                  const fileUrl = getBundledAppFileUrl(calculator.appFile)
                  if (!fileUrl) {
                    showToast.error("Launch failed", "The attached application file is not a supported HTML tool")
                    return
                  }
                  const win = window.open(fileUrl, "_blank", "noopener,noreferrer")
                  if (!win) {
                    showToast.error("Popup blocked", "Allow popups for this site to launch the calculator")
                  }
                }}>
                  <Play className="h-4 w-4 mr-2" />
                  Launch Calculator
                </Button>
              </div>
            ) : (
              <div className="text-center text-muted-foreground py-8">
                <p>No input fields configured for this calculator</p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Request Calculator Dialog */}
        <Dialog
          open={requestOpen}
          onOpenChange={(open) => {
            setRequestOpen(open)
            if (!open) resetRequestForm()
          }}
        >
          <DialogContent className="sm:max-w-lg">
            <DialogHeader>
              <DialogTitle>Request a Calculator</DialogTitle>
              <DialogDescription>
                Submit a request for a new clinical calculator. Our content team will review it.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-2">
              <div className="space-y-2">
                <Label htmlFor="req-name">
                  Calculator name <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="req-name"
                  placeholder="e.g. CHA₂DS₂-VASc Score"
                  value={requestForm.name}
                  onChange={(e) => setRequestForm((f) => ({ ...f, name: e.target.value }))}
                  disabled={requestSubmitting}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="req-category">Category</Label>
                <Input
                  id="req-category"
                  placeholder="e.g. Cardiology, Renal, Obstetrics"
                  value={requestForm.category}
                  onChange={(e) => setRequestForm((f) => ({ ...f, category: e.target.value }))}
                  disabled={requestSubmitting}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="req-description">
                  Description <span className="text-destructive">*</span>
                </Label>
                <Textarea
                  id="req-description"
                  placeholder="What does this calculator do? What inputs and outputs does it need?"
                  rows={3}
                  value={requestForm.description}
                  onChange={(e) => setRequestForm((f) => ({ ...f, description: e.target.value }))}
                  disabled={requestSubmitting}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="req-justification">Clinical justification</Label>
                <Textarea
                  id="req-justification"
                  placeholder="Why is this needed? Link to the source or guideline if available."
                  rows={3}
                  value={requestForm.justification}
                  onChange={(e) => setRequestForm((f) => ({ ...f, justification: e.target.value }))}
                  disabled={requestSubmitting}
                />
              </div>
            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => setRequestOpen(false)}
                disabled={requestSubmitting}
              >
                Cancel
              </Button>
              <Button onClick={handleSubmitRequest} disabled={requestSubmitting}>
                {requestSubmitting ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Submitting...
                  </>
                ) : (
                  "Submit Request"
                )}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Results */}
        <Card>
          <CardHeader>
            <CardTitle>Results</CardTitle>
            <CardDescription>Calculation results and interpretation</CardDescription>
          </CardHeader>
          <CardContent>
            {currentResult ? (
              <div className="space-y-4">
                <div>
                  <div className="text-3xl font-bold">{currentResult.value}</div>
                  {currentResult.description && (
                    <div className="text-sm text-muted-foreground">
                      {currentResult.description}
                    </div>
                  )}
                  {currentResult.category && (
                    <Badge variant="outline" className="mt-2">
                      {currentResult.category}
                    </Badge>
                  )}
                </div>
              </div>
            ) : (
              <div className="text-center text-muted-foreground py-8">
                <Calculator className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p>Enter values and click Calculate to see results</p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
