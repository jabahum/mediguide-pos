/**
 * Support Tickets Service
 * Centralized service for all support ticket CRUD operations and business logic
 */

import { getBackendClient } from "@/lib/backend-client"
import { Collections } from "@/types/backend-types"
import type {
  SupportTicketsResponse,
  SupportTicketRepliesResponse,
  UsersResponse,
  SupportTicketsStatusOptions,
  SupportTicketsPriorityOptions,
} from "@/types/backend-types"
import type {
  SupportTicketsWithExpanded,
  SupportTicketRepliesWithExpanded,
} from "@/types/expanded"
import type {
  CreateSupportTicketData,
  UpdateSupportTicketData,
  CreateTicketReplyData,
  TicketStats,
  TicketFilters,
  BulkTicketOperation,
} from "@/types/support-tickets"

export class SupportTicketsService {
  /**
   * Get all tickets with optional filters and expanded relationships
   */
  static async getTickets(options: {
    expand?: string
    filter?: string
    sort?: string
    page?: number
    perPage?: number
  } = {}): Promise<{
    items: SupportTicketsWithExpanded[]
    totalItems: number
    totalPages: number
    page: number
    perPage: number
  }> {
    try {
      const backend = getBackendClient()
      
      const defaultOptions = {
        expand: "user_id,assigned_to",
        sort: "-created",
        page: 1,
        perPage: 30,
        ...options
      }

      const result = await backend.resource(Collections.SupportTickets).getList(
        defaultOptions.page,
        defaultOptions.perPage,
        {
          expand: defaultOptions.expand,
          filter: defaultOptions.filter,
          sort: defaultOptions.sort,
        }
      )

      return {
        items: result.items as SupportTicketsWithExpanded[],
        totalItems: result.totalItems,
        totalPages: result.totalPages,
        page: result.page,
        perPage: result.perPage,
      }
    } catch (error) {
      console.error('Error fetching tickets:', error)
      throw error
    }
  }

  /**
   * Get a single ticket by ID with expanded relationships
   */
  static async getTicketById(id: string): Promise<SupportTicketsWithExpanded> {
    try {
      const backend = getBackendClient()
      
      const ticket = await backend.resource(Collections.SupportTickets).getOne(id, {
        expand: "user_id,assigned_to"
      })

      return ticket as SupportTicketsWithExpanded
    } catch (error) {
      console.error('Error fetching ticket:', error)
      throw error
    }
  }

  /**
   * Create a new support ticket (typically called from mobile app)
   */
  static async createTicket(data: CreateSupportTicketData): Promise<SupportTicketsResponse> {
    try {
      const backend = getBackendClient()
      
      const ticketData = {
        ...data,
        status: 'open' as SupportTicketsStatusOptions,
      }

      const ticket = await backend.resource(Collections.SupportTickets).create(ticketData)
      return ticket as SupportTicketsResponse
    } catch (error) {
      console.error('Error creating ticket:', error)
      throw error
    }
  }

  /**
   * Update ticket status, assignment, or other fields
   */
  static async updateTicket(id: string, data: UpdateSupportTicketData): Promise<SupportTicketsResponse> {
    try {
      const backend = getBackendClient()
      
      const ticket = await backend.resource(Collections.SupportTickets).update(id, data)
      return ticket as SupportTicketsResponse
    } catch (error) {
      console.error('Error updating ticket:', error)
      throw error
    }
  }

  /**
   * Update ticket status specifically
   */
  static async updateTicketStatus(id: string, status: SupportTicketsStatusOptions): Promise<SupportTicketsResponse> {
    return this.updateTicket(id, { status })
  }

  /**
   * Assign ticket to a user
   */
  static async assignTicket(id: string, userId: string): Promise<SupportTicketsResponse> {
    return this.updateTicket(id, { assigned_to: userId })
  }

  /**
   * Update ticket priority
   */
  static async updateTicketPriority(id: string, priority: SupportTicketsPriorityOptions): Promise<SupportTicketsResponse> {
    return this.updateTicket(id, { priority })
  }

  /**
   * Delete a ticket (admin only)
   */
  static async deleteTicket(id: string): Promise<boolean> {
    try {
      const backend = getBackendClient()
      
      await backend.resource(Collections.SupportTickets).delete(id)
      return true
    } catch (error) {
      console.error('Error deleting ticket:', error)
      throw error
    }
  }

  /**
   * Get ticket replies with expanded user information
   */
  static async getTicketReplies(ticketId: string): Promise<SupportTicketRepliesWithExpanded[]> {
    try {
      const backend = getBackendClient()
      
      const replies = await backend.resource(Collections.SupportTicketReplies).getFullList({
        filter: `ticket_id="${ticketId}"`,
        sort: "created",
        expand: "user_id"
      })

      return replies as SupportTicketRepliesWithExpanded[]
    } catch (error) {
      console.error('Error fetching ticket replies:', error)
      throw error
    }
  }

  /**
   * Add a reply to a ticket
   */
  static async addReply(data: CreateTicketReplyData): Promise<SupportTicketRepliesResponse> {
    try {
      const backend = getBackendClient()
      
      const reply = await backend.resource(Collections.SupportTicketReplies).create(data)
      return reply as SupportTicketRepliesResponse
    } catch (error) {
      console.error('Error adding reply:', error)
      throw error
    }
  }

