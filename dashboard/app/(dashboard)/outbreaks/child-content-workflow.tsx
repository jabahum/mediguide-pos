"use client"

import * as React from "react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { showToast } from "@/lib/toast"
import {
  outbreaksService,
  type OutbreakResourceRecord,
  type OutbreakUpdateRecord,
} from "@/services/outbreaks.service"

type ChildRecord = OutbreakUpdateRecord | OutbreakResourceRecord
type ChildKind = "update" | "resource"

export function ChildContentWorkflow({
  outbreakId,
  kind,
  items,
  empty,
  onChanged,
}: {
  outbreakId: string
  kind: ChildKind
  items: ChildRecord[]
  empty: string
  onChanged: () => Promise<void>
}) {
  const [workingId, setWorkingId] = React.useState<string | null>(null)

  async function run(item: ChildRecord, action: "submit" | "approve" | "publish" | "withdraw" | "correct") {
    if (!item.id || item.lock_version === undefined) return

    let reason = ""
    if (action === "withdraw" || action === "correct") {
      reason = window.prompt(`Enter the reason for this ${action}`)?.trim() || ""
      if (!reason) return
    }
    if (action === "publish" && !window.confirm(`Publish this outbreak ${kind}? Published content is immutable.`)) return

    setWorkingId(item.id)
    try {
      const input = { lock_version: item.lock_version, reason }
      if (kind === "update") {
        if (action === "correct") await outbreaksService.correctUpdate(outbreakId, item.id, input)
        else await outbreaksService.transitionUpdate(outbreakId, item.id, action, input)
      } else {
        if (action === "correct") await outbreaksService.correctResource(outbreakId, item.id, input)
        else await outbreaksService.transitionResource(outbreakId, item.id, action, input)
      }
      await onChanged()
      showToast.success("Workflow updated", `The ${kind} workflow action completed.`)
    } catch (value) {
      const message = value instanceof Error ? value.message : "The workflow action failed."
      showToast.error("Workflow failed", /conflict|modified|lock/i.test(message) ? "Another editor changed this item. Reload before retrying." : message)
    } finally {
      setWorkingId(null)
    }
  }

  if (!items.length) return <p className="text-sm text-muted-foreground">{empty}</p>

  return <div className="space-y-2">
    {items.map(item => {
      const status = item.status || "draft"
      const busy = workingId === item.id
      const detail = "resource_type" in item ? item.resource_type : "summary" in item ? item.summary : undefined
      return <div key={item.id} className="flex flex-col gap-3 rounded-md border p-3 lg:flex-row lg:items-center lg:justify-between">
        <div className="min-w-0">
          <div className="truncate font-medium">{item.title || `Untitled ${kind}`}</div>
          {detail ? <div className="truncate text-xs text-muted-foreground">{detail}</div> : null}
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Badge variant="outline">{status}</Badge>
          {status === "draft" ? <Button size="sm" variant="outline" disabled={busy} onClick={() => void run(item, "submit")}>Submit</Button> : null}
          {status === "pending_review" ? <Button size="sm" variant="outline" disabled={busy} onClick={() => void run(item, "approve")}>Approve</Button> : null}
          {status === "pending_review" && item.approved_at ? <Button size="sm" disabled={busy} onClick={() => void run(item, "publish")}>Publish</Button> : null}
          {status === "published" ? <Button size="sm" variant="outline" disabled={busy} onClick={() => void run(item, "correct")}>Create correction</Button> : null}
          {status !== "draft" && status !== "withdrawn" ? <Button size="sm" variant="destructive" disabled={busy} onClick={() => void run(item, "withdraw")}>Withdraw</Button> : null}
        </div>
      </div>
    })}
  </div>
}
