import { backendClient } from "@/lib/backend-client"
import type { ClinicaltoolsDefinition, ClinicaltoolsExpression, ServicesCalculatorVersionDTO } from "@/types/generated/backend-openapi"

export type ClinicalToolExpression = Omit<ClinicaltoolsExpression, "op" | "args" | "value"> & {
  op: string
  value?: unknown
  field?: string
  args?: ClinicalToolExpression[]
  precision?: number
  rounding_mode?: string
  from_unit?: string
  to_unit?: string
  date_unit?: string
}

export type ClinicalToolDefinition = Omit<ClinicaltoolsDefinition, "schema_version" | "tool_type" | "title" | "version" | "locale" | "warnings" | "citations" | "inputs" | "sections" | "calculation" | "rules" | "outputs" | "interpretations" | "completion" | "test_cases"> & {
  schema_version: "1.0"
  tool_type: "calculator" | "decision_tool" | "checklist"
  title: string
  description?: string
  version: string
  locale: string
  clinical_owner?: string
  clinical_reviewer?: string
  warnings?: Array<{ key: string; text: string; severity: string; when?: ClinicalToolExpression }>
  citations?: Array<{ key: string; title: string; organization?: string; url?: string }>
  inputs: Array<{ key: string; type: string; label: string; required: boolean; minimum?: number; maximum?: number; default_unit?: string; allowed_units?: string[]; options?: Array<{ value: unknown; label: string }> }>
  sections: Array<{ key: string; title: string; order: number }>
  calculation: Array<{ key: string; expression: ClinicalToolExpression; precision?: number; unit?: string }>
  rules: Array<{ key: string; when: ClinicalToolExpression; actions: Array<{ type: string; target?: string; value?: ClinicalToolExpression; message_key?: string }>; order: number; stop?: boolean }>
  outputs: Array<{ key: string; label: string; value: ClinicalToolExpression; unit?: string; precision?: number }>
  interpretations: Array<{ key: string; when: ClinicalToolExpression; label: string; description?: string; severity: string; recommendations: string[]; order: number }>
  completion: { mode: string; allow_resume?: boolean; require_review?: boolean; show_percentage?: boolean; reset_confirmation: boolean }
  test_cases: Array<{ key: string; inputs: Record<string, unknown>; expected: Record<string, unknown>; numeric_tolerance?: number }>
  minimum_app_version?: string
}

export type ClinicalToolVersion = Omit<ServicesCalculatorVersionDTO, "id" | "calculator_id" | "semantic_version" | "schema_version" | "definition" | "definition_checksum" | "status" | "change_summary" | "validation_passed" | "tests_passed" | "lock_version" | "created_at" | "updated_at"> & {
  id: string; calculator_id: string; semantic_version: string; schema_version: string
  definition: ClinicalToolDefinition; definition_checksum: string; status: string
  change_summary: string; validation_passed: boolean; tests_passed: boolean
  lock_version: number; created_at: string; updated_at: string
}

export type ValidationIssue = { path: string; code: string; message: string }
export type TestReport = { passed: boolean; cases: Array<{ key: string; passed: boolean; failures?: string[] }> }

const json = (value: unknown) => JSON.stringify(value)
export const clinicalToolService = {
  definition: (toolId: string) => backendClient.send<{ calculator_id: string; version_id: string; definition_checksum: string; definition: ClinicalToolDefinition }>(`/api/v2/calculators/${toolId}/definition`),
  versions: (toolId: string) => backendClient.send<ClinicalToolVersion[]>(`/api/v2/calculators/${toolId}/versions`),
  version: (id: string) => backendClient.send<ClinicalToolVersion>(`/api/v2/calculator-versions/${id}`),
  create: (toolId: string, definition: ClinicalToolDefinition, changeSummary: string) => backendClient.send<ClinicalToolVersion>(`/api/v2/calculators/${toolId}/versions`, { method: "POST", body: json({ definition, change_summary: changeSummary }) }),
  update: (id: string, definition: ClinicalToolDefinition, changeSummary: string, lockVersion: number) => backendClient.send<ClinicalToolVersion>(`/api/v2/calculator-versions/${id}`, { method: "PATCH", body: json({ definition, change_summary: changeSummary, lock_version: lockVersion }) }),
  duplicate: (id: string, semanticVersion: string, changeSummary: string) => backendClient.send<ClinicalToolVersion>(`/api/v2/calculator-versions/${id}/duplicate`, { method: "POST", body: json({ semantic_version: semanticVersion, change_summary: changeSummary }) }),
  validate: (id: string, lockVersion: number) => backendClient.send<{ valid: boolean; errors: ValidationIssue[]; lock_version: number }>(`/api/v2/calculator-versions/${id}/validate`, { method: "POST", body: json({ lock_version: lockVersion }) }),
  test: (id: string, lockVersion: number) => backendClient.send<{ report: TestReport; lock_version: number }>(`/api/v2/calculator-versions/${id}/test`, { method: "POST", body: json({ lock_version: lockVersion }) }),
  transition: (id: string, action: "submit" | "approve" | "publish" | "withdraw", lockVersion: number) => backendClient.send<ClinicalToolVersion>(`/api/v2/calculator-versions/${id}/${action}`, { method: "POST", body: json({ lock_version: lockVersion }) }),
  rollbackToLegacy: (toolId: string) => backendClient.send<void>(`/api/v2/calculators/${toolId}/runtime/legacy`, { method: "POST" }),
  audit: (id: string) => backendClient.send<Array<{ id: string; action: string; created_at: string; actor_id?: string; metadata?: { comment?: string } }>>(`/api/v2/calculator-versions/${id}/audit`),
  reviewComment: (id: string, comment: string) => backendClient.send<void>(`/api/v2/calculator-versions/${id}/review-comments`, { method: "POST", body: json({ comment }) }),
}
