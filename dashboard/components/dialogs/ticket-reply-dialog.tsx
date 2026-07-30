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
import { Checkbox } from "@/components/ui/checkbox"
import { LoadingState } from "@/components/ui/loading-state"
import { Textarea } from "@/components/ui/textarea"

import { SupportTicketsService } from "@/services/support-tickets.service"
import type { SupportTicketsWithExpanded } from "@/types/expanded"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"

const replySchema = z.object({
  message: z.string().min(1, "Reply message is required"),
  is_internal: z.boolean(),
})

type ReplyFormData = z.infer<typeof replySchema>

interface TicketReplyDialogProps {
  ticket: SupportTicketsWithExpanded | null
  open: boolean
  onOpenChange: (open: boolean) => void
  onReplyAdded?: () => void
}

export function TicketReplyDialog({
  ticket,
  open,
  onOpenChange,
  onReplyAdded,
}: TicketReplyDialogProps) {
  const [loading, setLoading] = useState(false)

  const form = useForm<ReplyFormData>({
    resolver: zodResolver(replySchema),
    defaultValues: {
      message: "",
      is_internal: false,
    },
  })

  // Reset form when dialog opens/closes or ticket changes
  useEffect(() => {
    if (open && ticket) {
      form.reset({
        message: "",
        is_internal: false,
      })
    }
  }, [open, ticket, form])

  const onSubmit = async (data: ReplyFormData) => {
    if (!ticket) return

    try {
      setLoading(true)
      
      const backend = getBackendClient()
      const currentUser = backend.authStore.model
      
      if (!currentUser) {
        showToast.error("Error", "You must be logged in to reply")
        return
      }

      await SupportTicketsService.addReply({
        ticket_id: ticket.id,
        message: data.message,
        user_id: currentUser.id,
        is_internal: data.is_internal,
      })

      showToast.success(
        "Success", 
        data.is_internal ? "Internal note added" : "Reply added successfully"
      )
      
      form.reset()
      onOpenChange(false)
      onReplyAdded?.()
    } catch (error) {
      console.error('Error adding reply:', error)
      showToast.error("Error", "Failed to add reply")
    } finally {
      setLoading(false)
    }
  }

  if (!ticket) return null

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>
            Reply to: {ticket.subject}
          </DialogTitle>
          <DialogDescription>
            Add a reply to this support ticket. You can mark it as internal if it&apos;s only for team members.
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <FormField
              control={form.control}
              name="message"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Reply Message</FormLabel>
                  <FormControl>
                    <Textarea
                      {...field}
                      placeholder="Type your reply here..."
                      className="min-h-[200px]"
                      rows={8}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="is_internal"
              render={({ field }) => (
                <FormItem className="flex flex-row items-start space-x-3 space-y-0 rounded-md border p-4">
                  <FormControl>
                    <Checkbox
                      checked={field.value}
                      onCheckedChange={field.onChange}
                    />
                  </FormControl>
                  <div className="space-y-1 leading-none">
                    <FormLabel className="font-medium">
                      Internal Note
                    </FormLabel>
                    <p className="text-sm text-muted-foreground">
                      Mark this as an internal note that won&apos;t be visible to the ticket creator
                    </p>
                  </div>
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
                  <LoadingState size="sm" message="Adding Reply..." />
                ) : (
                  form.watch("is_internal") ? "Add Internal Note" : "Add Reply"
                )}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}