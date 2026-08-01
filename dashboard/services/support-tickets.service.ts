import { getBackendClient } from "@/lib/backend-client"
import { usersService } from "@/services/user-management.service"
import type {
  SupportTicketRepliesResponse,
  SupportTicketsPriorityOptions,
  SupportTicketsResponse,
  SupportTicketsStatusOptions,
  UsersResponse,
} from "@/types/backend-types"
import type {
  SupportTicketRepliesWithExpanded,
  SupportTicketsWithExpanded,
} from "@/types/expanded"
import type {
  BulkTicketOperation,
  CreateSupportTicketData,
  CreateTicketReplyData,
  TicketFilters,
  TicketStats,
  UpdateSupportTicketData,
} from "@/types/support-tickets"

interface TypedPage<T> {
  items: T[]
  page: number
  per_page: number
  total_items: number
  total_pages: number
}

interface SupportQuery {
  page?: number
  per_page?: number
  search?: string
  status?: string
  priority?: string
  category?: string
  owner_id?: string
  assigned_to?: string
  sort?: string
  order?: "asc" | "desc"
}

type SupportTicketWire = SupportTicketsResponse & {
  created_at?: string
  updated_at?: string
  user_name?: string
  user_email?: string
  assignee_name?: string
}

type SupportReplyWire = SupportTicketRepliesResponse & {
  created_at?: string
  updated_at?: string
  user_name?: string
  user_email?: string
}

const client = () => getBackendClient()

function normalizeTicket(ticket: SupportTicketWire): SupportTicketsWithExpanded {
  return {
    ...ticket,
    created: ticket.created || ticket.created_at || "",
    updated: ticket.updated || ticket.updated_at || "",
    expand: {
      ...(ticket.expand || {}),
      user_id: {
        id: ticket.user_id,
        name: ticket.user_name || "",
        email: ticket.user_email || "",
      } as UsersResponse,
      ...(ticket.assigned_to
        ? {
            assigned_to: {
              id: ticket.assigned_to,
              name: ticket.assignee_name || "",
            } as UsersResponse,
          }
        : {}),
    },
  } as SupportTicketsWithExpanded
}

function normalizeReply(reply: SupportReplyWire): SupportTicketRepliesWithExpanded {
  return {
    ...reply,
    created: reply.created || reply.created_at || "",
    updated: reply.updated || reply.updated_at || "",
    expand: {
      ...(reply.expand || {}),
      user_id: {
        id: reply.user_id,
        name: reply.user_name || "",
        email: reply.user_email || "",
      } as UsersResponse,
    },
  } as SupportTicketRepliesWithExpanded
}

export class SupportTicketsService {
  static async getTickets(query: SupportQuery = {}) {
    const result = await client().send<TypedPage<SupportTicketWire>>(
      "/api/v2/support/tickets",
      { query: { page: 1, per_page: 30, sort: "updated_at", order: "desc", ...query } },
    )
    return {
      items: result.items.map(normalizeTicket),
      totalItems: result.total_items,
      totalPages: result.total_pages,
      page: result.page,
      perPage: result.per_page,
    }
  }

  static async getTicketById(id: string): Promise<SupportTicketsWithExpanded> {
    return normalizeTicket(
      await client().send<SupportTicketWire>(`/api/v2/support/tickets/${id}`),
    )
  }

  static async createTicket(data: CreateSupportTicketData): Promise<SupportTicketsResponse> {
    return normalizeTicket(
      await client().send<SupportTicketWire>("/api/v2/support/tickets", {
        method: "POST",
        body: JSON.stringify({
          subject: data.subject,
          description: data.description,
          priority: data.priority,
          category: data.category,
        }),
      }),
    )
  }

  static async updateTicket(id: string, data: UpdateSupportTicketData): Promise<SupportTicketsResponse> {
    return normalizeTicket(
      await client().send<SupportTicketWire>(`/api/v2/support/tickets/${id}`, {
        method: "PATCH",
        body: JSON.stringify(data),
      }),
    )
  }

  static updateTicketStatus(id: string, status: SupportTicketsStatusOptions) {
    return this.updateTicket(id, { status })
  }

  static assignTicket(id: string, userId: string) {
    return this.updateTicket(id, { assigned_to: userId })
  }

  static updateTicketPriority(id: string, priority: SupportTicketsPriorityOptions) {
    return this.updateTicket(id, { priority })
  }

  static async deleteTicket(id: string): Promise<boolean> {
    await client().send<void>(`/api/v2/support/tickets/${id}`, { method: "DELETE" })
    return true
  }

  static async getTicketReplies(ticketId: string): Promise<SupportTicketRepliesWithExpanded[]> {
    const result = await client().send<TypedPage<SupportReplyWire>>(
      `/api/v2/support/tickets/${ticketId}/replies`,
      { query: { page: 1, per_page: 100 } },
    )
    return result.items.map(normalizeReply)
  }

  static async addReply(data: CreateTicketReplyData): Promise<SupportTicketRepliesResponse> {
    return normalizeReply(
      await client().send<SupportReplyWire>(
        `/api/v2/support/tickets/${data.ticket_id}/replies`,
        {
          method: "POST",
          body: JSON.stringify({ message: data.message, is_internal: data.is_internal }),
        },
      ),
    )
  }

  static addInternalNote(ticketId: string, message: string, _userId: string) {
    return this.addReply({ ticket_id: ticketId, message, user_id: _userId, is_internal: true })
  }

  static async getTicketStats(): Promise<TicketStats> {
    const allTickets: SupportTicketsWithExpanded[] = []
    let page = 1
    let totalPages = 1
    while (page <= totalPages) {
      const result = await this.getTickets({ page, per_page: 100 })
      allTickets.push(...result.items)
      totalPages = result.totalPages
      page += 1
    }
    const stats: TicketStats = {
      total: allTickets.length,
      open: 0,
      in_progress: 0,
      resolved: 0,
      closed: 0,
      byPriority: { low: 0, normal: 0, high: 0, urgent: 0 },
      recentActivity: 0,
    }
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    for (const ticket of allTickets) {
      stats[ticket.status] += 1
      stats.byPriority[ticket.priority] += 1
      if (new Date(ticket.created) > weekAgo) stats.recentActivity += 1
    }
    return stats
  }

  static async getTicketsByStatus(status: SupportTicketsStatusOptions) {
    return (await this.getTickets({ status })).items
  }

  static async getAssignedTickets(userId: string) {
    return (await this.getTickets({ assigned_to: userId })).items
  }

  static async searchTickets(keyword: string) {
    return (await this.getTickets({ search: keyword })).items
  }

  static async bulkUpdateTickets(operation: BulkTicketOperation) {
    const results: SupportTicketsResponse[] = []
    for (const id of operation.ticket_ids) {
      try { results.push(await this.updateTicket(id, operation.data)) } catch (error) {
        console.error(`Error updating ticket ${id}:`, error)
      }
    }
    return results
  }

  static getAssignableUsers(): Promise<UsersResponse[]> {
    return usersService.all<UsersResponse>({ status: "active", sort: "name", order: "asc" })
  }

  static async getFilteredTickets(filters: TicketFilters) {
    return (await this.getTickets({
      status: filters.status,
      priority: filters.priority,
      assigned_to: filters.assigned_to,
      owner_id: filters.user_id,
      category: filters.category,
    })).items
  }
}
