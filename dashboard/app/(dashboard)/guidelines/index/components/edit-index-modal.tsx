"use client"

import * as React from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
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
import { Check, ChevronDown, Search } from "lucide-react"
import { GuidelineIndexType } from "../columns"
import { showToast } from "@/lib/toast"
import { getBackendClient } from "@/lib/backend-client"

const editIndexSchema = z.object({
  title: z.string().min(1, "Title is required").max(200, "Title must be less than 200 characters"),
  description: z.string().optional(),
  parent: z.string().optional(),
})

type EditIndexFormData = z.infer<typeof editIndexSchema>

interface EditIndexModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  indexItem: GuidelineIndexType | null
  allIndexItems: GuidelineIndexType[]
  onSuccess: () => void
}

export function EditIndexModal({
  open,
  onOpenChange,
  indexItem,
  allIndexItems,
  onSuccess,
}: EditIndexModalProps) {
  const [isSubmitting, setIsSubmitting] = React.useState(false)
  const [parentSearch, setParentSearch] = React.useState("")
  const [parentOpen, setParentOpen] = React.useState(false)
  const [searchResults, setSearchResults] = React.useState<GuidelineIndexType[]>([])
  const [isSearching, setIsSearching] = React.useState(false)

  const form = useForm<EditIndexFormData>({
    resolver: zodResolver(editIndexSchema),
    defaultValues: {
      title: "",
      description: "",
      parent: "",
    },
  })

  const { register, handleSubmit, formState: { errors }, setValue, watch, reset } = form

  // Reset form when indexItem changes
  React.useEffect(() => {
    if (indexItem && open) {
      reset({
        title: indexItem.title || "",
        description: indexItem.description || "",
        parent: indexItem.parent?.[0] || "",
      })
      setParentSearch("")
      setSearchResults([])
    }
  }, [indexItem, open, reset])

  // Server-side search for parent items (excluding invalid options)
  const searchParentItems = React.useCallback(async (searchTerm: string) => {
    if (!searchTerm.trim() || !indexItem) {
      setSearchResults([])
      return
    }
    
    setIsSearching(true)
    try {
      const backend = getBackendClient()
      const results = await backend.resource('guideline_index').getList(1, 50, {
        filter: `title ~ "${searchTerm}" && id != "${indexItem.id}"`,
        sort: 'level,order'
      })
      
      // Filter out invalid parent options (descendants and same level+)
      const validParents = (results.items as GuidelineIndexType[]).filter(item => {
        // Exclude items that have this item as parent (direct descendants)
        if (item.parent?.[0] === indexItem.id) return false
        
        // Only show items at same or higher level to prevent circular references
        if ((item.level || 0) >= (indexItem.level || 0)) return false
        
        return true
      })
      
      setSearchResults(validParents)
    } catch (error) {
      console.error("Failed to search parent items:", error)
      setSearchResults([])
    } finally {
      setIsSearching(false)
    }
  }, [indexItem])
  
  // Debounced search
  React.useEffect(() => {
    const timer = setTimeout(() => {
      if (parentSearch) {
        searchParentItems(parentSearch)
      } else {
        setSearchResults([])
      }
    }, 300)
    
    return () => clearTimeout(timer)
  }, [parentSearch, searchParentItems])
  
  // Get display text for selected parent
  const selectedParentText = React.useMemo(() => {
    const parentValue = watch("parent")
    if (!parentValue) return "Select parent (or leave as root)"
    
    // Try to find in allIndexItems first
    const item = allIndexItems.find(item => item.id === parentValue)
    if (item) return `${"  ".repeat(item.level || 0)}${item.title}`
    
    // Try to find in search results
    const searchItem = searchResults.find(item => item.id === parentValue)
    if (searchItem) return `${"  ".repeat(searchItem.level || 0)}${searchItem.title}`
    
    return "Unknown parent"
  }, [watch, allIndexItems, searchResults])

  const onSubmit = async (data: EditIndexFormData) => {
    if (!indexItem) return

    setIsSubmitting(true)
    try {
      const backend = getBackendClient()
      
      // Prepare update data
      const updateData: Record<string, unknown> = {
        title: data.title,
        description: data.description || "",
      }

      // Handle parent change
      if (data.parent !== (indexItem.parent?.[0] || "")) {
        if (data.parent) {
          // Moving to new parent
          updateData.parent = [data.parent]
          
          // Calculate new level based on parent
          const newParent = allIndexItems.find(item => item.id === data.parent)
          updateData.level = (newParent?.level || 0) + 1
          
          // Get next order under new parent
          const siblings = await backend.resource('guideline_index').getList(1, 50, {
            filter: `parent ~ "${data.parent}"`,
            sort: '-order'
          })
          updateData.order = (siblings.items[0]?.order || 0) + 1
          
          // Update new parent to mark it has children
          await backend.resource('guideline_index').update(data.parent, {
            hasChildren: true
          })
        } else {
          // Moving to root level
          updateData.parent = ""
          updateData.level = 0
          
          // Get next order for root items
          const rootItems = await backend.resource('guideline_index').getList(1, 1, {
            filter: 'parent = ""',
            sort: '-order'
          })
          updateData.order = (rootItems.items[0]?.order || 0) + 1
        }

        // Check if old parent should be updated (no longer has children)
        if (indexItem.parent?.[0]) {
          const oldParentId = indexItem.parent[0]
          const remainingSiblings = await backend.resource('guideline_index').getList(1, 1, {
            filter: `parent ~ "${oldParentId}" && id != "${indexItem.id}"`
          })
          
          if (remainingSiblings.totalItems === 0) {
            await backend.resource('guideline_index').update(oldParentId, {
              hasChildren: false
            })
          }
        }
      }

      // Update the index item
      await backend.resource('guideline_index').update(indexItem.id, updateData)
      
      showToast.success("Success", "Index item updated successfully")
      onSuccess()
      onOpenChange(false)
    } catch (error) {
      showToast.error("Error", "Failed to update index item")
      console.error("Failed to update index item:", error)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Edit Index Item</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {/* Title */}
          <div className="space-y-2">
            <Label htmlFor="title">Title *</Label>
            <Input
              id="title"
              {...register("title")}
              placeholder="Enter index item title"
              disabled={isSubmitting}
              className={errors.title ? "border-destructive" : ""}
            />
            {errors.title && (
              <p className="text-sm text-destructive">{errors.title.message}</p>
            )}
          </div>

          {/* Description */}
          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              {...register("description")}
              placeholder="Optional description"
              disabled={isSubmitting}
              rows={3}
            />
          </div>

          {/* Parent */}
          <div className="space-y-2">
            <Label htmlFor="parent">Parent Item</Label>
            <Popover open={parentOpen} onOpenChange={setParentOpen}>
              <PopoverTrigger asChild>
                <Button
                  variant="outline"
                  role="combobox"
                  aria-expanded={parentOpen}
                  className="w-full justify-between"
                  disabled={isSubmitting}
                >
                  <span className="truncate">{selectedParentText}</span>
                  <ChevronDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-full p-0" align="start">
                <Command>
                  <div className="flex items-center border-b px-3">
                    <Search className="mr-2 h-4 w-4 shrink-0 opacity-50" />
                    <CommandInput
                      placeholder="Search parent items..."
                      value={parentSearch}
                      onValueChange={setParentSearch}
                      className="border-0 focus:ring-0"
                    />
                  </div>
                  <CommandList>
                    <CommandEmpty>
                      {isSearching ? "Searching..." : parentSearch ? "No valid parent items found." : "Type to search for parent items"}
                    </CommandEmpty>
                    
                    <CommandGroup>
                      {/* Root level option */}
                      <CommandItem
                        value="root"
                        onSelect={() => {
                          setValue("parent", "")
                          setParentOpen(false)
                          setParentSearch("")
                        }}
                      >
                        <Check
                          className={`mr-2 h-4 w-4 ${watch("parent") === "" ? "opacity-100" : "opacity-0"}`}
                        />
                        Root Level
                      </CommandItem>
                      
                      {/* Search results */}
                      {searchResults.map((parent) => (
                        <CommandItem
                          key={parent.id}
                          value={parent.id}
                          onSelect={() => {
                            setValue("parent", parent.id)
                            setParentOpen(false)
                            setParentSearch("")
                          }}
                        >
                          <Check
                            className={`mr-2 h-4 w-4 ${watch("parent") === parent.id ? "opacity-100" : "opacity-0"}`}
                          />
                          <span className="truncate">
                            {parent.title}
                          </span>
                        </CommandItem>
                      ))}
                    </CommandGroup>
                  </CommandList>
                </Command>
              </PopoverContent>
            </Popover>
            <p className="text-xs text-muted-foreground">
              Choose a parent item or leave as root level
            </p>
          </div>

          {/* Actions */}
          <div className="flex gap-3 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={isSubmitting}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting ? "Updating..." : "Update Item"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}