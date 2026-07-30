/**
 * Support Tickets Types
 * Extended types and interfaces for the support ticket system
 */

import type {
  SupportTicketsRecord,
  SupportTicketsResponse,
  SupportTicketRepliesRecord,
  SupportTicketRepliesResponse,
  UsersResponse,
  SupportTicketsStatusOptions,
  SupportTicketsPriorityOptions,
} from "./backend-types"

// Expanded ticket type with user relations
export interface SupportTicketWithUser extends SupportTicketsResponse {
  expand?: {
    user_id?: UsersResponse
    assigned_to?: UsersResponse
  }
}

// Expanded reply type with user relations
export interface SupportTicketReplyWithUser extends SupportTicketRepliesResponse {
  expand?: {
    user_id?: UsersResponse
    ticket_id?: SupportTicketsResponse
  }
}

// For creating new tickets (from mobile app)
export interface CreateSupportTicketData {
  subject: string
  description: string
  priority: SupportTicketsPriorityOptions
  category?: string
  user_id: string
}

// For updating ticket status/assignment
export interface UpdateSupportTicketData {
  status?: SupportTicketsStatusOptions
  priority?: SupportTicketsPriorityOptions
  assigned_to?: string
  category?: string
}

// For creating replies
export interface CreateTicketReplyData {
  ticket_id: string
  message: string
  is_internal?: boolean
  user_id: string
}

// Ticket statistics interface
export interface TicketStats {
  total: number
  open: number
  in_progress: number
  resolved: number
  closed: number
  byPriority: {
    low: number
    normal: number
    high: number
    urgent: number
  }
  recentActivity: number
}

// Filter options for ticket list
export interface TicketFilters {
  status?: SupportTicketsStatusOptions
  priority?: SupportTicketsPriorityOptions
  assigned_to?: string
  user_id?: string
  category?: string
  date_range?: {
    start: Date
    end: Date
  }
}

// Ticket activity type for timeline
export interface TicketActivity {
  id: string
  type: 'status_change' | 'assignment' | 'reply' | 'priority_change' | 'created'
  user: UsersResponse
  message: string
  old_value?: string
  new_value?: string
  created: string
}

// Bulk operations interface
export interface BulkTicketOperation {
  ticket_ids: string[]
  operation: 'update_status' | 'assign' | 'update_priority'
  data: {
    status?: SupportTicketsStatusOptions
    assigned_to?: string
    priority?: SupportTicketsPriorityOptions
  }
}

// Export commonly used types for convenience
export type TicketStatus = SupportTicketsStatusOptions
export type TicketPriority = SupportTicketsPriorityOptions

// Status display configuration
export const TICKET_STATUS_CONFIG = {
  open: {
    label: 'Open',
    color: 'bg-red-100 text-red-800 border-red-200',
    icon: 'AlertCircle'
  },
  in_progress: {
    label: 'In Progress',
    color: 'bg-blue-100 text-blue-800 border-blue-200',
    icon: 'Clock'
  },
  resolved: {
    label: 'Resolved',
    color: 'bg-green-100 text-green-800 border-green-200',
    icon: 'CheckCircle'
  },
  closed: {
    label: 'Closed',
    color: 'bg-gray-100 text-gray-800 border-gray-200',
    icon: 'XCircle'
  }
} as const

// Priority display configuration
export const TICKET_PRIORITY_CONFIG = {
  low: {
    label: 'Low',
    color: 'bg-gray-100 text-gray-800 border-gray-200',
    icon: 'ArrowDown'
  },
  normal: {
    label: 'Normal',
    color: 'bg-blue-100 text-blue-800 border-blue-200',
    icon: 'Minus'
  },
  high: {
    label: 'High',
    color: 'bg-orange-100 text-orange-800 border-orange-200',
    icon: 'ArrowUp'
  },
  urgent: {
    label: 'Urgent',
    color: 'bg-red-100 text-red-800 border-red-200',
    icon: 'AlertTriangle'
  }
} as const