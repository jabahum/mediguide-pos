export const diseaseHubFeatureFlagDefaults = {
  disease_taxonomy_enabled: false,
  disease_content_assignment: false,
  disease_hubs_enabled: false,
  generic_hubs_enabled: false,
  api_driven_outbreak_pillars: false,
  guideline_category_assignment: false,
  unified_document_search: false,
  pillar_rag_metadata: false,
} as const

export function addMissingDiseaseHubFeatureFlags(template: Record<string, unknown>) {
  const parameters = isRecord(template.parameters) ? { ...template.parameters } : {}
  for (const [name, enabled] of Object.entries(diseaseHubFeatureFlagDefaults)) {
    if (parameters[name] !== undefined) continue
    parameters[name] = {
      defaultValue: { value: String(enabled) },
      valueType: "BOOLEAN",
      description: "MediGuide disease-aware content rollout flag",
    }
  }
  return { ...template, parameters }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}