  /**
   * Add an internal note to a ticket
   */
  static async addInternalNote(ticketId: string, message: string, userId: string): Promise<SupportTicketRepliesResponse> {
    return this.addReply({
      ticket_id: ticketId,
      message,
      user_id: userId,
      is_internal: true
    })
  }

  /**
   * Get ticket statistics
   */
  static async getTicketStats(): Promise<TicketStats> {
    try {
      const backend = getBackendClient()
      
      // Get all tickets to calculate stats
      const allTickets = await backend.resource(Collections.SupportTickets).getFullList()
      
      const stats: TicketStats = {
        total: allTickets.length,
        open: 0,
        in_progress: 0,
        resolved: 0,
        closed: 0,
        byPriority: {
          low: 0,
          normal: 0,
          high: 0,
          urgent: 0
        },
        recentActivity: 0
      }

      // Calculate status counts
      allTickets.forEach(ticket => {
        const typedTicket = ticket as SupportTicketsResponse
        stats[typedTicket.status]++
        stats.byPriority[typedTicket.priority]++
        
        // Count recent activity (last 7 days)
        const createdDate = new Date(typedTicket.created)
        const weekAgo = new Date()
        weekAgo.setDate(weekAgo.getDate() - 7)
        if (createdDate > weekAgo) {
          stats.recentActivity++
        }
      })

      return stats
    } catch (error) {
      console.error('Error fetching ticket stats:', error)
      throw error
    }
  }

  /**
   * Get tickets by status
   */
  static async getTicketsByStatus(status: SupportTicketsStatusOptions): Promise<SupportTicketsWithExpanded[]> {
    try {
      const result = await this.getTickets({
        filter: `status="${status}"`,
        expand: "user_id,assigned_to"
      })
      
      return result.items
    } catch (error) {
      console.error('Error fetching tickets by status:', error)
      throw error
    }
  }

  /**
   * Get tickets assigned to a specific user
   */
  static async getAssignedTickets(userId: string): Promise<SupportTicketsWithExpanded[]> {
    try {
      const result = await this.getTickets({
        filter: `assigned_to="${userId}"`,
        expand: "user_id,assigned_to"
      })
      
      return result.items
    } catch (error) {
      console.error('Error fetching assigned tickets:', error)
      throw error
    }
  }

  /**
   * Search tickets by keyword
   */
  static async searchTickets(keyword: string): Promise<SupportTicketsWithExpanded[]> {
    try {
      const result = await this.getTickets({
        filter: `subject~"${keyword}" || description~"${keyword}"`,
        expand: "user_id,assigned_to"
      })
      
      return result.items
    } catch (error) {
      console.error('Error searching tickets:', error)
      throw error
    }
  }

  /**
   * Perform bulk operations on tickets
   */
  static async bulkUpdateTickets(operation: BulkTicketOperation): Promise<SupportTicketsResponse[]> {
    try {
      const backend = getBackendClient()
      const results: SupportTicketsResponse[] = []

      for (const ticketId of operation.ticket_ids) {
        try {
          const result = await backend.resource(Collections.SupportTickets).update(ticketId, operation.data)
          results.push(result as SupportTicketsResponse)
        } catch (error) {
          console.error(`Error updating ticket ${ticketId}:`, error)
          // Continue with other tickets even if one fails
        }
      }

      return results
    } catch (error) {
      console.error('Error performing bulk update:', error)
      throw error
    }
  }

  /**
   * Get available users for assignment (with appropriate roles)
   */
  static async getAssignableUsers(): Promise<UsersResponse[]> {
    try {
      const backend = getBackendClient()
      
      // Get users with admin, contentManager, or other relevant roles
      const users = await backend.resource(Collections.Users).getFullList({
        filter: 'status="active"',
        sort: "name"
      })

      return users as UsersResponse[]
    } catch (error) {
      console.error('Error fetching assignable users:', error)
      throw error
    }
  }

  /**
   * Apply advanced filters to tickets
   */
  static async getFilteredTickets(filters: TicketFilters): Promise<SupportTicketsWithExpanded[]> {
    try {
      const filterParts: string[] = []

      if (filters.status) {
        filterParts.push(`status="${filters.status}"`)
      }
      
      if (filters.priority) {
        filterParts.push(`priority="${filters.priority}"`)
      }
      
      if (filters.assigned_to) {
        filterParts.push(`assigned_to="${filters.assigned_to}"`)
      }
      
      if (filters.user_id) {
        filterParts.push(`user_id="${filters.user_id}"`)
      }
      
      if (filters.category) {
        filterParts.push(`category~"${filters.category}"`)
      }

      if (filters.date_range) {
        const startDate = filters.date_range.start.toISOString()
        const endDate = filters.date_range.end.toISOString()
        filterParts.push(`created>="${startDate}" && created<="${endDate}"`)
      }

      const filterString = filterParts.join(' && ')

      const result = await this.getTickets({
        filter: filterString,
        expand: "user_id,assigned_to"
      })
      
      return result.items
    } catch (error) {
      console.error('Error applying filters:', error)
      throw error
    }
  }
}