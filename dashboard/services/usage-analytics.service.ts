import { backendClient } from "@/lib/backend-client"

export interface UsageAggregate {
  event_type: "guideline" | "abbreviation" | "consultant" | "ai"
  count: number
}

export const usageAnalyticsService = {
  list(since?: string) {
    return backendClient.send<UsageAggregate[]>("/api/v2/analytics/usage", {
      query: { since },
    })
  },
}
