"use client"

import * as React from "react"
import Link from "next/link"
import { Bell, Check, Inbox, Loader2, RefreshCw, Settings } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { PageHeader } from "@/components/ui/page-header"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { hasBackendPermission } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"
import { notificationsService, type NotificationDto } from "@/services/notifications.service"

export default function NotificationsInboxPage() {
  const [items, setItems] = React.useState<NotificationDto[]>([])
  const [fetching, setFetching] = React.useState(true)
  const [listError, setListError] = React.useState("")
  const [search, setSearch] = React.useState("")
  const [page, setPage] = React.useState(1)
  const [totalPages, setTotalPages] = React.useState(0)
  const [updatingId, setUpdatingId] = React.useState<string | null>(null)
  const canAdminister = [
    "notification.publish",
    "notification.template.read",
    "notification.campaign.read",
    "firebase.status.read",
  ].some(hasBackendPermission)

  const loadNotifications = React.useCallback(async () => {
    setFetching(true)
    setListError("")
    try {
      const result = await notificationsService.list({
        page,
        per_page: 20,
        search: search.trim() || undefined,
        sort: "created_at",
        order: "desc",
      })
      setItems(result.items)
      setTotalPages(result.total_pages)
    } catch (error) {
      setListError(error instanceof Error ? error.message : "Failed to load notifications")
    } finally {
      setFetching(false)
    }
  }, [page, search])

  React.useEffect(() => {
    void loadNotifications()
  }, [loadNotifications])

  async function markRead(item: NotificationDto) {
    if (item.is_read) return
    setUpdatingId(item.id)
    try {
      const updated = await notificationsService.markRead(item.id)
      setItems((current) => current.map((value) => (value.id === item.id ? updated : value)))
    } catch (error) {
      showToast.error("Notification", error instanceof Error ? error.message : "Unable to mark notification as read")
    } finally {
      setUpdatingId(null)
    }
  }

  async function markAllRead() {
    setUpdatingId("all")
    try {
      await notificationsService.markAllRead()
      setItems((current) => current.map((item) => ({ ...item, is_read: true })))
      showToast.success("Notifications", "All notifications were marked as read")
    } catch (error) {
      showToast.error("Notifications", error instanceof Error ? error.message : "Unable to mark notifications as read")
    } finally {
      setUpdatingId(null)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <PageHeader title="Notification Inbox" description="Notices visible to your signed-in account" />
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" disabled={updatingId !== null || items.every((item) => item.is_read)} onClick={() => void markAllRead()}>
            {updatingId === "all" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Check className="mr-2 h-4 w-4" />}
            Mark all read
          </Button>
          {canAdminister ? (
            <Button asChild><Link href="/settings/notifications"><Settings className="mr-2 h-4 w-4" />Administration</Link></Button>
          ) : null}
        </div>
      </div>

      <div className="space-y-3 rounded-md border p-4">
        <div className="flex gap-2">
          <Input
            value={search}
            onChange={(event) => { setSearch(event.target.value); setPage(1) }}
            placeholder="Search your notifications..."
            aria-label="Search your notifications"
          />
          <Button variant="outline" size="icon" onClick={() => void loadNotifications()} aria-label="Refresh notifications">
            <RefreshCw className={fetching ? "h-4 w-4 animate-spin" : "h-4 w-4"} />
          </Button>
        </div>

        {listError ? (
          <div className="space-y-3 rounded-md border border-destructive/40 p-4 text-sm text-destructive" role="alert">
            <p>{listError}</p>
            <Button variant="outline" size="sm" onClick={() => void loadNotifications()}>Try again</Button>
          </div>
        ) : (
          <Table>
            <TableHeader><TableRow><TableHead>Status</TableHead><TableHead>Title</TableHead><TableHead>Message</TableHead><TableHead>Type</TableHead><TableHead>Priority</TableHead><TableHead>Created</TableHead><TableHead className="text-right">Action</TableHead></TableRow></TableHeader>
            <TableBody>
              {fetching ? <TableRow><TableCell colSpan={7} className="py-10 text-center text-muted-foreground"><Loader2 className="mr-2 inline h-4 w-4 animate-spin" />Loading notifications…</TableCell></TableRow> : null}
              {!fetching && items.length === 0 ? <TableRow><TableCell colSpan={7} className="py-12 text-center text-muted-foreground"><Inbox className="mx-auto mb-3 h-8 w-8" />No notifications found</TableCell></TableRow> : null}
              {items.map((item) => (
                <TableRow key={item.id} className={item.is_read ? "opacity-70" : undefined}>
                  <TableCell>{item.is_read ? "Read" : "Unread"}</TableCell>
                  <TableCell className="font-medium">{item.title}</TableCell>
                  <TableCell className="max-w-md whitespace-normal text-muted-foreground">{item.message}</TableCell>
                  <TableCell>{item.type}</TableCell><TableCell>{item.priority}</TableCell><TableCell>{new Date(item.created_at).toLocaleString()}</TableCell>
                  <TableCell className="text-right"><Button variant="ghost" size="sm" disabled={item.is_read || updatingId !== null} onClick={() => void markRead(item)} aria-label={`Mark ${item.title} as read`}>{updatingId === item.id ? <Loader2 className="h-4 w-4 animate-spin" /> : <Bell className="h-4 w-4" />}</Button></TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}

        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <span>Page {page}{totalPages > 0 ? ` of ${totalPages}` : ""}</span>
          <div className="flex gap-2"><Button variant="outline" size="sm" disabled={page <= 1 || fetching} onClick={() => setPage((value) => value - 1)}>Previous</Button><Button variant="outline" size="sm" disabled={page >= totalPages || fetching} onClick={() => setPage((value) => value + 1)}>Next</Button></div>
        </div>
      </div>
    </div>
  )
}
