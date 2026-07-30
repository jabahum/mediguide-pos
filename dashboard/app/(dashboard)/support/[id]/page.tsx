"use client"

import { useState, useEffect, useCallback } from "react"
import { useParams, useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"
import { format } from "date-fns"
import { MessageSquare, User, Clock, AlertCircle, Plus, ArrowLeft, Edit } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Separator } from "@/components/ui/separator"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { LoadingState } from "@/components/ui/loading-state"
import { RichContent } from "@/components/ui/rich-content"
import { TicketReplyDialog } from "@/components/dialogs/ticket-reply-dialog"
import { TicketStatusUpdateDialog } from "@/components/dialogs/ticket-status-update-dialog"
import { TicketAssignDialog } from "@/components/dialogs/ticket-assign-dialog"

import { SupportTicketsService } from "@/services/support-tickets.service"
import type { SupportTicketsWithExpanded, SupportTicketRepliesWithExpanded } from "@/types/expanded"
import type { SupportTicketsStatusOptions } from "@/types/backend-types"
import { TICKET_STATUS_CONFIG, TICKET_PRIORITY_CONFIG } from "@/types/support-tickets"
import { showToast } from "@/lib/toast"

export default function TicketViewPage() {
  const params = useParams()
  const router = useRouter()
  const ticketId = params.id as string
  const { hasPermission, loading: permLoading } = usePermissionContext()

  const [ticket, setTicket] = useState<SupportTicketsWithExpanded | null>(null)
  const [replies, setReplies] = useState<SupportTicketRepliesWithExpanded[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (permLoading) return
    if (!hasPermission("content", "read:any")) {
      router.replace("/support")
    }
  }, [permLoading, hasPermission, router])

  // Dialog states
  const [replyDialogOpen, setReplyDialogOpen] = useState(false)
  const [statusDialogOpen, setStatusDialogOpen] = useState(false)
  const [assignDialogOpen, setAssignDialogOpen] = useState(false)

  const loadTicketData = useCallback(async () => {
    try {
      setLoading(true)
      const [ticketData, repliesData] = await Promise.all([
        SupportTicketsService.getTicketById(ticketId),
        SupportTicketsService.getTicketReplies(ticketId)
      ])
      
      setTicket(ticketData)
      setReplies(repliesData)
    } catch (error) {
      console.error('Error loading ticket:', error)
      showToast.error("Error", "Failed to load ticket")
      router.push('/support')
    } finally {
      setLoading(false)
    }
  }, [ticketId, router])

  // Load ticket and replies
  useEffect(() => {
    if (ticketId) {
      loadTicketData()
    }
  }, [ticketId, loadTicketData])


  // Handle dialog completions
  const handleDialogClose = useCallback(() => {
    loadTicketData() // Refresh both ticket and replies
  }, [loadTicketData])

  const handleQuickStatusChange = async (status: string) => {
    if (!ticket) return

    try {
      await SupportTicketsService.updateTicketStatus(ticket.id, status as SupportTicketsStatusOptions)
      showToast.success("Success", `Ticket marked as ${TICKET_STATUS_CONFIG[status as keyof typeof TICKET_STATUS_CONFIG].label}`)
      loadTicketData()
    } catch (error) {
      console.error('Error updating status:', error)
      showToast.error("Error", "Failed to update status")
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <LoadingState message="Loading ticket..." />
      </div>
    )
  }

  if (!ticket) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <AlertCircle className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
          <h3 className="text-lg font-medium">Ticket not found</h3>
          <p className="text-muted-foreground mb-4">The requested ticket could not be found.</p>
          <Button onClick={() => router.push('/support')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Support
          </Button>
        </div>
      </div>
    )
  }

  const statusConfig = TICKET_STATUS_CONFIG[ticket.status]
  const priorityConfig = TICKET_PRIORITY_CONFIG[ticket.priority]

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        title={ticket.subject}
        description={`Support Ticket #${ticket.id}`}
        showBackButton={true}
        onBack={() => router.push('/support')}
        actions={[
          {
            label: "Add Reply",
            onClick: () => setReplyDialogOpen(true),
            icon: <Plus className="h-4 w-4" />
          },
          {
            label: "Update Status",
            onClick: () => setStatusDialogOpen(true),
            variant: "outline",
            icon: <Edit className="h-4 w-4" />
          },
          {
            label: "Assign",
            onClick: () => setAssignDialogOpen(true),
            variant: "outline",
            icon: <User className="h-4 w-4" />
          }
        ]}
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Ticket Info Card */}
          <Card>
            <CardHeader>
              <div className="flex items-start justify-between">
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <Badge variant="outline" className={statusConfig.color}>
                      {statusConfig.label}
                    </Badge>
                    <Badge variant="outline" className={priorityConfig.color}>
                      {priorityConfig.label}
                    </Badge>
                    {ticket.category && (
                      <Badge variant="secondary">
                        {ticket.category}
                      </Badge>
                    )}
                  </div>
                </div>
                
                {/* Quick Status Actions */}
                <div className="flex gap-1">
                  {ticket.status !== "in_progress" && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleQuickStatusChange("in_progress")}
                    >
                      <Clock className="h-4 w-4 mr-1" />
                      In Progress
                    </Button>
                  )}
                  {ticket.status !== "resolved" && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleQuickStatusChange("resolved")}
                    >
                      Resolve
                    </Button>
                  )}
                  {ticket.status !== "closed" && ticket.status === "resolved" && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleQuickStatusChange("closed")}
                    >
                      Close
                    </Button>
                  )}
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <RichContent className="prose prose-sm max-w-none" html={ticket.description} />
            </CardContent>
          </Card>

          {/* Replies Section */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="flex items-center gap-2">
                  <MessageSquare className="h-5 w-5" />
                  Replies ({replies.length})
                </CardTitle>
                <Button
                  size="sm"
                  onClick={() => setReplyDialogOpen(true)}
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Add Reply
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {replies.length > 0 ? (
                <div className="space-y-6">
                  {replies.map((reply, index) => (
                    <div key={reply.id}>
                      <div className="flex gap-4">
                        <Avatar className="h-10 w-10">
                          <AvatarImage src={reply.expand?.user_id?.avatar} />
                          <AvatarFallback>
                            {reply.expand?.user_id?.name?.charAt(0) || 'U'}
                          </AvatarFallback>
                        </Avatar>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-2">
                            <span className="font-medium">
                              {reply.expand?.user_id?.name || reply.expand?.user_id?.email}
                            </span>
                            <span className="text-sm text-muted-foreground">
                              {format(new Date(reply.created), "MMM d, yyyy 'at' h:mm a")}
                            </span>
                            {reply.is_internal && (
                              <Badge variant="secondary" className="text-xs">
                                Internal
                              </Badge>
                            )}
                          </div>
                          <RichContent
                            className="prose prose-sm max-w-none bg-muted/30 p-4 rounded-lg"
                            html={reply.message}
                          />
                        </div>
                      </div>
                      {index < replies.length - 1 && (
                        <Separator className="mt-6" />
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8 text-muted-foreground">
                  <MessageSquare className="h-12 w-12 mx-auto mb-2 opacity-50" />
                  <p>No replies yet</p>
                  <Button
                    variant="outline"
                    size="sm"
                    className="mt-2"
                    onClick={() => setReplyDialogOpen(true)}
                  >
                    <Plus className="h-4 w-4 mr-2" />
                    Add first reply
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Ticket Details */}
          <Card>
            <CardHeader>
              <CardTitle>Ticket Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium text-muted-foreground">Created by</label>
                <div className="flex items-center gap-2 mt-1">
                  <Avatar className="h-6 w-6">
                    <AvatarImage src={ticket.expand?.user_id?.avatar} />
                    <AvatarFallback>
                      {ticket.expand?.user_id?.name?.charAt(0) || 'U'}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="text-sm font-medium">
                      {ticket.expand?.user_id?.name || ticket.expand?.user_id?.email}
                    </p>
                    {ticket.expand?.user_id?.name && (
                      <p className="text-xs text-muted-foreground">
                        {ticket.expand.user_id.email}
                      </p>
                    )}
                  </div>
                </div>
              </div>

              {ticket.expand?.assigned_to && (
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Assigned to</label>
                  <div className="flex items-center gap-2 mt-1">
                    <Avatar className="h-6 w-6">
                      <AvatarImage src={ticket.expand.assigned_to.avatar} />
                      <AvatarFallback>
                        {ticket.expand.assigned_to.name?.charAt(0) || 'A'}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <p className="text-sm font-medium">
                        {ticket.expand.assigned_to.name || ticket.expand.assigned_to.email}
                      </p>
                      {ticket.expand.assigned_to.name && (
                        <p className="text-xs text-muted-foreground">
                          {ticket.expand.assigned_to.email}
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              )}

              <Separator />

              <div>
                <label className="text-sm font-medium text-muted-foreground">Created</label>
                <p className="text-sm mt-1">
                  {format(new Date(ticket.created), "MMM d, yyyy 'at' h:mm a")}
                </p>
              </div>

              <div>
                <label className="text-sm font-medium text-muted-foreground">Last updated</label>
                <p className="text-sm mt-1">
                  {format(new Date(ticket.updated), "MMM d, yyyy 'at' h:mm a")}
                </p>
              </div>

              {ticket.category && (
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Category</label>
                  <p className="text-sm mt-1">{ticket.category}</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Dialogs */}
      <TicketReplyDialog
        ticket={ticket}
        open={replyDialogOpen}
        onOpenChange={setReplyDialogOpen}
        onReplyAdded={() => {
          setReplyDialogOpen(false)
          handleDialogClose()
        }}
      />

      <TicketStatusUpdateDialog
        ticket={ticket}
        open={statusDialogOpen}
        onOpenChange={setStatusDialogOpen}
        onStatusUpdated={() => {
          setStatusDialogOpen(false)
          handleDialogClose()
        }}
      />

      <TicketAssignDialog
        ticket={ticket}
        open={assignDialogOpen}
        onOpenChange={setAssignDialogOpen}
        onTicketAssigned={() => {
          setAssignDialogOpen(false)
          handleDialogClose()
        }}
      />
    </div>
  )
}
