"use client"

import { useState, useEffect } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { LoadingState } from "@/components/ui/loading-state"
import { Badge } from "@/components/ui/badge"

import { SupportTicketsService } from "@/services/support-tickets.service"
import type { SupportTicketsWithExpanded } from "@/types/expanded"
import type { SupportTicketsStatusOptions, SupportTicketsPriorityOptions } from "@/types/backend-types"
import { TICKET_STATUS_CONFIG, TICKET_PRIORITY_CONFIG } from "@/types/support-tickets"
import { showToast } from "@/lib/toast"

const statusUpdateSchema = z.object({
  status: z.enum(["open", "in_progress", "resolved", "closed"]),
  priority: z.enum(["low", "normal", "high", "urgent"]),
})

type StatusUpdateFormData = z.infer<typeof statusUpdateSchema>

interface TicketStatusUpdateDialogProps {
  ticket: SupportTicketsWithExpanded | null
  open: boolean
  onOpenChange: (open: boolean) => void
  onStatusUpdated?: () => void
}

export function TicketStatusUpdateDialog({
  ticket,
  open,
  onOpenChange,
  onStatusUpdated,
}: TicketStatusUpdateDialogProps) {
  const [loading, setLoading] = useState(false)

  const form = useForm<StatusUpdateFormData>({
    resolver: zodResolver(statusUpdateSchema),
  })

  // Set form values when ticket changes
  useEffect(() => {
    if (ticket && open) {
      form.reset({
        status: ticket.status,
        priority: ticket.priority,
      })
    }
  }, [ticket, open, form])

  const onSubmit = async (data: StatusUpdateFormData) => {
    if (!ticket) return

    try {
      setLoading(true)

      // Check if anything actually changed
      const hasChanges = data.status !== ticket.status || data.priority !== ticket.priority

      if (!hasChanges) {
        showToast.info("Info", "No changes to update")
        onOpenChange(false)
        return
      }

      // Update the ticket
      await SupportTicketsService.updateTicket(ticket.id, {
        status: data.status as SupportTicketsStatusOptions,
        priority: data.priority as SupportTicketsPriorityOptions,
      })

      const statusChanged = data.status !== ticket.status
      const priorityChanged = data.priority !== ticket.priority

      let message = "Ticket updated successfully"
      if (statusChanged && priorityChanged) {
        message = `Status changed to ${TICKET_STATUS_CONFIG[data.status].label} and priority to ${TICKET_PRIORITY_CONFIG[data.priority].label}`
      } else if (statusChanged) {
        message = `Status changed to ${TICKET_STATUS_CONFIG[data.status].label}`
      } else if (priorityChanged) {
        message = `Priority changed to ${TICKET_PRIORITY_CONFIG[data.priority].label}`
      }

      showToast.success("Success", message)
      onOpenChange(false)
      onStatusUpdated?.()
    } catch (error) {
      console.error('Error updating ticket:', error)
      showToast.error("Error", "Failed to update ticket")
    } finally {
      setLoading(false)
    }
  }

  if (!ticket) return null

  const currentStatusConfig = TICKET_STATUS_CONFIG[ticket.status]
  const currentPriorityConfig = TICKET_PRIORITY_CONFIG[ticket.priority]

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Update Ticket Status & Priority</DialogTitle>
          <DialogDescription>
            Change the status and priority of this support ticket.
          </DialogDescription>
          <div className="flex items-center gap-2 pt-2">
            <span className="text-sm text-muted-foreground">Current:</span>
            <Badge variant="outline" className={currentStatusConfig.color}>
              {currentStatusConfig.label}
            </Badge>
            <Badge variant="outline" className={currentPriorityConfig.color}>
              {currentPriorityConfig.label}
            </Badge>
          </div>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="status"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Status</FormLabel>
                  <Select onValueChange={field.onChange} value={field.value}>
                    <FormControl>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select status" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {Object.entries(TICKET_STATUS_CONFIG).map(([value, config]) => (
                        <SelectItem key={value} value={value}>
                          {config.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="priority"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Priority</FormLabel>
                  <Select onValueChange={field.onChange} value={field.value}>
                    <FormControl>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select priority" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {Object.entries(TICKET_PRIORITY_CONFIG).map(([value, config]) => (
                        <SelectItem key={value} value={value}>
                          {config.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />

            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => onOpenChange(false)}
                disabled={loading}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={loading}>
                {loading ? (
                  <LoadingState size="sm" message="Updating..." />
                ) : (
                  "Update Ticket"
                )}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}