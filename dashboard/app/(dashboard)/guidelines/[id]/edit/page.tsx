"use client";

import * as React from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useParams, useRouter } from "next/navigation";

import { LoadingState } from "@/components/ui/loading-state";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/ui/page-header";
import { usePermissionContext } from "@/lib/permission-context";
import { showToast } from "@/lib/toast";
import {
  GuidelineDocumentInput,
  GuidelineDocumentsService,
  guidelineDocumentsQueryKey,
} from "@/services/guideline-documents.service";
import { GuidelineDocumentForm } from "../../components/guideline-document-form";
import { contentDiseaseService } from "@/services/content-hubs.service";

export default function EditGuidelinePage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const queryClient = useQueryClient();
  const { hasPermission, loading: permissionsLoading } = usePermissionContext();
  const [submitting, setSubmitting] = React.useState(false);
  const documentQuery = useQuery({
    queryKey: [...guidelineDocumentsQueryKey, id],
    queryFn: () => GuidelineDocumentsService.getDocument(id),
    enabled: Boolean(id),
  });
  const classificationQuery = useQuery({
    queryKey: ["content-disease-assignments", "guideline", id],
    queryFn: () => contentDiseaseService.list("guideline", id),
    enabled: Boolean(id),
  });

  React.useEffect(() => {
    if (!permissionsLoading && !hasPermission("content", "update:any")) {
      router.replace(`/guidelines/${id}`);
    }
  }, [hasPermission, id, permissionsLoading, router]);

  async function submit(payload: GuidelineDocumentInput) {
    setSubmitting(true);
    try {
      const {
        disease_ids = [],
        primary_disease_id,
        ...documentPayload
      } = payload;
      await GuidelineDocumentsService.updateDocument(id, documentPayload);
      await contentDiseaseService.replace(
        "guideline",
        id,
        disease_ids,
        primary_disease_id,
      );
      await queryClient.invalidateQueries({
        queryKey: guidelineDocumentsQueryKey,
      });
      showToast.success(
        "Guideline updated",
        "Document metadata has been saved.",
      );
      router.push(`/guidelines/${id}`);
    } catch (error) {
      showToast.error(
        "Update failed",
        error instanceof Error ? error.message : "Unknown error",
      );
    } finally {
      setSubmitting(false);
    }
  }

  if (documentQuery.isLoading || classificationQuery.isLoading)
    return <LoadingState message="Loading guideline..." />;
  if (classificationQuery.isError) {
    return (
      <div className="space-y-3 rounded-md border border-destructive/40 p-6">
        <p className="font-medium">Disease assignments could not be loaded.</p>
        <p className="text-sm text-muted-foreground">
          Editing is paused to prevent existing classifications from being
          removed accidentally.
        </p>
        <Button
          variant="outline"
          onClick={() => void classificationQuery.refetch()}
        >
          Try again
        </Button>
      </div>
    );
  }
  if (!documentQuery.data) {
    return (
      <div className="p-6 text-destructive">
        Guideline document could not be loaded.
      </div>
    );
  }

  const document = documentQuery.data;
  const assignments = classificationQuery.data?.items || [];
  return (
    <div className="space-y-6">
      <PageHeader
        title={`Edit ${document.title}`}
        description="Update v2 guideline document metadata."
      />
      <GuidelineDocumentForm
        initialValue={{
          title: document.title,
          country: document.country,
          source_org: document.source_org,
          program_area: document.program_area,
          language: document.language,
          description: document.description,
          category_ids: document.categories.map((category) => category.id),
          disease_ids: assignments.map((assignment) => assignment.disease_id),
          primary_disease_id:
            assignments.find((assignment) => assignment.is_primary)
              ?.disease_id || "",
        }}
        submitting={submitting}
        submitLabel="Save Changes"
        onCancel={() => router.push(`/guidelines/${id}`)}
        onSubmit={submit}
      />
    </div>
  );
}
