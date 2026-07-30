"use client"

import { Eye, MessageSquare, Clock, User, CheckCircle, XCircle, AlertTriangle } from "lucide-react"

import type { RowAction, BulkAction } from "@/types/data-table"
import type { SupportTicketsWithExpanded } from "@/types/expanded"
import type { SupportTicketsStatusOptions, SupportTicketsPriorityOptions } from "@/types/backend-types"
import { SupportTicketsService } from "@/services/support-tickets.service"
import { showToast } from "@/lib/toast"

// Row Actions Factory
export const createSupportTicketRowActions = (
  navigate: (path: string) => void,
  onAddReply: (ticket: SupportTicketsWithExpanded) => void,
  onUpdateStatus: (ticket: SupportTicketsWithExpanded) => void,
  onAssignTicket: (ticket: SupportTicketsWithExpanded) => void,
): RowAction<SupportTicketsWithExpanded>[] => [
  {
    id: "view",
    label: "View Details",
    icon: Eye,
    onClick: async (ticket) => {
      navigate(`/support/${ticket.id}`)
    },
  },
  {
    id: "reply",
    label: "Add Reply",
    icon: MessageSquare,
    onClick: async (ticket) => {
      onAddReply(ticket)
    },
  },
  {
    id: "status",
    label: "Update Status",
    icon: Clock,
    onClick: async (ticket) => {
      onUpdateStatus(ticket)
    },
    separator: true,
  },
  {
    id: "assign",
    label: "Assign Ticket",
    icon: User,
    onClick: async (ticket) => {
      onAssignTicket(ticket)
    },
  },
  {
    id: "close",
    label: "Close Ticket",
    icon: XCircle,
    variant: "destructive",
    onClick: async (ticket) => {
      try {
        await SupportTicketsService.updateTicketStatus(ticket.id, "closed" as SupportTicketsStatusOptions)
        showToast.success("Success", "Ticket closed successfully")
        // Trigger refresh - this will be handled by the parent component
        // DataTable will auto-refresh
      } catch (error) {
        console.error('Error closing ticket:', error)
        showToast.error("Error", "Failed to close ticket")
      }
    },
    disabled: (ticket) => ticket.status === "closed",
    confirmMessage: "Are you sure you want to close this ticket?",
    separator: true,
  },
]

// Bulk Actions
export const supportTicketBulkActions: BulkAction<SupportTicketsWithExpanded>[] = [
  {
    id: "bulk-open",
    label: "Mark as Open",
    icon: AlertTriangle,
    onClick: async (tickets) => {
      try {
        const ticketIds = tickets.map(t => t.id)
        await SupportTicketsService.bulkUpdateTickets({
          ticket_ids: ticketIds,
          operation: 'update_status',
          data: { status: 'open' as SupportTicketsStatusOptions }
        })
        showToast.success("Success", `${tickets.length} tickets marked as open`)
        // DataTable will auto-refresh
      } catch (error) {
        console.error('Error updating tickets:', error)
        showToast.error("Error", "Failed to update tickets")
      }
    },
    disabled: (tickets) => tickets.every(ticket => ticket.status === 'open'),
    description: "Change status to open for selected tickets",
  },
  {
    id: "bulk-in-progress",
    label: "Mark as In Progress",
    icon: Clock,
    onClick: async (tickets) => {
      try {
        const ticketIds = tickets.map(t => t.id)
        await SupportTicketsService.bulkUpdateTickets({
          ticket_ids: ticketIds,
          operation: 'update_status',
          data: { status: 'in_progress' as SupportTicketsStatusOptions }
        })
        showToast.success("Success", `${tickets.length} tickets marked as in progress`)
        // DataTable will auto-refresh
      } catch (error) {
        console.error('Error updating tickets:', error)
        showToast.error("Error", "Failed to update tickets")
      }
    },
    disabled: (tickets) => tickets.every(ticket => ticket.status === 'in_progress'),
    description: "Change status to in progress for selected tickets",
  },
  {
    id: "bulk-resolved",
    label: "Mark as Resolved", 
    icon: CheckCircle,
    onClick: async (tickets) => {
      try {
        const ticketIds = tickets.map(t => t.id)
        await SupportTicketsService.bulkUpdateTickets({
          ticket_ids: ticketIds,
          operation: 'update_status',
          data: { status: 'resolved' as SupportTicketsStatusOptions }
        })
        showToast.success("Success", `${tickets.length} tickets marked as resolved`)
        // DataTable will auto-refresh
      } catch (error) {
        console.error('Error updating tickets:', error)
        showToast.error("Error", "Failed to update tickets")
      }
    },
    disabled: (tickets) => tickets.every(ticket => ticket.status === 'resolved'),
    description: "Change status to resolved for selected tickets",
  },
  {
    id: "bulk-closed",
    label: "Close Selected Tickets",
    icon: XCircle,
    variant: "destructive",
    onClick: async (tickets) => {
      try {
        const ticketIds = tickets.map(t => t.id)
        await SupportTicketsService.bulkUpdateTickets({
          ticket_ids: ticketIds,
          operation: 'update_status',
          data: { status: 'closed' as SupportTicketsStatusOptions }
        })
        showToast.success("Success", `${tickets.length} tickets closed`)
        // DataTable will auto-refresh
      } catch (error) {
        console.error('Error closing tickets:', error)
        showToast.error("Error", "Failed to close tickets")
      }
    },
    disabled: (tickets) => tickets.every(ticket => ticket.status === 'closed'),
    description: "Close selected tickets",
    separator: true,
    requiresConfirmation: true,
  },
  {
    id: "bulk-priority-high",
    label: "Set High Priority",
    icon: AlertTriangle,
    variant: "outline",
    onClick: async (tickets) => {
      try {
        const ticketIds = tickets.map(t => t.id)
        await SupportTicketsService.bulkUpdateTickets({
          ticket_ids: ticketIds,
          operation: 'update_priority',
          data: { priority: 'high' as SupportTicketsPriorityOptions }
        })
        showToast.success("Success", `${tickets.length} tickets set to high priority`)
        // DataTable will auto-refresh
      } catch (error) {
        console.error('Error updating priority:', error)
        showToast.error("Error", "Failed to update priority")
      }
    },
    disabled: (tickets) => tickets.every(ticket => ticket.priority === 'high'),
    description: "Set priority to high for selected tickets",
  },
  {
    id: "bulk-priority-urgent",
    label: "Set Urgent Priority",
    icon: AlertTriangle,
    variant: "destructive",
    onClick: async (tickets) => {
      try {
        const ticketIds = tickets.map(t => t.id)
        await SupportTicketsService.bulkUpdateTickets({
          ticket_ids: ticketIds,
          operation: 'update_priority',
          data: { priority: 'urgent' as SupportTicketsPriorityOptions }
        })
        showToast.success("Success", `${tickets.length} tickets set to urgent priority`)
        // DataTable will auto-refresh
      } catch (error) {
        console.error('Error updating priority:', error)
        showToast.error("Error", "Failed to update priority")
      }
    },
    disabled: (tickets) => tickets.every(ticket => ticket.priority === 'urgent'),
    description: "Set priority to urgent for selected tickets",
  },
]