"use client"

// Kept as a dedicated import boundary so situation-report consumers do not
// depend on the outbreak editor's service surface.
export {
  situationReportsService,
  type SituationReportInput,
  type SituationReportRecord,
  type OutbreakAuditRecord,
  type OutbreakListQuery as SituationReportListQuery,
} from "./outbreaks.service"
