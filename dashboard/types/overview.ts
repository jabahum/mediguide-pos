import type { IsoDateString, RecordIdString } from "@/types/backend-types"

export type OverviewSeriesPoint = {
  day: IsoDateString
  total: number
}

export type OverviewData = {
  success: boolean
  cached_at: IsoDateString
  metrics: {
    totalUsers: number
    activeUsers: number
    healthcareProviders: number
    totalDrugs: number
    activeDrugs: number
    totalFacilities: number
    totalConsultants: number
    activeConsultants: number
  }
  pipeline: {
    usersPendingActivation: number
    drugsUnderReview: number
    drugsPendingReview: number
    drugsInactive: number
    consultantsPendingApproval: number
    consultantsVerified: number
  }
  engagement: {
    aiUsage7d: number
    aiUsage30d: number
    calculatorUsage7d: number
    calculatorUsage30d: number
    guidelineUsage7d: number
    guidelineUsage30d: number
    drugUsage7d: number
    drugUsage30d: number
    facilityUsage7d: number
    facilityUsage30d: number
  }
  contentHealth: {
    medicalGuidelinesTotal: number
    medicalGuidelinesPublished: number
    medicalGuidelinesDraft: number
    faqsTotal: number
    faqsPublished: number
    faqsDraft: number
    documentationTotal: number
    documentationPublished: number
    genericPagesTotal: number
    abbreviationsTotal: number
    calculatorsTotal: number
    calculatorsActive: number
    guidelineCategoriesActive: number
  }
  support: {
    ticketsOpen: number
    ticketsInProgress: number
    ticketsResolved: number
    ticketsClosed: number
    ticketsUrgent: number
    notifications7d: number
    notifications30d: number
  }
  taxonomy: {
    activeDrugCategories: number
    activeDrugClasses: number
    activeTherapeuticCategories: number
    activeDrugTags: number
  }
  coverage: {
    regions: number
    districts: number
    subcounties: number
    parishes: number
  }
  series: {
    usersByDay: OverviewSeriesPoint[]
    drugsByDay: OverviewSeriesPoint[]
    facilitiesByDay: OverviewSeriesPoint[]
  }
}
