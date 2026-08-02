const referenceCollections = new Set([
  "regions",
  "health_sub_regions",
  "districts",
  "health_sub_districts",
  "counties",
  "subcounties",
  "parishes",
  "facility_levels",
  "ownership_types",
  "authorities",
  "languages",
  "drug_categories",
  "drug_classes",
  "drug_tags",
  "therapeutic_categories",
  "guideline_categories",
  "guideline_tags",
  "faq_tags",
])

const privateCollections = new Set([
  "users",
  "notifications",
  "support_tickets",
  "support_ticket_replies",
  "conversations",
  "messages",
  "reading_progress",
])

export function staleTimeForDomain(domain: string) {
  if (privateCollections.has(domain)) return 0
  if (referenceCollections.has(domain)) return 10 * 60 * 1000
  if (domain.includes("analytics") || domain.includes("overview")) {
    return 30 * 1000
  }
  return 60 * 1000
}
