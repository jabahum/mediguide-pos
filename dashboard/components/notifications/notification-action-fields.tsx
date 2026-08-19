"use client"

import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import type { NotificationAction, NotificationActionType } from "@/services/notifications.service"

const resourceActionTypes = new Set<NotificationActionType>([
  "guideline",
  "outbreak",
  "situation_report",
  "drug",
  "calculator",
  "facility",
  "support_ticket",
])

const internalRoutes = [
  ["/home", "Home"],
  ["/search", "Search"],
  ["/guidelines", "Guidelines"],
  ["/tools", "Tools"],
  ["/library", "Library"],
  ["/offline-content", "Offline content"],
  ["/outbreak-hub", "Outbreak hub"],
  ["/situation-reports", "Situation reports"],
  ["/drug-index", "Drug index"],
  ["/health-facilities", "Health facilities"],
  ["/calculators", "Calculators"],
  ["/ai-assistant", "AI assistant"],
  ["/notifications", "Notifications"],
  ["/help-center", "Help center"],
] as const

export const emptyNotificationAction = (): NotificationAction => ({
  type: "none",
  parameters: {},
})

export function NotificationActionFields({
  value,
  onChange,
  allowSupportTicket = true,
}: {
  value: NotificationAction
  onChange: (value: NotificationAction) => void
  allowSupportTicket?: boolean
}) {
  const changeType = (type: NotificationActionType) => {
    if (type === "internal_route") {
      onChange({ type, route: "/home", parameters: {} })
      return
    }
    onChange({ type, parameters: {} })
  }

  return (
    <div className="space-y-3 rounded-lg border p-4">
      <div className="space-y-2">
        <Label htmlFor="notification-action-type">Tap action</Label>
        <Select value={value.type} onValueChange={(type: NotificationActionType) => changeType(type)}>
          <SelectTrigger id="notification-action-type"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="none">No action</SelectItem>
            <SelectItem value="guideline">Open guideline</SelectItem>
            <SelectItem value="outbreak">Open outbreak</SelectItem>
            <SelectItem value="situation_report">Open situation report</SelectItem>
            <SelectItem value="drug">Open drug</SelectItem>
            <SelectItem value="calculator">Open calculator</SelectItem>
            <SelectItem value="facility">Open facility</SelectItem>
            {allowSupportTicket ? <SelectItem value="support_ticket">Open support ticket</SelectItem> : null}
            <SelectItem value="internal_route">Open app screen</SelectItem>
            <SelectItem value="approved_external_url">Open approved website</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {resourceActionTypes.has(value.type) ? (
        <div className="space-y-2">
          <Label htmlFor="notification-resource-id">Resource UUID</Label>
          <Input
            id="notification-resource-id"
            required
            placeholder="00000000-0000-0000-0000-000000000000"
            value={value.resource_id ?? ""}
            onChange={(event) => onChange({ ...value, resource_id: event.target.value.trim(), route: undefined })}
          />
          <p className="text-xs text-muted-foreground">The backend verifies that this resource exists and derives the safe app route.</p>
        </div>
      ) : null}

      {value.type === "internal_route" ? (
        <div className="space-y-2">
          <Label htmlFor="notification-internal-route">App screen</Label>
          <Select value={value.route ?? "/home"} onValueChange={(route) => onChange({ ...value, route })}>
            <SelectTrigger id="notification-internal-route"><SelectValue /></SelectTrigger>
            <SelectContent>
              {internalRoutes.map(([route, label]) => <SelectItem key={route} value={route}>{label}</SelectItem>)}
            </SelectContent>
          </Select>
        </div>
      ) : null}

      {value.type === "approved_external_url" ? (
        <div className="space-y-2">
          <Label htmlFor="notification-external-url">Approved HTTPS URL</Label>
          <Input
            id="notification-external-url"
            required
            type="url"
            placeholder="https://www.who.int/..."
            value={value.route ?? ""}
            onChange={(event) => onChange({ ...value, route: event.target.value.trim(), resource_id: undefined })}
          />
          <p className="text-xs text-muted-foreground">The destination host must be explicitly approved by the backend and mobile app.</p>
        </div>
      ) : null}
    </div>
  )
}
