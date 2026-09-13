"use client";

import * as React from "react";
import Link from "next/link";
import { Plus } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/ui/page-header";
import { hasBackendPermission } from "@/lib/backend-client";
import { showToast } from "@/lib/toast";
import { ContentHub, contentHubService } from "@/services/content-hubs.service";

export default function ContentHubsPage() {
  const canManage = hasBackendPermission("content_hub.manage");
  const [rows, setRows] = React.useState<ContentHub[]>([]);
  const [search, setSearch] = React.useState("");
  React.useEffect(() => {
    const timer = setTimeout(() => {
      void contentHubService
        .list({ search })
        .then((value) => setRows(value.items || []))
        .catch((error) =>
          showToast.error(
            "Hubs unavailable",
            error instanceof Error ? error.message : "Try again.",
          ),
        );
    }, 200);
    return () => clearTimeout(timer);
  }, [search]);
  return (
    <div className="space-y-6">
      <PageHeader
        title="Content hubs"
        description="Curate disease and outbreak resources into API-managed pillars for web and mobile."
      />
      <div className="flex gap-2">
        <Input
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder="Search hubs"
        />
        {canManage ? <Button asChild>
          <Link href="/content-hubs/new">
            <Plus className="mr-2 h-4 w-4" />
            New hub
          </Link>
        </Button> : null}
      </div>
      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
        {rows.map((row) => (
          <Card key={row.id}>
            <CardHeader className="pb-2">
              <div className="flex justify-between gap-2">
                <CardTitle className="text-base">{row.name}</CardTitle>
                <Badge variant="outline">{row.status}</Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <p className="text-muted-foreground">
                {row.description || "No description"}
              </p>
              <p>
                {row.diseases?.map((value) => value.name).join(", ") ||
                  "General hub"}
              </p>
              <Button variant="outline" size="sm" asChild>
                <Link href={`/content-hubs/${row.id}`}>
                  {canManage ? "Manage hub" : "View hub"}
                </Link>
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>
      {rows.length === 0 ? (
        <div className="rounded-md border p-10 text-center text-muted-foreground">
          No hubs match this search.
        </div>
      ) : null}
    </div>
  );
}
