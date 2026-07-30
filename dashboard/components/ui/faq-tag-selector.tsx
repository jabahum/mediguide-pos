"use client"

import * as React from "react"
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
import { Badge } from "@/components/ui/badge"
import { Check, ChevronDown, X } from "lucide-react"
import { cn } from "@/lib/utils"
import { FaqTagsService } from "@/services/faq-tags.service"
import type { FaqTagsResponse } from "@/types/backend-types"

export interface FaqTagSelectorProps {
  /**
   * Current selected values (array of tag IDs)
   */
  value?: string[]
  
  /**
   * Callback when selection changes
   */
  onValueChange: (value: string[]) => void
  
  /**
   * Placeholder text when no items are selected
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
   * Maximum number of tags that can be selected
   */
  maxSelection?: number
  
  /**
   * Whether to show selected tags as badges in trigger
   */
  showSelectedInTrigger?: boolean
  
  /**
   * Custom render function for displaying selected tags
   */
  renderSelectedTags?: (tags: FaqTagsResponse[]) => React.ReactNode
}

/**
 * A reusable multi-select component for FAQ tags with server-side search
 * 
 * @example
 * ```tsx
 * <FaqTagSelector
 *   value={selectedTagIds}
 *   onValueChange={setSelectedTagIds}
 *   placeholder="Select tags"
 *   maxSelection={10}
 *   showSelectedInTrigger={true}
 * />
 * ```
 */
export function FaqTagSelector({
  value = [],
  onValueChange,
  placeholder = "Select tags",
  searchPlaceholder = "Search tags...",
  disabled = false,
  className,
  maxSelection,
  showSelectedInTrigger = true,
  renderSelectedTags,
}: FaqTagSelectorProps) {
  const [open, setOpen] = React.useState(false)
  const [searchTerm, setSearchTerm] = React.useState("")
  const [availableTags, setAvailableTags] = React.useState<FaqTagsResponse[]>([])
  const [isSearching, setIsSearching] = React.useState(false)

  // Load tags with search
  const loadTags = React.useCallback(async (query = "") => {
    try {
      setIsSearching(true)
      const result = await FaqTagsService.getTagSuggestions(query, 20)
      if (result.success && result.data) {
        setAvailableTags(result.data)
      }
    } catch (error) {
      console.error('Error loading tags:', error)
    } finally {
      setIsSearching(false)
    }
  }, [])

  // Load initial tags
  React.useEffect(() => {
    loadTags()
  }, [loadTags])

  // Handle search with debouncing
  React.useEffect(() => {
    const timer = setTimeout(() => {
      loadTags(searchTerm)
    }, 300)

    return () => clearTimeout(timer)
  }, [searchTerm, loadTags])

  // Get selected tag objects
  const selectedTags = React.useMemo(() => {
    return availableTags.filter(tag => value.includes(tag.id))
  }, [availableTags, value])

  const handleSelect = (tagId: string) => {
    const newValue = value.includes(tagId)
      ? value.filter(id => id !== tagId)
      : [...value, tagId]
    
    // Check max selection limit
    if (maxSelection && !value.includes(tagId) && value.length >= maxSelection) {
      return
    }
    
    onValueChange(newValue)
  }


  const handleClearAll = (e: React.MouseEvent) => {
    e.stopPropagation()
    onValueChange([])
  }

  // Default selected tags render
  const defaultRenderSelectedTags = (tags: FaqTagsResponse[]) => {
    if (tags.length === 0) return placeholder

    if (tags.length === 1) {
      return (
        <Badge 
          variant="outline" 
          className="text-xs"
          style={{
            borderColor: `hsl(var(--${tags[0].color || 'primary'}))`,
            color: `hsl(var(--${tags[0].color || 'primary'}))`
          }}
        >
          {tags[0].name}
        </Badge>
      )
    }

    return `${tags.length} tags selected`
  }

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className={cn("justify-between min-h-10", className)}
          disabled={disabled}
        >
          <div className="flex items-center gap-1 flex-1 overflow-hidden">
            {showSelectedInTrigger && selectedTags.length > 0 ? (
              renderSelectedTags ? renderSelectedTags(selectedTags) : defaultRenderSelectedTags(selectedTags)
            ) : (
              <span className="text-muted-foreground">{placeholder}</span>
            )}
          </div>
          <div className="flex items-center gap-1 ml-2">
            {value.length > 0 && !disabled && (
              <X 
                className="h-4 w-4 shrink-0 opacity-50 hover:opacity-100" 
                onClick={handleClearAll}
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
              {isSearching ? (
                "Searching..."
              ) : searchTerm ? (
                "No tags found."
              ) : (
                "Type to search for tags"
              )}
            </CommandEmpty>
            
            <CommandGroup>
              {availableTags.map((tag) => {
                const isSelected = value.includes(tag.id)
                const isMaxReached = maxSelection && value.length >= maxSelection && !isSelected

                return (
                  <CommandItem
                    key={tag.id}
                    value={tag.id}
                    onSelect={() => handleSelect(tag.id)}
                    disabled={!!isMaxReached}
                    className={cn(
                      "flex items-center gap-2",
                      isMaxReached && "opacity-50 cursor-not-allowed"
                    )}
                  >
                    <Check
                      className={cn(
                        "h-4 w-4",
                        isSelected ? "opacity-100" : "opacity-0"
                      )}
                    />
                    <div 
                      className="w-2 h-2 rounded-full flex-shrink-0"
                      style={{ 
                        backgroundColor: `hsl(var(--${tag.color || 'primary'}))` 
                      }}
                    />
                    <div className="flex flex-col flex-1 min-w-0">
                      <span className="font-medium truncate">{tag.name}</span>
                      {tag.description && (
                        <span className="text-xs text-muted-foreground truncate">
                          {tag.description}
                        </span>
                      )}
                    </div>
                    {tag.usage_count !== undefined && (
                      <span className="text-xs text-muted-foreground">
                        {tag.usage_count}
                      </span>
                    )}
                  </CommandItem>
                )
              })}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  )
}

/**
 * A display component for showing selected tags as removable badges
 */
export function SelectedTagsList({
  tags,
  onRemoveTag,
  disabled = false,
  className,
}: {
  tags: FaqTagsResponse[]
  onRemoveTag: (tagId: string) => void
  disabled?: boolean
  className?: string
}) {
  if (tags.length === 0) return null

  return (
    <div className={cn("flex flex-wrap gap-2", className)}>
      {tags.map((tag) => (
        <Badge 
          key={tag.id}
          variant="outline"
          className="flex items-center gap-2 text-xs"
          style={{ 
            borderColor: `hsl(var(--${tag.color || 'primary'}))`,
            color: `hsl(var(--${tag.color || 'primary'}))`
          }}
        >
          <div 
            className="w-2 h-2 rounded-full"
            style={{ 
              backgroundColor: `hsl(var(--${tag.color || 'primary'}))` 
            }}
          />
          {tag.name}
          {!disabled && (
            <button
              type="button"
              onClick={() => onRemoveTag(tag.id)}
              className="ml-1 hover:text-destructive"
            >
              <X className="h-3 w-3" />
            </button>
          )}
        </Badge>
      ))}
    </div>
  )
}