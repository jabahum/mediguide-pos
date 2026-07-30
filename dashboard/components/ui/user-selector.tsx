"use client"

import { useState, useEffect, useMemo } from "react"
import { Button } from "@/components/ui/button"
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Check, ChevronDown, X } from "lucide-react"
import { cn } from "@/lib/utils"
import type { UsersResponse } from "@/types/backend-types"
import { SupportTicketsService } from "@/services/support-tickets.service"

export interface UserSelectorProps {
  /**
   * Current selected value (user ID)
   */
  value?: string
  
  /**
   * Callback when selection changes
   */
  onValueChange: (value: string | undefined) => void
  
  /**
   * Placeholder text when no user is selected
   */
  placeholder?: string
  
  /**
   * Search input placeholder
   */
  searchPlaceholder?: string
  
  /**
   * Whether the selector is disabled
   */
  disabled?: boolean
  
  /**
   * Additional CSS classes for the trigger button
   */
  className?: string
  
  /**
   * Whether to show an "Unassigned" option
   */
  showUnassignedOption?: boolean
  
  /**
   * Label for the unassigned option
   */
  unassignedOptionLabel?: string
  
  /**
   * Whether to allow clearing the selection
   */
  allowClear?: boolean
}

/**
 * A reusable selector component for users with server-side search
 * 
 * @example
 * ```tsx
 * <UserSelector
 *   value={assignedUserId}
 *   onValueChange={setAssignedUserId}
 *   placeholder="Select user to assign"
 *   showUnassignedOption={true}
 *   allowClear={true}
 * />
 * ```
 */
export function UserSelector({
  value,
  onValueChange,
  placeholder = "Select user",
  searchPlaceholder = "Search users...",
  disabled = false,
  className,
  showUnassignedOption = true,
  unassignedOptionLabel = "Unassigned",
  allowClear = true,
}: UserSelectorProps) {
  const [open, setOpen] = useState(false)
  const [searchTerm, setSearchTerm] = useState("")
  const [users, setUsers] = useState<UsersResponse[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Load users when component opens
  useEffect(() => {
    if (open) {
      loadUsers()
    }
  }, [open])

  const loadUsers = async () => {
    try {
      setIsLoading(true)
      setError(null)
      const availableUsers = await SupportTicketsService.getAssignableUsers()
      setUsers(availableUsers)
    } catch (err) {
      console.error('Error loading users:', err)
      setError('Failed to load users')
    } finally {
      setIsLoading(false)
    }
  }

  // Filter users based on search term
  const filteredUsers = useMemo(() => {
    if (!searchTerm.trim()) return users
    
    const term = searchTerm.toLowerCase()
    return users.filter(user => 
      user.name?.toLowerCase().includes(term) ||
      user.email.toLowerCase().includes(term)
    )
  }, [users, searchTerm])

  // Find selected user
  const selectedUser = useMemo(() => {
    if (!value) return null
    return users.find(user => user.id === value) || null
  }, [value, users])

  const renderSelectedUser = (user: UsersResponse | null) => {
    if (!user) return placeholder
    return (
      <div className="flex items-center gap-2">
        <Avatar className="h-5 w-5">
          <AvatarImage src={user.avatar} />
          <AvatarFallback className="text-xs">
            {user.name?.charAt(0) || user.email.charAt(0)}
          </AvatarFallback>
        </Avatar>
        <span className="truncate">
          {user.name || user.email}
        </span>
      </div>
    )
  }

  const renderUserItem = (user: UsersResponse) => (
    <div className="flex items-center gap-2">
      <Avatar className="h-6 w-6">
        <AvatarImage src={user.avatar} />
        <AvatarFallback className="text-xs">
          {user.name?.charAt(0) || user.email.charAt(0)}
        </AvatarFallback>
      </Avatar>
      <div className="flex flex-col min-w-0">
        <span className="text-sm font-medium truncate">
          {user.name || user.email}
        </span>
        {user.name && (
          <span className="text-xs text-muted-foreground truncate">
            {user.email}
          </span>
        )}
      </div>
    </div>
  )

  const handleSelect = (selectedValue: string) => {
    if (selectedValue === "unassigned") {
      onValueChange(undefined)
    } else {
      onValueChange(selectedValue)
    }
    setOpen(false)
  }

  const handleClear = (e: React.MouseEvent) => {
    e.stopPropagation()
    onValueChange(undefined)
  }

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className={cn("justify-between", className)}
          disabled={disabled}
        >
          <span className="truncate flex-1 text-left">
            {value === "" && showUnassignedOption 
              ? unassignedOptionLabel 
              : selectedUser 
                ? renderSelectedUser(selectedUser)
                : placeholder
            }
          </span>
          <div className="flex items-center gap-1 ml-2">
            {allowClear && value && !disabled && (
              <X 
                className="h-4 w-4 shrink-0 opacity-50 hover:opacity-100" 
                onClick={handleClear}
              />
            )}
            <ChevronDown className="h-4 w-4 shrink-0 opacity-50" />
          </div>
        </Button>
      </PopoverTrigger>
      
      <PopoverContent className="w-full p-0" align="start">
        <Command shouldFilter={false}>
          <CommandInput
            placeholder={searchPlaceholder}
            value={searchTerm}
            onValueChange={setSearchTerm}
          />
          
          <CommandList>
            <CommandEmpty>
              {error ? (
                <div className="text-destructive text-sm p-2">
                  {error}
                </div>
              ) : isLoading ? (
                "Loading users..."
              ) : searchTerm ? (
                "No users found."
              ) : (
                "No users available"
              )}
            </CommandEmpty>
            
            <CommandGroup>
              {/* Unassigned option */}
              {showUnassignedOption && (
                <CommandItem
                  value="unassigned"
                  onSelect={(selectedValue) => handleSelect(selectedValue)}
                >
                  <Check
                    className={cn(
                      "mr-2 h-4 w-4",
                      !value ? "opacity-100" : "opacity-0"
                    )}
                  />
                  <span className="text-muted-foreground">{unassignedOptionLabel}</span>
                </CommandItem>
              )}
              
              {/* User options */}
              {filteredUsers.map((user) => (
                <CommandItem
                  key={user.id}
                  value={user.id}
                  onSelect={(selectedValue) => handleSelect(selectedValue)}
                >
                  <Check
                    className={cn(
                      "mr-2 h-4 w-4",
                      value === user.id ? "opacity-100" : "opacity-0"
                    )}
                  />
                  {renderUserItem(user)}
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  )
}