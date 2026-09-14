import { describe, expect, it } from "vitest"
import { addMissingDiseaseHubFeatureFlags, diseaseHubFeatureFlagDefaults } from "./disease-hub-feature-flags"

describe("addMissingDiseaseHubFeatureFlags", () => {
  it("adds rollout defaults without changing existing parameters", () => {
    const result = addMissingDiseaseHubFeatureFlags({
      parameters: { disease_hubs_enabled: { defaultValue: { value: "true" } }, existing: { defaultValue: { value: "x" } } },
    })
    expect(Object.keys(result.parameters)).toEqual(expect.arrayContaining(Object.keys(diseaseHubFeatureFlagDefaults)))
    expect(result.parameters.disease_hubs_enabled).toEqual({ defaultValue: { value: "true" } })
    expect(result.parameters.existing).toEqual({ defaultValue: { value: "x" } })
    expect(result.parameters.disease_taxonomy_enabled).toEqual({
      defaultValue: { value: "true" },
      valueType: "BOOLEAN",
      description: "MediGuide disease-aware content rollout flag",
    })
    expect(result.parameters.generic_hubs_enabled).toEqual({
      defaultValue: { value: "true" },
      valueType: "BOOLEAN",
      description: "MediGuide disease-aware content rollout flag",
    })
  })
})
