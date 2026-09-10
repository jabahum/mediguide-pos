"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import Image from "next/image";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import {
  AlertTriangle,
  ArrowDown,
  ArrowLeft,
  ArrowUp,
  Check,
  ExternalLink,
  FileText,
  GitMerge,
  Monitor,
  Save,
  Scissors,
  Send,
  Smartphone,
  Trash2,
  X,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { LoadingState } from "@/components/ui/loading-state";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { showToast } from "@/lib/toast";
import { GuidelineBulkReviewPanel } from "@/components/guidelines/guideline-bulk-review-panel";
import { GuidelineCompletenessReport } from "@/components/guidelines/guideline-completeness-report";
import {
  guidelineDocumentsQueryKey,
  GuidelineBlockType,
  GuidelineAssetRecord,
  GuidelineContentBlockRecord,
  GuidelineDocumentsService,
  GuidelineSectionRecord,
} from "@/services/guideline-documents.service";

const blockTypes: GuidelineBlockType[] = [
  "heading",
  "paragraph",
  "ordered_list",
  "unordered_list",
  "table",
  "figure",
  "recommendation",
  "warning",
  "caution",
  "key_point",
  "contraindication",
  "dosage",
  "evidence",
  "definition",
  "procedure",
  "clinical_note",
  "referral_criteria",
  "algorithm_reference",
  "algorithm",
  "reference",
  "page_break",
  "unknown",
];

type BlockReviewFilter = "high-risk" | "pending-high-risk" | "all";

function blockText(block: GuidelineContentBlockRecord) {
  const content = block.content;
  if (typeof content.text === "string") return content.text;
  if (typeof content.content === "string") return content.content;
  if (typeof content.citation === "string") return content.citation;
  if (Array.isArray(content.items))
    return content.items
      .filter((item): item is string => typeof item === "string")
      .join("\n");
  if (typeof content.title === "string") return content.title;
  if (typeof content.caption === "string") return content.caption;
  if (typeof content.alternative_text === "string")
    return content.alternative_text;
  return "";
}

