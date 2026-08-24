import { describe, expect, it } from "vitest";
import { buildMarkdownSearchIndex, searchMarkdown } from "./search";

describe("guideline markdown search", () => {
  const index = buildMarkdownSearchIndex("# Guide\n\n## Malaria treatment\nUse ACT for uncomplicated malaria.\n\n### Severe disease\nRefer urgently and give artesunate.");

  it("indexes handbook headings with their section text", () => {
    expect(index.map((item) => item.id)).toEqual(["malaria-treatment", "severe-disease"]);
    expect(index[0].text).toContain("uncomplicated malaria");
  });

  it("searches both headings and clinical content", () => {
    expect(searchMarkdown(index, "artesunate")[0].title).toBe("Severe disease");
    expect(searchMarkdown(index, "malaria treatment")[0].id).toBe("malaria-treatment");
  });

  it("keeps a headingless published document searchable", () => {
    const headingless = buildMarkdownSearchIndex("Give oral rehydration solution and reassess the patient.");
    expect(searchMarkdown(headingless, "rehydration")[0].id).toBe("guideline-document");
  });
});
