import { RowAction, BulkAction } from "@/types/data-table"
import { DrugWithRelations } from "./columns"
import {
  DrugsReviewStatusOptions,
  DrugsStatusOptions,
} from "@/types/backend-types"
import {
  Eye,
  Edit,
  Copy,
  Trash2,
  FileDown,
  CheckCircle,
  XCircle,
  Clock,
} from "lucide-react"
import { getBackendClient } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"
import { downloadCsv, downloadJson } from "@/lib/client-download"

const backend = getBackendClient()

function getExportFilename(prefix: string) {
  return `${prefix}-${new Date().toISOString().slice(0, 10)}`
}

function mapDrugForCsv(drug: DrugWithRelations) {
  return {
    name: drug.name,
    brand_names: drug.brand_names || "",
    status: drug.status,
    review_status: drug.review_status,
    drug_class: drug.expand?.drug_class?.name || "",
    therapeutic_category: drug.expand?.therapeutic_category?.name || "",
    categories: drug.expand?.categories?.map((category) => category.name).join(", ") || "",
    tags: drug.expand?.tags?.map((tag) => tag.name).join(", ") || "",
    created: drug.created,
    updated: drug.updated,
  }
}

async function updateDrug(id: string, data: Partial<DrugWithRelations>) {
  await backend.resource("drugs").update(id, data)
}

async function updateManyDrugs(
  drugs: DrugWithRelations[],
  data: Partial<DrugWithRelations>,
  actionLabel: string
) {
  const results = await Promise.allSettled(
    drugs.map((drug) => updateDrug(drug.id, data))
  )

  const successCount = results.filter((result) => result.status === "fulfilled").length
  const errorCount = results.length - successCount

  if (successCount > 0) {
    showToast.success(
      `${actionLabel} Complete`,
      errorCount > 0
        ? `${successCount} updated, ${errorCount} failed`
        : `${successCount} drugs updated`
    )
  }

  if (errorCount > 0) {
    showToast.error("Some Updates Failed", `${errorCount} drugs could not be updated`)
  }
}

async function deleteDrug(drug: DrugWithRelations) {
  await backend.resource("drugs").delete(drug.id)
  showToast.success("Drug Deleted", `"${drug.name}" was deleted`)
}

async function deleteManyDrugs(drugs: DrugWithRelations[]) {
  const results = await Promise.allSettled(
    drugs.map((drug) => backend.resource("drugs").delete(drug.id))
  )

  const successCount = results.filter((result) => result.status === "fulfilled").length
  const errorCount = results.length - successCount

  if (successCount > 0) {
    showToast.success(
      "Bulk Delete Complete",
      errorCount > 0
        ? `${successCount} deleted, ${errorCount} failed`
        : `${successCount} drugs deleted`
    )
  }

  if (errorCount > 0) {
    showToast.error("Some Deletes Failed", `${errorCount} drugs could not be deleted`)
  }
}

/**
 * Row actions for individual drug records
 * Factory pattern for dependency injection
 */
export const createDrugRowActions = (
  navigate: (path: string) => void
): RowAction<DrugWithRelations>[] => [
  {
    id: "view",
    label: "View Details",
    icon: Eye,
    onClick: async (drug) => {
      navigate(`/drugs/${drug.id}`)
    },
  },
  {
    id: "edit",
    label: "Edit Drug",
    icon: Edit,
    onClick: async (drug) => {
      navigate(`/drugs/${drug.id}/edit`)
    },
  },
  {
    id: "duplicate",
    label: "Duplicate Drug",
    icon: Copy,
    onClick: async (drug) => {
      navigate(`/drugs/create?duplicate=${drug.id}`)
    },
    separator: true,
  },
  {
    id: "export",
    label: "Export Drug Data",
    icon: FileDown,
    onClick: async (drug) => {
      downloadJson(drug, `${getExportFilename(`drug-${drug.id}`)}.json`)
      showToast.success("Export Complete", `"${drug.name}" was exported`)
    },
    separator: true,
  },
  {
    id: "delete",
    label: "Delete Drug",
    icon: Trash2,
    variant: "destructive",
    onClick: async (drug) => {
      await deleteDrug(drug)
    },
    disabled: (drug) =>
      drug.status === DrugsStatusOptions.active &&
      drug.review_status === DrugsReviewStatusOptions.approved,
    confirmMessage:
      "Are you sure you want to delete this drug? This action cannot be undone and will remove all associated data.",
    separator: true,
  },
]

/**
 * Bulk actions for multiple selected drug records
 */
export const drugBulkActions: BulkAction<DrugWithRelations>[] = [
  {
    id: "bulk-activate",
    label: "Activate Drugs",
    icon: CheckCircle,
    onClick: async (drugs) => {
      await updateManyDrugs(
        drugs,
        { status: DrugsStatusOptions.active },
        "Activation"
      )
    },
    disabled: (drugs) => drugs.every((drug) => drug.status === DrugsStatusOptions.active),
    description: "Change status to active for selected drugs",
  },
  {
    id: "bulk-deactivate",
    label: "Deactivate Drugs",
    icon: XCircle,
    variant: "outline",
    onClick: async (drugs) => {
      await updateManyDrugs(
        drugs,
        { status: DrugsStatusOptions.inactive },
        "Deactivation"
      )
    },
    disabled: (drugs) => drugs.every((drug) => drug.status === DrugsStatusOptions.inactive),
    description: "Change status to inactive for selected drugs",
  },
  {
    id: "bulk-review-pending",
    label: "Set Review Pending",
    icon: Clock,
    variant: "outline",
    onClick: async (drugs) => {
      await updateManyDrugs(
        drugs,
        { review_status: DrugsReviewStatusOptions.pending },
        "Review Status Update"
      )
    },
    disabled: (drugs) =>
      drugs.every((drug) => drug.review_status === DrugsReviewStatusOptions.pending),
    description: "Set review status to pending for selected drugs",
    separator: true,
  },
  {
    id: "bulk-export",
    label: "Export Selected",
    icon: FileDown,
    variant: "outline",
    onClick: async (drugs) => {
      downloadCsv(
        drugs.map(mapDrugForCsv),
        [
          { key: "name", label: "Drug Name" },
          { key: "brand_names", label: "Brand Names" },
          { key: "status", label: "Status" },
          { key: "review_status", label: "Review Status" },
          { key: "drug_class", label: "Drug Class" },
          { key: "therapeutic_category", label: "Therapeutic Category" },
          { key: "categories", label: "Categories" },
          { key: "tags", label: "Tags" },
          { key: "created", label: "Created" },
          { key: "updated", label: "Updated" },
        ],
        `${getExportFilename("drugs-export")}.csv`
      )
      showToast.success("Export Complete", `Exported ${drugs.length} drugs`)
    },
    description: "Export selected drugs to CSV/Excel",
    separator: true,
  },
  {
    id: "bulk-delete",
    label: "Delete Selected",
    icon: Trash2,
    variant: "destructive",
    onClick: async (drugs) => {
      await deleteManyDrugs(drugs)
    },
    disabled: (drugs) =>
      drugs.some(
        (drug) =>
          drug.status === DrugsStatusOptions.active &&
          drug.review_status === DrugsReviewStatusOptions.approved
      ),
    description: "Permanently delete selected drugs",
    confirmMessage:
      "Are you sure you want to delete the selected drugs? This action cannot be undone.",
    separator: true,
  },
]
