"use client";

import { useState, useEffect, use, useMemo } from "react";
import { useRouter } from "next/navigation";
import { usePermissionContext } from "@/lib/permission-context";
import { Edit, FileText, Trash2, Plus } from "lucide-react";
import { PageHeader } from "@/components/ui/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { LoadingState } from "@/components/ui/loading-state";
import { RichContent } from "@/components/ui/rich-content";
import { ConfirmDialog } from "@/components/dialogs/confirm-dialog";
import { GenericPagesService } from "@/services/generic-pages.service";
import { showToast } from "@/lib/toast";
import { useDomainRecord } from "@/hooks/use-domain-record";
import { GenericPagesResponse } from "@/types/backend-types";

export default function PageDetailsPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const router = useRouter();
  const resolvedParams = use(params);
  const { record: page, loading, error, refresh: loadPage } = useDomainRecord<GenericPagesResponse>(
    "generic_pages",
    resolvedParams.id,
    GenericPagesService.getPageById,
  );
  const { hasPermission, loading: permLoading } = usePermissionContext();
  // const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (permLoading) return;
    if (!hasPermission("content", "read:any")) {
      router.replace("/pages");
    }
  }, [permLoading, hasPermission, router]);
  // const [page, setPage] = useState<GenericPagesResponse | null>(null);
  const [activeTab, setActiveTab] = useState("");
  const [deleteDialog, setDeleteDialog] = useState({
    open: false,
    loading: false,
    contentKey: "",
    contentTitle: ""
  });

  useEffect(() => {
    if (!error) return;
    console.error("Error loading page:", error);
    showToast.error("Load Failed", "Failed to load page data");
    router.push("/pages");
  }, [error, router]);

  // Content type detection (from lab tests pattern)
  const contentStructure = useMemo(() => {
    if (!page?.content) return "simple";
    return typeof page.content === "object" && page.content !== null
      ? "keyed"
      : "simple";
  }, [page?.content]);

  // Get content keys for tabs (keyed content)
  const contentKeys = useMemo(() => {
    if (contentStructure !== "keyed" || !page?.content) return [];
    return Object.keys(page.content as Record<string, unknown>);
  }, [page?.content, contentStructure]);

  // Set initial active tab when page loads
  useEffect(() => {
    if (page && contentKeys.length > 0) {
      if (!contentKeys.includes(activeTab)) {
        setActiveTab(contentKeys[0]);
      }
    }
  }, [page, contentKeys, activeTab]);

  const handleDelete = async () => {
    if (!page) return;

    try {
      await GenericPagesService.deletePage(page.id);
      showToast.success(
        "Page Deleted",
        `Page "${page.title}" has been deleted successfully`,
      );
      router.push("/pages");
    } catch (error) {
      showToast.error(
        "Delete Failed",
        error instanceof Error ? error.message : "Failed to delete page",
      );
    }
  };

  const handleDeleteContent = (contentKey: string) => {
    const content = (
      page?.content as Record<string, { title?: string; content?: string }>
    )?.[contentKey];
    
    if (content && page) {
      setDeleteDialog({
        open: true,
        loading: false,
        contentKey: contentKey,
        contentTitle: content.title || contentKey
      });
    }
  };

  const confirmDeleteContent = async () => {
    if (!deleteDialog.contentKey || !page) return;

    setDeleteDialog(prev => ({ ...prev, loading: true }));
    try {
      await GenericPagesService.deleteContent(page.key, deleteDialog.contentKey);
      showToast.success("Content Deleted", "Content section has been deleted successfully");
      
      // Reload page data
      await loadPage();
      
      // Reset dialog state
      setDeleteDialog({
        open: false,
        loading: false,
        contentKey: "",
        contentTitle: ""
      });
    } catch (error) {
      console.error("Error deleting content:", error);
      showToast.error(
        "Delete Failed", 
        error instanceof Error ? error.message : "Failed to delete content"
      );
      setDeleteDialog(prev => ({ ...prev, loading: false }));
    }
  };

  if (loading) return <LoadingState message="Loading page..." />;

  if (!page) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Page Not Found"
          description="The requested page does not exist"
          showBackButton={true}
          onBack={() => router.push("/pages")}
        />
        <Card>
          <CardContent className="text-center py-8">
            <p className="text-muted-foreground">
              The page you&apos;re looking for doesn&apos;t exist or has been
              deleted.
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  const hasContent = page.content !== null && page.content !== undefined;

  return (
    <div className="space-y-6 w-full overflow-x-hidden">
      <PageHeader
        title={page.title}
        description={page.description || "No description provided"}
        showBackButton={true}
        onBack={() => router.push("/pages")}
        actions={[
          {
            label: "Edit Page Info",
            onClick: () => router.push(`/pages/${page.id}/edit`),
            icon: <Edit className="h-4 w-4" />,
            variant: "outline"
          },
          ...(contentStructure === "keyed" ? [{
            label: "Add Section",
            onClick: () =>
              router.push(
                `/generic-pages/${page.key}/content/create?returnTo=/pages/${page.id}`,
              ),
            icon: <Plus className="h-4 w-4" />,
          }] : [{
            label: "Edit Content",
            onClick: () =>
              router.push(
                `/generic-pages/${page.key}/content/edit?returnTo=/pages/${page.id}`,
              ),
            icon: <Edit className="h-4 w-4" />,
          }]),
          {
            label: "Delete Page",
            onClick: handleDelete,
            variant: "destructive",
            icon: <Trash2 className="h-4 w-4" />,
          },
        ]}
      />

      {/* Content Display - Full Screen */}
      {hasContent ? (
        <Card className="w-full">
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                {page.title}
              </CardTitle>
              <div className="flex items-center gap-2">
                <Badge variant="default">
                  {contentStructure === "keyed"
                    ? "Key-Value Sections"
                    : "HTML Content"}
                </Badge>
              </div>
            </div>
          </CardHeader>
          <CardContent className="overflow-hidden">
            {contentStructure === "simple" ? (
              // HTML Content Type - render directly
              <div className="prose max-w-none overflow-x-auto">
                <RichContent html={page.content as string} />
              </div>
            ) : // Key-Value Type - render with scrollable tabs
            contentKeys.length > 0 ? (
              <Tabs
                value={activeTab}
                onValueChange={setActiveTab}
                className="w-full"
              >
                <div className="w-full overflow-x-auto">
                  <TabsList className="inline-flex">
                    {contentKeys.map((key) => {
                      const content = (
                        page.content as Record<
                          string,
                          { title?: string; content?: string }
                        >
                      )?.[key];
                      return (
                        <TabsTrigger
                          key={key}
                          value={key}
                          className="flex-shrink-0 whitespace-nowrap"
                        >
                          {content?.title || key}
                        </TabsTrigger>
                      );
                    })}
                  </TabsList>
                </div>

                {contentKeys.map((key) => {
                  const content = (
                    page.content as Record<
                      string,
                      { title?: string; content?: string }
                    >
                  )?.[key];
                  if (!content) return null;

                  return (
                    <TabsContent
                      key={key}
                      value={key}
                      className="mt-4 overflow-x-hidden"
                    >
                      <Card>
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-4">
                          <CardTitle>{content?.title || key}</CardTitle>
                          <div className="flex items-center space-x-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() =>
                                router.push(
                                  `/generic-pages/${page.key}/content/edit?contentKey=${key}&returnTo=/pages/${page.id}`
                                )
                              }
                            >
                              <Edit className="h-4 w-4 mr-1" />
                              Edit
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleDeleteContent(key)}
                            >
                              Delete
                            </Button>
                          </div>
                        </CardHeader>
                        <CardContent>
                          <div className="prose max-w-none overflow-x-auto">
                            <RichContent html={content.content} />
                          </div>
                        </CardContent>
                      </Card>
                    </TabsContent>
                  );
                })}
              </Tabs>
            ) : (
              <div className="text-center py-8">
                <FileText className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                <p className="text-muted-foreground mb-4">
                  No content sections yet.
                </p>
              </div>
            )}
          </CardContent>
        </Card>
      ) : (
        <Card className="min-w-0">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5" />
              {page.title}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-center py-8">
              <FileText className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground mb-4">
                This page has no content yet.
              </p>
              <button
                onClick={() =>
                  router.push(
                    `/generic-pages/${page.key}/content/create?returnTo=/pages/${page.id}`,
                  )
                }
                className="text-primary hover:underline"
              >
                Add content to this page →
              </button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Delete Content Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialog.open}
        onOpenChange={(open) => setDeleteDialog(prev => ({ ...prev, open }))}
        title="Delete Content Section"
        description={`Are you sure you want to delete "${deleteDialog.contentTitle}"? This action cannot be undone.`}
        confirmText="Delete"
        cancelText="Cancel"
        variant="destructive"
        onConfirm={confirmDeleteContent}
        loading={deleteDialog.loading}
      />
    </div>
  );
}
