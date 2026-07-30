"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { ColumnDef } from "@tanstack/react-table"
import { Bell, Loader2, Plus } from "lucide-react"

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
import { BackendDataTable } from "@/components/ui/backend-data-table"
import { PageHeader } from "@/components/ui/page-header"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { getBackendClient, hasAnyRole } from "@/lib/backend-client"
import { showToast } from "@/lib/toast"
import {
  NotificationsPriorityOptions,
  NotificationsResponse,
  NotificationsTypeOptions,
} from "@/types/backend-types"
import { usePermissionContext } from "@/lib/permission-context"

const columns: ColumnDef<NotificationsResponse>[] = [
  {
    accessorKey: "title",
    header: "Title",
    cell: ({ row }) => <span className="font-medium">{row.getValue("title")}</span>,
  },
  {
    accessorKey: "message",
    header: "Message",
    cell: ({ row }) => (
      <span className="line-clamp-2 text-muted-foreground">
        {row.getValue("message")}
      </span>
    ),
  },
  {
    accessorKey: "type",
    header: "Type",
  },
  {
    accessorKey: "priority",
    header: "Priority",
  },
  {
    accessorKey: "created",
    header: "Created",
    cell: ({ row }) => {
      const value = row.getValue("created")
      if (!value) return null
      return new Date(String(value)).toLocaleString()
    },
  },
  {
    accessorKey: "updated",
    header: "Updated",
    cell: ({ row }) => {
      const value = row.getValue("updated")
      if (!value) return null
      return new Date(String(value)).toLocaleString()
    },
  },
]

export default function NotificationsPage() {
  const [dialogOpen, setDialogOpen] = React.useState(false)
  const [creating, setCreating] = React.useState(false)
  const [canCreateNotifications, setCanCreateNotifications] = React.useState(false)
  const [tableRefreshSignal, setTableRefreshSignal] = React.useState(0)
  const [formData, setFormData] = React.useState({
    title: "",
    message: "",
    type: "info" as NotificationsTypeOptions,
    priority: "normal" as NotificationsPriorityOptions,
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
      const pb = getBackendClient()

      await pb.collection("notifications").create({
        title,
        message,
        type: formData.type,
        priority: formData.priority,
        ...(actionUrl ? { action_url: actionUrl } : {}),
      })

      showToast.success("Notification published", "The notice has been added to the table and is available in the mobile app")
      resetForm()
      setDialogOpen(false)
      setTableRefreshSignal((signal) => signal + 1)
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
                      onValueChange={(value: NotificationsTypeOptions) =>
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
                      onValueChange={(value: NotificationsPriorityOptions) =>
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

      <BackendDataTable<NotificationsResponse>
        collection="notifications"
        columns={columns}
        searchFields={["title", "message"]}
        refreshSignal={tableRefreshSignal}
        query={{
          sort: "-created",
        }}
        ui={{
          exportable: false,
          importable: false,
        }}
      />
    </div>
  )
}
