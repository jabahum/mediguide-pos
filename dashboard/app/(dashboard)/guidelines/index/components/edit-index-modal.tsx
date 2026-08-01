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
import { guidelineIndexService } from "@/services/guideline-content.service"

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
        parent: typeof indexItem.parent === "string" ? indexItem.parent : "",
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
      const results = await guidelineIndexService.all({ search: searchTerm, per_page: 50 })
      
      // Filter out invalid parent options (descendants and same level+)
      const validParents = (results as GuidelineIndexType[]).filter(item => {
        // Exclude items that have this item as parent (direct descendants)
        if (item.parent === indexItem.id) return false
        
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
      // Prepare update data
      const updateData: Record<string, unknown> = {
        title: data.title,
        description: data.description || "",
      }

      // Handle parent change
      if (data.parent !== (typeof indexItem.parent === "string" ? indexItem.parent : "")) {
        if (data.parent) {
          updateData.parent = data.parent
          const siblings = allIndexItems.filter(item => item.parent === data.parent)
          updateData.order = Math.max(0, ...siblings.map(item => item.order || 0)) + 1
        } else {
          updateData.parent = ""
          const rootItems = allIndexItems.filter(item => !item.parent && item.id !== indexItem.id)
          updateData.order = Math.max(0, ...rootItems.map(item => item.order || 0)) + 1
        }
      }

      await guidelineIndexService.update(indexItem.id, updateData)
      
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