function BlockPreview({
  block,
  asset,
}: {
  block: GuidelineContentBlockRecord;
  asset?: GuidelineAssetRecord;
}) {
  const content = block.content;
  const text = blockText(block);
  if (block.type === "heading") {
    const level = Math.min(6, Math.max(1, Number(content.level) || 2));
    const Heading = `h${level}` as keyof React.JSX.IntrinsicElements;
    return <Heading className="font-semibold">{text}</Heading>;
  }
  if (block.type === "ordered_list" || block.type === "unordered_list") {
    const List = block.type === "ordered_list" ? "ol" : "ul";
    return (
      <List className="ml-5 list-outside list-disc space-y-1">
        {((content.items as unknown[]) || []).map((item, index) => (
          <li key={index}>{String(item)}</li>
        ))}
      </List>
    );
  }
  if (block.type === "table") {
    const columns = Array.isArray(content.columns) ? content.columns : [];
    const rows = Array.isArray(content.rows) ? content.rows : [];
    return (
      <div className="min-w-0 overflow-hidden rounded-md border">
        <table className="w-full table-fixed border-collapse text-xs">
          <caption className="border-b bg-muted/50 p-2 text-left font-semibold">
            {text || "Clinical table"}
          </caption>
          <thead>
            <tr>
              {columns.map((column, index) => (
                <th
                  className="break-words border-b border-r bg-muted p-2 text-left align-top [overflow-wrap:anywhere] last:border-r-0"
                  key={index}
                >
                  {String(column)}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, rowIndex) => (
              <tr key={rowIndex}>
                {(Array.isArray(row) ? row : []).map((cell, cellIndex) => (
                  <td
                    className="break-words border-b border-r p-2 align-top [overflow-wrap:anywhere] last:border-r-0"
                    key={cellIndex}
                  >
                    {String(cell)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }
  if (["recommendation", "warning", "key_point"].includes(block.type)) {
    return (
      <div
        className={
          block.type === "warning"
            ? "rounded-md border border-amber-300 bg-amber-50 p-3 text-amber-950"
            : "rounded-md border border-blue-200 bg-blue-50 p-3 text-blue-950"
        }
      >
        <div className="text-xs font-semibold uppercase">
          {String(content.title || block.type.replace("_", " "))}
        </div>
        <p className="mt-1 whitespace-pre-wrap text-sm">{text}</p>
      </div>
    );
  }
  if (block.type === "figure")
    return <FigureBlockPreview block={block} asset={asset} />;
  if (block.type === "algorithm")
    return (
      <div className="rounded-md border border-dashed p-6 text-center text-sm">
        Reviewed structured algorithm ·{" "}
        {Array.isArray(content.nodes) ? content.nodes.length : 0} nodes
      </div>
    );
  if (block.type === "page_break")
    return (
      <div className="border-t border-dashed pt-2 text-xs text-muted-foreground">
        Page {String(content.page || "")}
      </div>
    );
  return (
    <p className="whitespace-pre-wrap text-sm leading-6">
      {text || JSON.stringify(content)}
    </p>
  );
}

function FigureBlockPreview({
  block,
  asset,
}: {
  block: GuidelineContentBlockRecord;
  asset?: GuidelineAssetRecord;
}) {
  const assetId =
    typeof block.content.asset_id === "string" ? block.content.asset_id : "";
  const [url, setUrl] = React.useState<string | null>(null);
  React.useEffect(() => {
    if (!assetId) return;
    let active = true;
    GuidelineDocumentsService.getReviewAsset(block.version_id, assetId)
      .then((blob) => {
        if (!active) return;
        setUrl(URL.createObjectURL(blob));
      })
      .catch(() => setUrl(null));
    return () => {
      active = false;
    };
  }, [assetId, block.version_id]);
  React.useEffect(
    () => () => {
      if (url) URL.revokeObjectURL(url);
    },
    [url],
  );
  const caption =
    (typeof block.content.caption === "string" ? block.content.caption : "") ||
    asset?.caption ||
    "";
  const alternativeText =
    (typeof block.content.alternative_text === "string"
      ? block.content.alternative_text
      : "") ||
    asset?.alternative_text ||
    caption;
  const source =
    (typeof block.content.source === "string" ? block.content.source : "") ||
    asset?.source ||
    "";
  const attribution =
    (typeof block.content.attribution === "string"
      ? block.content.attribution
      : "") ||
    asset?.attribution ||
    "";
  const license =
    (typeof block.content.license === "string" ? block.content.license : "") ||
    asset?.license ||
    "";
  return (
    <figure className="space-y-2 rounded-md border p-2">
      {url ? (
        <Image
          unoptimized
          width={800}
          height={600}
          src={url}
          alt={
            alternativeText ||
            "Extracted guideline figure pending alternative text"
          }
          className="mx-auto h-auto max-h-96 w-auto max-w-full object-contain"
        />
      ) : (
        <div className="rounded-md border border-dashed p-6 text-center text-sm text-muted-foreground">
          Figure asset unavailable
        </div>
      )}
      <figcaption className="text-xs text-muted-foreground">
        {caption || "Caption required before review"}
      </figcaption>
      <dl className="grid gap-1 border-t pt-2 text-xs">
        <div>
          <dt className="inline font-medium">Alternative text: </dt>
          <dd className="inline">
            {alternativeText || "Missing — add it before approval"}
          </dd>
        </div>
        {source && (
          <div>
            <dt className="inline font-medium">Source: </dt>
            <dd className="inline">{source}</dd>
          </div>
        )}
        {attribution && (
          <div>
            <dt className="inline font-medium">Attribution: </dt>
            <dd className="inline">{attribution}</dd>
          </div>
        )}
        {license && (
          <div>
            <dt className="inline font-medium">License: </dt>
            <dd className="inline">{license}</dd>
          </div>
        )}
      </dl>
    </figure>
  );
}

export default function GuidelineReviewPage() {
  const { id, versionId } = useParams<{ id: string; versionId: string }>();
  const router = useRouter();
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();
  const pendingQueueInitialized = React.useRef(false);
  const [selectedSectionId, setSelectedSectionId] = React.useState<
    string | null
  >(null);
  const [selectedBlockId, setSelectedBlockId] = React.useState<string | null>(
    null,
  );
  const [pdfUrl, setPdfUrl] = React.useState<string | null>(null);
  const [pdfPage, setPdfPage] = React.useState(1);
  const [previewMode, setPreviewMode] = React.useState<"web" | "mobile">("web");
  const [blockReviewFilter, setBlockReviewFilter] =
    React.useState<BlockReviewFilter>(() =>
      searchParams.get("focus") === "pending-high-risk"
        ? "pending-high-risk"
        : "high-risk",
    );
  const [sectionDraft, setSectionDraft] = React.useState({
    title: "",
    slug: "",
    level: 1,
  });
  const [blockType, setBlockType] =
    React.useState<GuidelineBlockType>("paragraph");
  const [blockJSON, setBlockJSON] = React.useState("");

  const workspaceQuery = useQuery({
    queryKey: [...guidelineDocumentsQueryKey, versionId, "review"],
    queryFn: () => GuidelineDocumentsService.getReviewWorkspace(versionId),
    enabled: Boolean(versionId),
  });

  React.useEffect(() => {
    let active = true;
    GuidelineDocumentsService.getOriginalPdf(versionId)
      .then((blob) => {
        if (!active) return;
        const url = URL.createObjectURL(blob);
        setPdfUrl((previous) => {
          if (previous) URL.revokeObjectURL(previous);
          return url;
        });
      })
      .catch(() => setPdfUrl(null));
    return () => {
      active = false;
    };
  }, [versionId]);

  React.useEffect(
    () => () => {
      if (pdfUrl) URL.revokeObjectURL(pdfUrl);
    },
    [pdfUrl],
  );

  const workspace = workspaceQuery.data;
  const sections = React.useMemo(
    () => workspace?.sections || [],
    [workspace?.sections],
  );
  const blocks = React.useMemo(
    () => workspace?.blocks || [],
    [workspace?.blocks],
  );
  const individualReviewBlockTypes = React.useMemo(
    () =>
      new Set([
        ...(workspace?.block_review_policy?.high_risk_types || []),
        ...(workspace?.block_review_policy?.conditional_risk_types || []),
      ]),
    [
      workspace?.block_review_policy?.conditional_risk_types,
      workspace?.block_review_policy?.high_risk_types,
    ],
  );
  const pendingIndividualReviewBlocks = React.useMemo(
    () =>
      blocks.filter(
        (block) =>
          individualReviewBlockTypes.has(block.type) &&
          block.review_status !== "reviewed",
      ),
    [blocks, individualReviewBlockTypes],
  );
  const selectedSection =
    sections.find((section) => section.id === selectedSectionId) || sections[0];
  const sectionBlocks = blocks.filter(
    (block) => block.section_id === selectedSection?.id,
  );
  const visibleSectionBlocks = sectionBlocks.filter((block) => {
    if (blockReviewFilter === "all") return true;
    if (!individualReviewBlockTypes.has(block.type)) return false;
    return blockReviewFilter !== "pending-high-risk" || block.review_status !== "reviewed";
  });
  const selectedBlock =
    visibleSectionBlocks.find((block) => block.id === selectedBlockId) ||
    visibleSectionBlocks[0];

  React.useEffect(() => {
    if (!selectedSectionId && sections[0]) setSelectedSectionId(sections[0].id);
  }, [sections, selectedSectionId]);

  const selectBlock = React.useCallback(
    (block: GuidelineContentBlockRecord) => {
      if (block.section_id) setSelectedSectionId(block.section_id);
      setSelectedBlockId(block.id);
    },
    [],
  );

  React.useEffect(() => {
    if (
      searchParams.get("focus") !== "pending-high-risk" ||
      pendingQueueInitialized.current ||
      pendingIndividualReviewBlocks.length === 0
    )
      return;
    pendingQueueInitialized.current = true;
    selectBlock(pendingIndividualReviewBlocks[0]);
  }, [pendingIndividualReviewBlocks, searchParams, selectBlock]);

  React.useEffect(() => {
    if (!selectedSection) return;
    setSectionDraft({
      title: selectedSection.title,
      slug: selectedSection.slug,
      level: selectedSection.level,
    });
  }, [selectedSection]);

  React.useEffect(() => {
    if (!selectedBlock) return;
    setSelectedBlockId(selectedBlock.id);
    setBlockType(selectedBlock.type);
    setBlockJSON(JSON.stringify(selectedBlock.content, null, 2));
    setPdfPage(selectedBlock.page_start || selectedSection?.page_start || 1);
  }, [selectedBlock, selectedSection?.id, selectedSection?.page_start]);

  const refresh = React.useCallback(async () => {
    await Promise.all([
      queryClient.invalidateQueries({
        queryKey: [...guidelineDocumentsQueryKey, versionId, "review"],
      }),
      queryClient.invalidateQueries({
        queryKey: [...guidelineDocumentsQueryKey, id],
      }),
    ]);
  }, [id, queryClient, versionId]);

  const action = useMutation({
    mutationFn: async (operation: () => Promise<unknown>) => operation(),
    onSuccess: async () => {
      await refresh();
    },
    onError: (error) =>
      showToast.error(
        "Review action failed",
        error instanceof Error ? error.message : "Unknown error",
      ),
  });

  async function saveSection() {
    if (!selectedSection) return;
    await action.mutateAsync(() =>
      GuidelineDocumentsService.updateReviewSection(
        versionId,
        selectedSection.id,
        sectionDraft,
      ),
    );
    showToast.success("Section saved");
  }

  async function moveSection(direction: -1 | 1) {
    if (!selectedSection) return;
    const index = sections.findIndex(
      (section) => section.id === selectedSection.id,
    );
    const nextIndex = index + direction;
    if (nextIndex < 0 || nextIndex >= sections.length) return;
    const reordered = [...sections];
    [reordered[index], reordered[nextIndex]] = [
      reordered[nextIndex],
      reordered[index],
    ];
    await action.mutateAsync(() =>
      GuidelineDocumentsService.reorderReviewSections(
        versionId,
        reordered.map((section, sortOrder) => ({
          id: section.id,
          parent_id: section.parent_id,
          level: section.level,
          sort_order: sortOrder,
        })),
      ),
    );
  }

  async function saveBlock() {
    if (!selectedBlock) return;
    let content: Record<string, unknown>;
    try {
      content = JSON.parse(blockJSON) as Record<string, unknown>;
    } catch {
      showToast.error(
        "Invalid JSON",
        "Correct the block payload before saving.",
      );
      return;
    }
    await action.mutateAsync(() =>
      GuidelineDocumentsService.updateReviewBlock(versionId, selectedBlock.id, {
        type: blockType,
        content,
      }),
    );
    showToast.success(
      "Block correction saved",
      "The review decision was reset because the clinical content changed.",
    );
  }

  function changeBlockType(nextType: GuidelineBlockType) {
    setBlockType(nextType);
    let current: Record<string, unknown> = {};
    try {
      current = JSON.parse(blockJSON) as Record<string, unknown>;
    } catch {
      /* preserve an editable replacement */
    }
    const text = selectedBlock
      ? blockText({ ...selectedBlock, content: current })
      : "";
    let next: Record<string, unknown> = { ...current, type: nextType };
    if (["recommendation", "warning", "key_point"].includes(nextType)) {
      next = {
        type: nextType,
        title: String(current.title || nextType.replace("_", " ")),
        content: text,
        severity: String(current.severity || "standard"),
      };
    } else if (nextType === "paragraph" || nextType === "unknown") {
      next = { type: nextType, text };
    } else if (nextType === "heading") {
      next = { type: nextType, text, level: Number(current.level) || 2 };
    }
    setBlockJSON(JSON.stringify(next, null, 2));
  }

  async function decide(status: "reviewed" | "rejected") {
    if (!selectedBlock) return;
    const remainingBeforeDecision = pendingIndividualReviewBlocks.filter(
      (block) => block.id !== selectedBlock.id,
    );
    await action.mutateAsync(() =>
      GuidelineDocumentsService.reviewBlock(
        versionId,
        selectedBlock.id,
        status,
      ),
    );
    if (status === "reviewed") {
      showToast.success(
        selectedBlock.type === "figure" ? "Figure approved" : "Block approved",
        remainingBeforeDecision.length === 0
          ? "All blocks requiring individual review are approved. Return to the Markdown editor and refresh the regeneration review."
          : `${remainingBeforeDecision.length} block${remainingBeforeDecision.length === 1 ? "" : "s"} still require individual review.`,
      );
      if (remainingBeforeDecision[0]) selectBlock(remainingBeforeDecision[0]);
      return;
    }
    showToast.error(
      "Block rejected",
      "A rejected block remains unavailable to readers and may block publication. Correct it, compare it with the source again, and approve the corrected block.",
    );
  }

  async function removeBlock() {
    if (
      !selectedBlock ||
      !window.confirm(
        "Remove this extraction artifact? This action is audited.",
      )
    )
      return;
    await action.mutateAsync(() =>
      GuidelineDocumentsService.deleteReviewBlock(versionId, selectedBlock.id),
    );
    setSelectedBlockId(null);
  }

  async function splitSection() {
    if (!selectedSection || !selectedBlock) return;
    const title = window.prompt(
      "Title for the new section",
      `${selectedSection.title} — continued`,
    );
    if (!title?.trim()) return;
    await action.mutateAsync(() =>
      GuidelineDocumentsService.splitReviewSection(
        versionId,
        selectedSection.id,
        {
          block_id: selectedBlock.id,
          title: title.trim(),
          level: selectedSection.level,
        },
      ),
    );
  }

  async function mergeSection() {
    if (!selectedSection) return;
    const index = sections.findIndex(
      (section) => section.id === selectedSection.id,
    );
    const target = sections[index - 1];
    if (
      !target ||
      !window.confirm(
        `Merge “${selectedSection.title}” into “${target.title}”?`,
      )
    )
      return;
    await action.mutateAsync(() =>
      GuidelineDocumentsService.mergeReviewSection(
        versionId,
        selectedSection.id,
        target.id,
      ),
    );
    setSelectedSectionId(target.id);
  }

  async function publish() {
    const validation =
      await GuidelineDocumentsService.validatePublication(versionId);
    await refresh();
    if (!validation.valid) {
      showToast.error(
        "Publication blocked",
        `${validation.errors.length} validation issue(s) require attention.`,
      );
      return;
    }
    if (
      !window.confirm(
        "Publish this reviewed version? The action is permanent and audited.",
      )
    )
      return;
    await action.mutateAsync(() =>
      GuidelineDocumentsService.publishVersion(versionId),
    );
    showToast.success("Guideline published");
    router.push(`/guidelines/${id}`);
  }

  if (workspaceQuery.isLoading)
    return <LoadingState message="Loading editorial workspace..." />;
  if (workspaceQuery.isError || !workspace)
    return (
      <div className="p-6 text-destructive">
        {workspaceQuery.error instanceof Error
          ? workspaceQuery.error.message
          : "Review workspace unavailable."}
      </div>
    );

  const validationCount = workspace.validation.errors.length;
  const selectedPage =
    selectedBlock?.page_start || selectedSection?.page_start || pdfPage;
  const pdfSource = pdfUrl ? `${pdfUrl}#page=${selectedPage}` : null;

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => router.push(`/guidelines/${id}`)}
          >
            <ArrowLeft className="h-4 w-4" /> Back to guideline
          </Button>
          <h1 className="mt-2 text-2xl font-semibold">
            Editorial review · Version {workspace.version.version}
          </h1>
          <p className="text-sm text-muted-foreground">
            Compare every extracted block with its source before approving
            clinical content.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Badge
            variant={workspace.validation.valid ? "default" : "destructive"}
          >
            {workspace.validation.valid
              ? "Ready to publish"
              : `${validationCount} blockers`}
          </Badge>
          <Button
            variant="outline"
            onClick={() =>
              action.mutate(() =>
                GuidelineDocumentsService.validatePublication(versionId),
              )
            }
            disabled={action.isPending}
          >
            <Check className="h-4 w-4" /> Validate
          </Button>
          <Button
            onClick={publish}
            disabled={
              action.isPending || workspace.version.status === "published"
            }
          >
            <Send className="h-4 w-4" /> Publish
          </Button>
        </div>
      </div>

      {(searchParams.get("focus") === "pending-high-risk" ||
        pendingIndividualReviewBlocks.length > 0) && (
        <Card
          className={
            pendingIndividualReviewBlocks.length > 0
              ? "border-amber-300 bg-amber-50/40"
              : "border-emerald-300 bg-emerald-50/40"
          }
        >
          <CardContent className="flex flex-col gap-3 p-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <div className="font-medium">
                {pendingIndividualReviewBlocks.length > 0
                  ? `${pendingIndividualReviewBlocks.length} block${pendingIndividualReviewBlocks.length === 1 ? "" : "s"} require individual review`
                  : "All individually reviewed blocks are approved"}
              </div>
              <p className="mt-1 text-sm text-muted-foreground">
                {pendingIndividualReviewBlocks.length > 0
                  ? "Compare each pending table, figure, or clinical block with the original source. Figures cannot be bulk-approved. Rejected blocks remain pending until corrected and approved."
                  : "Return to the regeneration review, refresh its approval status, and accept the regenerated projection."}
              </p>
            </div>
            <div className="flex flex-wrap gap-2">
              <Button
                size="sm"
                disabled={pendingIndividualReviewBlocks.length === 0}
                onClick={() => selectBlock(pendingIndividualReviewBlocks[0])}
              >
                <Check className="h-4 w-4" /> Review next pending
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() =>
                  router.push(
                    `/guidelines/${id}/versions/${versionId}/markdown`,
                  )
                }
              >
                <ArrowLeft className="h-4 w-4" /> Return to regeneration review
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {(workspace.extraction_warnings.length > 0 ||
        workspace.validation.errors.length > 0 ||
        workspace.validation.warnings.length > 0) && (
        <Card className="border-amber-300">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <AlertTriangle className="h-4 w-4 text-amber-600" /> Extraction
              and publication review
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            {workspace.extraction_warnings.map((warning, index) => (
              <div key={`warning-${index}`} className="text-amber-800">
                {warning}
              </div>
            ))}
            {workspace.validation.warnings.map((issue, index) => (
              <div
                key={`${issue.code}-advisory-${index}`}
                className="text-amber-800"
              >
                Advisory: {issue.message}
              </div>
            ))}
            {workspace.validation.errors.map((issue, index) => (
              <button
                key={`${issue.code}-${index}`}
                className="block text-left text-destructive underline-offset-2 hover:underline"
                onClick={() => {
                  if (issue.section_id) setSelectedSectionId(issue.section_id);
                  if (issue.block_id) setSelectedBlockId(issue.block_id);
                }}
              >
                <span className="block font-medium">{issue.message}</span>
                {issue.remediation ? (
                  <span className="mt-1 block text-xs text-muted-foreground no-underline">
                    How to resolve: {issue.remediation}
                  </span>
                ) : null}
              </button>
            ))}
          </CardContent>
        </Card>
      )}

      <GuidelineBulkReviewPanel
        versionId={versionId}
        sections={sections}
        eligibleTypes={workspace.block_review_policy?.bulk_review_eligible_types || []}
        availableTypes={blockTypes}
        onSelectBlock={selectBlock}
        onReviewed={refresh}
      />

      <GuidelineCompletenessReport versionId={versionId} />

      <Tabs defaultValue="workspace" className="lg:hidden">
        <TabsList className="grid grid-cols-3">
          <TabsTrigger value="source">Source</TabsTrigger>
          <TabsTrigger value="workspace">Structure</TabsTrigger>
          <TabsTrigger value="preview">Preview</TabsTrigger>
        </TabsList>
        <TabsContent value="source">
          <SourcePanel src={pdfSource} page={selectedPage} />
        </TabsContent>
        <TabsContent value="workspace">
          <EditorPanel
            sections={sections}
            blocks={visibleSectionBlocks}
            sectionBlockCount={sectionBlocks.length}
            blockReviewFilter={blockReviewFilter}
            setBlockReviewFilter={setBlockReviewFilter}
            selectedSection={selectedSection}
            selectedBlock={selectedBlock}
            sectionDraft={sectionDraft}
            setSectionDraft={setSectionDraft}
            blockType={blockType}
            setBlockType={changeBlockType}
            blockJSON={blockJSON}
            setBlockJSON={setBlockJSON}
            setSelectedSectionId={setSelectedSectionId}
            setSelectedBlockId={setSelectedBlockId}
            pending={action.isPending}
            saveSection={saveSection}
            moveSection={moveSection}
            saveBlock={saveBlock}
            decide={decide}
            removeBlock={removeBlock}
            splitSection={splitSection}
            mergeSection={mergeSection}
          />
        </TabsContent>
        <TabsContent value="preview">
          <PreviewPanel
            blocks={sectionBlocks.filter(
              (block) => block.review_status !== "rejected",
            )}
            assets={workspace.assets}
            mode={previewMode}
            setMode={setPreviewMode}
          />
        </TabsContent>
      </Tabs>

      <div className="hidden min-h-[70vh] grid-cols-[minmax(280px,0.85fr)_minmax(380px,1.2fr)_minmax(300px,0.95fr)] gap-4 lg:grid">
        <SourcePanel src={pdfSource} page={selectedPage} />
        <EditorPanel
          sections={sections}
          blocks={visibleSectionBlocks}
          sectionBlockCount={sectionBlocks.length}
          blockReviewFilter={blockReviewFilter}
          setBlockReviewFilter={setBlockReviewFilter}
          selectedSection={selectedSection}
          selectedBlock={selectedBlock}
          sectionDraft={sectionDraft}
          setSectionDraft={setSectionDraft}
          blockType={blockType}
          setBlockType={changeBlockType}
          blockJSON={blockJSON}
          setBlockJSON={setBlockJSON}
          setSelectedSectionId={setSelectedSectionId}
          setSelectedBlockId={setSelectedBlockId}
          pending={action.isPending}
          saveSection={saveSection}
          moveSection={moveSection}
          saveBlock={saveBlock}
          decide={decide}
          removeBlock={removeBlock}
          splitSection={splitSection}
          mergeSection={mergeSection}
        />
        <PreviewPanel
          blocks={sectionBlocks.filter((block) => block.review_status !== "rejected")}
          assets={workspace.assets}
          mode={previewMode}
          setMode={setPreviewMode}
        />
      </div>
    </div>
  );
}

function SourcePanel({ src, page }: { src: string | null; page: number }) {
  return (
    <Card className="overflow-hidden">
      <CardHeader className="py-3">
        <CardTitle className="flex items-center justify-between text-sm">
          <span className="flex items-center gap-2">
            <FileText className="h-4 w-4" /> Original PDF · page {page}
          </span>
          {src && (
            <a href={src} target="_blank" rel="noreferrer">
              <ExternalLink className="h-4 w-4" />
            </a>
          )}
        </CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        {src ? (
          <iframe
            key={src}
            title="Original guideline PDF"
            src={src}
            className="h-[68vh] w-full border-0"
          />
        ) : (
          <div className="flex h-[68vh] items-center justify-center p-6 text-center text-sm text-muted-foreground">
            Original PDF preview could not be loaded.
          </div>
        )}
      </CardContent>
    </Card>
  );
}

type EditorPanelProps = {
  sections: GuidelineSectionRecord[];
  blocks: GuidelineContentBlockRecord[];
  sectionBlockCount: number;
  blockReviewFilter: BlockReviewFilter;
  setBlockReviewFilter: (value: BlockReviewFilter) => void;
  selectedSection?: GuidelineSectionRecord;
  selectedBlock?: GuidelineContentBlockRecord;
  sectionDraft: { title: string; slug: string; level: number };
  setSectionDraft: React.Dispatch<
    React.SetStateAction<{ title: string; slug: string; level: number }>
  >;
  blockType: GuidelineBlockType;
  setBlockType: (value: GuidelineBlockType) => void;
  blockJSON: string;
  setBlockJSON: (value: string) => void;
  setSelectedSectionId: (value: string) => void;
  setSelectedBlockId: (value: string) => void;
  pending: boolean;
  saveSection: () => void;
  moveSection: (direction: -1 | 1) => void;
  saveBlock: () => void;
  decide: (status: "reviewed" | "rejected") => void;
  removeBlock: () => void;
  splitSection: () => void;
  mergeSection: () => void;
};

function EditorPanel(props: EditorPanelProps) {
  return (
    <Card className="overflow-hidden">
      <CardHeader className="py-3">
        <CardTitle className="text-sm">Extracted structure</CardTitle>
      </CardHeader>
      <CardContent className="max-h-[72vh] space-y-4 overflow-auto p-4">
        <div className="space-y-1">
          {props.sections.map((section) => (
            <button
              key={section.id}
              onClick={() => props.setSelectedSectionId(section.id)}
              className={`flex w-full items-center justify-between rounded-md border px-3 py-2 text-left text-sm ${props.selectedSection?.id === section.id ? "border-primary bg-primary/5" : ""}`}
              style={{
                paddingLeft: `${12 + Math.max(0, section.level - 1) * 10}px`,
              }}
            >
              <span className="truncate">{section.title || "Untitled"}</span>
              <span className="text-xs text-muted-foreground">
                p.{section.page_start || "—"}
              </span>
            </button>
          ))}
        </div>
        {props.selectedSection && (
          <div className="space-y-3 rounded-md border p-3">
            <div className="grid gap-2 sm:grid-cols-[1fr_110px]">
              <div>
                <Label>Section title</Label>
                <Input
                  value={props.sectionDraft.title}
                  onChange={(event) =>
                    props.setSectionDraft((value) => ({
                      ...value,
                      title: event.target.value,
                    }))
                  }
                />
              </div>
              <div>
                <Label>Heading level</Label>
                <Input
                  type="number"
                  min={1}
                  max={6}
                  value={props.sectionDraft.level}
                  onChange={(event) =>
                    props.setSectionDraft((value) => ({
                      ...value,
                      level: Number(event.target.value),
                    }))
                  }
                />
              </div>
            </div>
            <div>
              <Label>Slug</Label>
              <Input
                value={props.sectionDraft.slug}
                onChange={(event) =>
                  props.setSectionDraft((value) => ({
                    ...value,
                    slug: event.target.value,
                  }))
                }
              />
            </div>
            <div className="flex flex-wrap gap-2">
              <Button
                size="sm"
                onClick={props.saveSection}
                disabled={props.pending}
              >
                <Save className="h-3.5 w-3.5" /> Save section
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => props.moveSection(-1)}
              >
                <ArrowUp className="h-3.5 w-3.5" />
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => props.moveSection(1)}
              >
                <ArrowDown className="h-3.5 w-3.5" />
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={props.mergeSection}
                disabled={props.sections[0]?.id === props.selectedSection.id}
              >
                <GitMerge className="h-3.5 w-3.5" /> Merge into previous
              </Button>
            </div>
          </div>
        )}
        <div className="space-y-2">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="text-xs font-semibold uppercase text-muted-foreground">
              Blocks · {props.blocks.length} of {props.sectionBlockCount}
            </div>
            <Label className="sr-only" htmlFor="block-review-filter">Block review filter</Label>
            <select
              id="block-review-filter"
              aria-label="Block review filter"
              className="h-8 rounded-md border bg-background px-2 text-xs"
              value={props.blockReviewFilter}
              onChange={(event) =>
                props.setBlockReviewFilter(event.target.value as BlockReviewFilter)
              }
            >
              <option value="high-risk">Individual review only</option>
              <option value="pending-high-risk">
                Pending individual review only
              </option>
              <option value="all">All blocks</option>
            </select>
          </div>
          {props.blocks.length === 0 && (
            <div className="rounded-md border border-dashed p-4 text-sm text-muted-foreground">
              No blocks in this section match the selected review filter.
            </div>
          )}
          {props.blocks.map((block) => (
            <button
              key={block.id}
              onClick={() => props.setSelectedBlockId(block.id)}
              className={`w-full rounded-md border p-3 text-left ${props.selectedBlock?.id === block.id ? "border-primary" : ""}`}
            >
              <div className="flex items-center justify-between gap-2">
                <Badge variant="outline">{block.type.replace("_", " ")}</Badge>
                <Badge
                  variant={
                    block.review_status === "reviewed"
                      ? "default"
                      : block.review_status === "rejected"
                        ? "destructive"
                        : "secondary"
                  }
                >
                  {block.review_status}
                </Badge>
              </div>
              <div className="mt-2 line-clamp-2 text-sm">
                {blockText(block) || "Structured payload"}
              </div>
              <div className="mt-1 text-xs text-muted-foreground">
                Page {block.page_start || "—"} · confidence{" "}
                {block.extraction_confidence == null
                  ? "—"
                  : `${Math.round(block.extraction_confidence * 100)}%`}
              </div>
            </button>
          ))}
        </div>
        {props.selectedBlock && (
          <div className="space-y-3 rounded-md border p-3">
            {props.selectedBlock.type === "figure" && (
              <div className="rounded-md border border-blue-200 bg-blue-50 p-3 text-sm text-blue-950">
                <div className="font-medium">Individual figure review</div>
                <p className="mt-1 text-xs leading-5">
                  Compare the image, caption, alternative text, source,
                  attribution, and licence with the authoritative document.
                  Approving this figure block also approves its linked asset.
                </p>
              </div>
            )}
            <div className="grid gap-2 sm:grid-cols-2">
              <div>
                <Label>Content type</Label>
                <select
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                  value={props.blockType}
                  onChange={(event) =>
                    props.setBlockType(event.target.value as GuidelineBlockType)
                  }
                >
                  {blockTypes.map((type) => (
                    <option key={type} value={type}>
                      {type.replace("_", " ")}
                    </option>
                  ))}
                </select>
              </div>
              <div className="flex items-end">
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={props.splitSection}
                >
                  <Scissors className="h-4 w-4" /> Split section here
                </Button>
              </div>
            </div>
            <div>
              <Label>Typed JSON payload</Label>
              <Textarea
                className="min-h-56 font-mono text-xs"
                value={props.blockJSON}
                onChange={(event) => props.setBlockJSON(event.target.value)}
              />
            </div>
            <div className="flex flex-wrap gap-2">
              <Button
                size="sm"
                onClick={props.saveBlock}
                disabled={props.pending}
              >
                <Save className="h-3.5 w-3.5" /> Save correction
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => props.decide("reviewed")}
              >
                <Check className="h-3.5 w-3.5" />{" "}
                {props.selectedBlock.type === "figure"
                  ? "Approve figure"
                  : "Approve block"}
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => props.decide("rejected")}
              >
                <X className="h-3.5 w-3.5" />{" "}
                {props.selectedBlock.type === "figure"
                  ? "Reject figure"
                  : "Reject block"}
              </Button>
              <Button
                size="sm"
                variant="destructive"
                onClick={props.removeBlock}
              >
                <Trash2 className="h-3.5 w-3.5" /> Artifact
              </Button>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function PreviewPanel({
  blocks,
  assets,
  mode,
  setMode,
}: {
  blocks: GuidelineContentBlockRecord[];
  assets: GuidelineAssetRecord[];
  mode: "web" | "mobile";
  setMode: (mode: "web" | "mobile") => void;
}) {
  return (
    <Card className="overflow-hidden">
      <CardHeader className="py-3">
        <CardTitle className="flex items-center justify-between text-sm">
          <span>Rendered preview</span>
          <span className="flex gap-1">
            <Button
              size="icon"
              variant={mode === "web" ? "default" : "outline"}
              onClick={() => setMode("web")}
            >
              <Monitor className="h-4 w-4" />
            </Button>
            <Button
              size="icon"
              variant={mode === "mobile" ? "default" : "outline"}
              onClick={() => setMode("mobile")}
            >
              <Smartphone className="h-4 w-4" />
            </Button>
          </span>
        </CardTitle>
      </CardHeader>
      <CardContent className="max-h-[68vh] overflow-auto bg-muted/30 p-3">
        <div
          className={`mx-auto space-y-4 bg-background p-5 shadow-sm transition-all ${mode === "mobile" ? "max-w-[390px] rounded-[24px]" : "w-full rounded-md"}`}
        >
          {blocks.length ? (
            blocks.map((block) => {
              const assetId =
                typeof block.content.asset_id === "string"
                  ? block.content.asset_id
                  : "";
              return (
                <BlockPreview
                  key={block.id}
                  block={block}
                  asset={assets.find((item) => item.id === assetId)}
                />
              );
            })
          ) : (
            <div className="py-20 text-center text-sm text-muted-foreground">
              No active blocks to preview.
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
