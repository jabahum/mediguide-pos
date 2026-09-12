# Disease-aware content classification: phases 3 and 4

## What changed

Phase 3 connects modern `guideline_documents` to the existing hierarchical
`guideline_categories` taxonomy through `guideline_document_categories`.
Assignments are many-to-many. A document can remain uncategorized. The legacy
`program_area` value remains intact and can still be used by older clients.

The dashboard create/edit form supports multiple active categories. Admin and
public guideline responses return categories, and both catalogues accept an
exact `category_id` filter. Mobile guest category tiles use the canonical
category ID and open an already-filtered guideline catalogue. Program-area
navigation remains as a compatibility fallback for cached older responses.

Phase 4 adds `content_disease_assignments`, the canonical association between a
disease and these initial resource types:

- `guideline`
- `outbreak`
- `outbreak_document`
- `situation_report`
- `algorithm`
- `clinical_tool`
- `form`
- `drug_reference`

One resource may have several diseases but at most one primary disease. The
service rejects duplicate assignments, unknown resource types, nonexistent or
wrongly typed resources, and new assignments to inactive/archived diseases.
Deleting an assignment only soft-deletes that association.

## API usage

Protected classification endpoints require guideline read/write permission:

```http
GET /api/v2/content-disease-assignments?disease_id={uuid}&content_type=guideline
POST /api/v2/content-disease-assignments
DELETE /api/v2/content-disease-assignments/{assignmentId}
```

Example body:

```json
{
  "disease_id": "00000000-0000-0000-0000-000000000000",
  "content_type": "guideline",
  "content_id": "00000000-0000-0000-0000-000000000000",
  "primary": true
}
```

Public guideline catalogue and public global search support:

```http
GET /api/public/guidelines?category_id={uuid}&disease_id={uuid}
GET /api/public/search?q=malaria&category_id={uuid}&disease_id={uuid}
```

## Visibility and safety

Classification is not publication. Public queries retain their existing
publication checks and additionally require active category/disease records.
The centralized `ContentDiseaseService.PubliclyEligible` boundary checks each
resource type before any future disease hub exposes it. It rejects draft,
unreviewed, expired, withdrawn, superseded/non-current, or unpublished content
as applicable.

The existing outbreak `disease_type` string is not changed. Migration 49 only
backfills outbreak assignments where the phase-2 migration report resolved the
text to exactly one active disease. Existing inactive disease/category
assignments remain readable to administrators, but cannot be newly assigned and
are not returned as active public filters.

## Deployment and rollback

Run normal Goose migrations before deploying the API. Migration 49 creates the
two join tables and their indexes. Its down migration drops only these new
associations; it never modifies `program_area`, `outbreaks.disease_type`, source
documents, or disease/category records.

After deployment:

1. Verify `/api/v2/guidelines/{id}` returns `categories`.
2. Assign several categories and confirm category-filtered public results.
3. Review the disease migration report before assigning unresolved outbreaks.
4. Confirm a disease assignment to draft content does not appear publicly.
5. Rebuild mobile cached catalogue data so canonical category tiles replace the
   program-area fallback.
