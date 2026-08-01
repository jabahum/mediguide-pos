"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { Bell, Loader2, Plus, RefreshCw } from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { PageHeader } from "@/components/ui/page-header"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { hasAnyRole } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"
import { notificationsService, NotificationDto, NotificationPriority, NotificationType } from "@/services/notifications.service"
import { usePermissionContext } from "@/lib/permission-context"

export default function NotificationsPage() {
  const [dialogOpen, setDialogOpen] = React.useState(false)
  const [creating, setCreating] = React.useState(false)
  const [canCreateNotifications, setCanCreateNotifications] = React.useState(false)
  const [items, setItems] = React.useState<NotificationDto[]>([])
  const [fetching, setFetching] = React.useState(true)
  const [listError, setListError] = React.useState("")
  const [search, setSearch] = React.useState("")
  const [page, setPage] = React.useState(1)
  const [totalPages, setTotalPages] = React.useState(0)
  const [formData, setFormData] = React.useState({
    title: "",
    message: "",
    type: "info" as NotificationType,
    priority: "normal" as NotificationPriority,
    action_url: "",
  })

  const router = useRouter()
  const { hasPermission, loading } = usePermissionContext()

  React.useEffect(() => {
    if (loading) return
    if (!hasPermission("system_settings", "read:any")) {
      router.replace("/")
    }
  }, [loading, hasPermission, router])

  const loadNotifications = React.useCallback(async () => {
    setFetching(true)
    setListError("")
    try {
      const result = await notificationsService.list({ page, per_page: 20, search: search.trim() || undefined, sort: "created_at", order: "desc" })
      setItems(result.items)
      setTotalPages(result.total_pages)
    } catch (error) {
      setListError(error instanceof Error ? error.message : "Failed to load notifications")
    } finally {
      setFetching(false)
    }
  }, [page, search])

  React.useEffect(() => { void loadNotifications() }, [loadNotifications])

  const resetForm = () => {
    setFormData({
      title: "",
      message: "",
      type: "info",
      priority: "normal",
      action_url: "",
    })
  }

  React.useEffect(() => {
    setCanCreateNotifications(hasAnyRole(["super_admin", "admin"]))
  }, [])

  const handleDialogOpenChange = (open: boolean) => {
    setDialogOpen(open)
    if (!open && !creating) {
      resetForm()
    }
  }

  const applyMaintenanceTemplate = () => {
    setFormData((current) => ({
      ...current,
      title: "Scheduled maintenance",
      message: "MediGuide will be unavailable for scheduled maintenance. Please save your work and try again after the maintenance window.",
      type: "warning",
      priority: "high",
    }))
  }

  const handleCreateNotification = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    const title = formData.title.trim()
    const message = formData.message.trim()
    const actionUrl = formData.action_url.trim()

    if (!title || !message) {
      showToast.warning("Missing details", "Add a title and message before publishing the notification")
      return
    }

    setCreating(true)

    try {
      await notificationsService.create({
        title,
        message,
        type: formData.type,
        priority: formData.priority,
        ...(actionUrl ? { action_url: actionUrl } : {}),
      })

      showToast.success("Notification published", "The notice has been added to the table and is available in the mobile app")
      resetForm()
      setDialogOpen(false)
      setPage(1)
      await loadNotifications()
    } catch (error: unknown) {
      console.error("Failed to create notification:", error)
      const message = error instanceof Error ? error.message : "Failed to create notification"
      showToast.error("Error", message)
    } finally {
      setCreating(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <PageHeader
          title="Notifications"
          description="System notifications and alerts center"
        />

        {canCreateNotifications && (
          <Dialog open={dialogOpen} onOpenChange={handleDialogOpenChange}>
            <DialogTrigger asChild>
              <Button>
                <Plus className="mr-2 h-4 w-4" />
                New Notification
              </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[560px]">
              <DialogHeader>
                <DialogTitle>Create Notification</DialogTitle>
                <DialogDescription>
                  Publish a general in-app notice for maintenance windows, system updates, or important alerts.
                </DialogDescription>
              </DialogHeader>

              <form onSubmit={handleCreateNotification} className="space-y-4">
                <div className="rounded-md border bg-muted/40 p-3 text-sm">
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                      <p className="font-medium">Audience: all app users</p>
                      <p className="text-muted-foreground">
                        Leave the action URL empty unless users should open a status page or support article.
                      </p>
                    </div>
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={applyMaintenanceTemplate}
                    >
                      Use Maintenance Template
                    </Button>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="notification-title">Title</Label>
                  <Input
                    id="notification-title"
                    value={formData.title}
                    onChange={(event) =>
                      setFormData((current) => ({ ...current, title: event.target.value }))
                    }
                    placeholder="Scheduled maintenance"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="notification-message">Message</Label>
                  <Textarea
                    id="notification-message"
                    value={formData.message}
                    onChange={(event) =>
                      setFormData((current) => ({ ...current, message: event.target.value }))
                    }
                    placeholder="MediGuide will be unavailable on Saturday from 10:00 PM to 11:00 PM for maintenance."
                    rows={5}
                    required
                  />
                </div>

                <div className="grid gap-4 sm:grid-cols-2">
                  <div className="space-y-2">
                    <Label>Type</Label>
                    <Select
                      value={formData.type}
                      onValueChange={(value: NotificationType) =>
                        setFormData((current) => ({ ...current, type: value }))
                      }
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="info">Info</SelectItem>
                        <SelectItem value="success">Success</SelectItem>
                        <SelectItem value="warning">Warning</SelectItem>
                        <SelectItem value="error">Error</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label>Priority</Label>
                    <Select
                      value={formData.priority}
                      onValueChange={(value: NotificationPriority) =>
                        setFormData((current) => ({ ...current, priority: value }))
                      }
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="low">Low</SelectItem>
                        <SelectItem value="normal">Normal</SelectItem>
                        <SelectItem value="high">High</SelectItem>
                        <SelectItem value="urgent">Urgent</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="notification-action-url">Action URL optional</Label>
                  <Input
                    id="notification-action-url"
                    type="url"
                    value={formData.action_url}
                    onChange={(event) =>
                      setFormData((current) => ({ ...current, action_url: event.target.value }))
                    }
                    placeholder="https://example.com/status"
                  />
                </div>

                <DialogFooter>
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setDialogOpen(false)}
                    disabled={creating}
                  >
                    Cancel
                  </Button>
                  <Button type="submit" disabled={creating}>
                    {creating ? (
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    ) : (
                      <Bell className="mr-2 h-4 w-4" />
                    )}
                    Publish
                  </Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        )}
      </div>

      <div className="space-y-3 rounded-md border p-4">
        <div className="flex gap-2">
          <Input value={search} onChange={(event) => { setSearch(event.target.value); setPage(1) }} placeholder="Search notifications..." />
          <Button variant="outline" size="icon" onClick={() => void loadNotifications()} aria-label="Refresh notifications">
            <RefreshCw className={fetching ? "h-4 w-4 animate-spin" : "h-4 w-4"} />
          </Button>
        </div>
        {listError ? (
          <div className="rounded-md border border-destructive/40 p-4 text-sm text-destructive">{listError}</div>
        ) : (
          <Table>
            <TableHeader><TableRow><TableHead>Title</TableHead><TableHead>Message</TableHead><TableHead>Type</TableHead><TableHead>Priority</TableHead><TableHead>Created</TableHead></TableRow></TableHeader>
            <TableBody>
              {!fetching && items.length === 0 && <TableRow><TableCell colSpan={5} className="py-8 text-center text-muted-foreground">No notifications found</TableCell></TableRow>}
              {items.map((item) => <TableRow key={item.id}><TableCell className="font-medium">{item.title}</TableCell><TableCell className="max-w-md whitespace-normal text-muted-foreground">{item.message}</TableCell><TableCell>{item.type}</TableCell><TableCell>{item.priority}</TableCell><TableCell>{new Date(item.created_at).toLocaleString()}</TableCell></TableRow>)}
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
