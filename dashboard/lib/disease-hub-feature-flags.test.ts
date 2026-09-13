import { describe, expect, it } from "vitest"
import { addMissingDiseaseHubFeatureFlags, diseaseHubFeatureFlagDefaults } from "./disease-hub-feature-flags"

describe("addMissingDiseaseHubFeatureFlags", () => {
  it("adds every rollout flag as disabled without changing existing parameters", () => {
    const result = addMissingDiseaseHubFeatureFlags({
      parameters: { disease_hubs_enabled: { defaultValue: { value: "true" } }, existing: { defaultValue: { value: "x" } } },
    })
    expect(Object.keys(result.parameters)).toEqual(expect.arrayContaining(Object.keys(diseaseHubFeatureFlagDefaults)))
    expect(result.parameters.disease_hubs_enabled).toEqual({ defaultValue: { value: "true" } })
    expect(result.parameters.existing).toEqual({ defaultValue: { value: "x" } })
  })
})
